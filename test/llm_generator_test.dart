import 'dart:async';
import 'dart:convert';

import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/llm_lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/section_runner.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/llm/fake_engine.dart';
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/validation/plan_validator.dart';
import 'package:ai_lesson_planner/core/validation/validation_issue.dart';
import 'package:test/test.dart';

void main() {
  group('LlmLessonGenerator', () {
    late FakeEngine engine;
    late LlmLessonGenerator generator;
    late PlanValidator validator;

    setUp(() {
      engine = FakeEngine(useFullKey: true);
      generator = LlmLessonGenerator(engine: engine, seed: 42);
      validator = PlanValidator();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('cancel() works without error when no generation is in progress', () {
      generator.cancel();
    });

    test('cancel() stops an ongoing generation', () async {
      // Create a fresh engine with sequences that have controlled delays
      final sequences = _buildValidSequenceForRequest(_validRequest());
      // Use longer delays to allow cancellation to take effect
      final delayedSequences = <String, FakeTokenSequence>{};
      for (final entry in sequences.entries) {
        delayedSequences[entry.key] = FakeTokenSequence(
          tokens: entry.value.tokens,
          delayMs: 50, // Controlled delay for testing
        );
      }
      final cancelEngine = FakeEngine(
        tokenSequences: delayedSequences,
        useFullKey: true,
      );
      await cancelEngine.load(
        ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
      );
      final cancelGenerator = LlmLessonGenerator(
        engine: cancelEngine,
        seed: 42,
      );

      final events = <GenerationEvent>[];
      final completer = Completer<void>();

      final sub = cancelGenerator
          .generate(_validRequest())
          .listen(
            (event) {
              events.add(event);
              // Cancel after first event is received
              if (!completer.isCompleted && events.isNotEmpty) {
                cancelGenerator.cancel();
              }
            },
            onError: (e) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          );

      await completer.future.timeout(const Duration(seconds: 5));

      // Verify that generation was cancelled (either GenerationFailed or partial events)
      final hasFailure = events.any((e) => e is GenerationFailed);
      final hasSomeEvents = events.isNotEmpty;
      expect(
        hasFailure || hasSomeEvents,
        isTrue,
        reason: 'Generation should have been cancelled',
      );

      await sub.cancel();
      await cancelEngine.dispose();
    });

    test('generateSection for header returns completed immediately', () async {
      final header = PlanHeader(
        school: 'Test School',
        teacher: 'Test Teacher',
        learningArea: 'Science',
        date: '2024-01-15',
        term: 'First',
        sessions: 2,
        sessionMinutes: 90,
        multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
      );

      final request = GenerationRequest(
        header: header,
        grades: [],
        sharedSubTheme: 'Test',
        language: OutputLanguage.filipino,
      );

      final emptyPlan = LessonPlan(
        header: header,
        grades: [],
        sharedSubTheme: '',
        bothGradesObjective: '',
        learnerContext: '',
        materials: Materials(),
        flow: [],
        assessments: [],
        reflectionQuestions: [],
        waysForward: [],
        notesNextSession: '',
        preparedBy: header.teacher,
        checkedBy: header.teacher,
        aiUseDeclaration: '',
      );

      var completed = false;
      await for (final event in generator.generateSection(
        request,
        PlanSection.header,
        emptyPlan,
      )) {
        if (event is GenerationCompleted) {
          completed = true;
        }
      }

      expect(completed, isTrue);
    });

    test(
      'full plan from scripted responses passes PlanValidator with zero errors',
      () async {
        final request = _validRequest(sessionMinutes: 60);
        final sequences = _buildValidSequenceForRequest(request);

        final stagePrompt = buildStageActivitiesPrompt(
          request,
          stage: 'Motivation',
          minutes: 10,
          wholeClass: true,
        );
        sequences['user:$stagePrompt;'] = FakeTokenSequence(
          tokens: [
            jsonEncode({
              'activities': ['Review the topic. Use the <|'],
            }),
          ],
        );
        final intentions =
            jsonDecode(_goodIntentionsJson()) as Map<String, dynamic>;
        final objectives =
            (intentions['grades'] as List).first['objectives'] as List;
        objectives.add('], ]');
        final intentionsPrompt = buildIntentionsPrompt(request);
        sequences['user:$intentionsPrompt;'] = FakeTokenSequence(
          tokens: [jsonEncode(intentions)],
        );
        final followup =
            jsonDecode(_goodWaysForwardJson()) as Map<String, dynamic>;
        (followup['reflectionQuestions'] as List).addAll([
          {'gradeLabel': 'Grade 2', 'text': 'Unexpected grade question?'},
          {'gradeLabel': 'Gradle 3', 'text': 'What did Gradle 3 learn?'},
        ]);
        final copied = (followup['waysForward'] as List).first as Map;
        copied['remediation'] = request.grades.first.competency;
        copied['enrichment'] = request.grades.first.competency;
        final followupPrompt = buildWaysForwardPrompt(request);
        sequences['user:$followupPrompt;'] = FakeTokenSequence(
          tokens: [jsonEncode(followup)],
        );

        final followupRetry = buildRetryPrompt([
          'Remediation is not defined for Grade 3.',
          'Enrichment is not defined for Grade 3.',
        ], followupPrompt);
        sequences['user:$followupRetry;'] = FakeTokenSequence(
          tokens: [jsonEncode(followup)],
        );

        // Create fresh engine with sequences
        final freshEngine = FakeEngine(
          tokenSequences: sequences,
          useFullKey: true,
        );
        await freshEngine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final freshGenerator = LlmLessonGenerator(
          engine: freshEngine,
          seed: 42,
        );

        final stream = freshGenerator.generate(request);
        final events = <GenerationEvent>[];

        await for (final event in stream) {
          events.add(event);
        }

        final completed = events.whereType<GenerationCompleted>().first;
        final plan = completed.plan;
        expect(plan.waysForward.first.remediation, isEmpty);
        expect(plan.waysForward.first.enrichment, isEmpty);
        expect(plan.flow.first.wholeClassActivity, 'Review the topic.');
        expect(plan.grades.first.objectives, isNot(contains('], ]')));
        expect(
          plan.reflectionQuestions.any((q) => q.gradeLabel == 'Grade 2'),
          isFalse,
        );
        expect(
          plan.reflectionQuestions.any(
            (q) =>
                q.gradeLabel == 'Grade 3' &&
                q.text == 'What did Grade 3 learn?',
          ),
          isTrue,
        );

        final issues = validator.validate(plan);
        final errors = issues
            .where((i) => i.severity == IssueSeverity.error)
            .toList();
        expect(
          errors,
          isEmpty,
          reason:
              'Validation errors: ${errors.map((e) => e.message).join(', ')}',
        );

        await freshEngine.dispose();
      },
    );

    test('per-grade regeneration changes only that grade', () async {
      final request = _validRequest();
      final sequences = _buildValidSequenceForRequest(request);

      // Create fresh engine with sequences for full plan
      var freshEngine = FakeEngine(tokenSequences: sequences, useFullKey: true);
      await freshEngine.load(
        ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
      );

      var freshGenerator = LlmLessonGenerator(engine: freshEngine, seed: 42);

      var events = <GenerationEvent>[];
      await for (final event in freshGenerator.generate(request)) {
        events.add(event);
      }

      await freshEngine.dispose();

      final initialPlan = events.whereType<GenerationCompleted>().first.plan;
      expect(initialPlan, isNotNull);

      final initialAssessmentCount = initialPlan.assessments.length;

      // Set up modified assessment response for regeneration
      final assessmentPrompt = buildAssessmentPrompt(request);
      final modifiedSequences = {
        'user:$assessmentPrompt;': FakeTokenSequence(
          tokens: [_modifiedAssessmentJson('Grade 3')],
        ),
      };

      // Create fresh engine for regeneration
      freshEngine = FakeEngine(
        tokenSequences: modifiedSequences,
        useFullKey: true,
      );
      await freshEngine.load(
        ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
      );
      freshGenerator = LlmLessonGenerator(engine: freshEngine, seed: 42);

      events = <GenerationEvent>[];
      await for (final event in freshGenerator.generateSection(
        request,
        PlanSection.assessment,
        initialPlan,
        gradeLabel: 'Grade 3',
      )) {
        events.add(event);
      }

      await freshEngine.dispose();

      final regeneratedPlan = events
          .whereType<GenerationCompleted>()
          .first
          .plan;
      expect(
        regeneratedPlan.assessments.length,
        equals(initialAssessmentCount),
      );

      // Verify only Grade 3 was modified
      final modifiedGrade = regeneratedPlan.assessments.firstWhere(
        (a) => a.gradeLabel == 'Grade 3',
      );
      expect(modifiedGrade.formative, contains('Modified'));

      // Verify Grade 4 is unchanged
      final unchangedGrade = regeneratedPlan.assessments.firstWhere(
        (a) => a.gradeLabel == 'Grade 4',
      );
      expect(unchangedGrade.formative, isNotEmpty);
    });

    test('invalid intentions JSON triggers a retry', () async {
      final request = _validRequest();
      final sequences = _buildValidSequenceForRequest(request);
      final prompt = buildIntentionsPrompt(request);
      final retryPrompt = buildRetryPrompt([
        'Return a non-empty grades list in a JSON object.',
      ], prompt);
      sequences['user:$prompt;'] = FakeTokenSequence(tokens: ['{}']);
      sequences['user:$retryPrompt;'] = FakeTokenSequence(
        tokens: [_goodIntentionsJson()],
      );

      final freshEngine = FakeEngine(
        tokenSequences: sequences,
        useFullKey: true,
      );
      await freshEngine.load(
        ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
      );

      final freshGenerator = LlmLessonGenerator(engine: freshEngine, seed: 42);

      final stream = freshGenerator.generate(request);
      final events = <GenerationEvent>[];

      await for (final event in stream) {
        events.add(event);
      }

      await freshEngine.dispose();

      // Should have retried and completed successfully
      final completed = events.whereType<GenerationCompleted>().firstOrNull;
      expect(
        completed,
        isNotNull,
        reason: 'Should have completed after validation retry',
      );

      // Verify the plan is valid
      final plan = completed!.plan;
      final issues = validator.validate(plan);
      final errors = issues
          .where((i) => i.severity == IssueSeverity.error)
          .toList();
      expect(
        errors,
        isEmpty,
        reason: 'Plan should have zero validation errors after retry',
      );
    });

    test('repeated invalid intentions JSON preserves teacher inputs', () async {
      final request = _validRequest();
      final sequences = _buildValidSequenceForRequest(request);
      final prompt = buildIntentionsPrompt(request);
      final retryPrompt = buildRetryPrompt([
        'Return a non-empty grades list in a JSON object.',
      ], prompt);
      sequences['user:$prompt;'] = FakeTokenSequence(tokens: ['{}']);
      sequences['user:$retryPrompt;'] = FakeTokenSequence(tokens: ['{}']);

      final assessmentJson =
          jsonDecode(_goodAssessmentJson()) as Map<String, dynamic>;
      (assessmentJson['assessments'] as List).first['competencyIndex'] = 99;
      final assessmentPrompt = buildAssessmentPrompt(request);
      sequences['user:$assessmentPrompt;'] = FakeTokenSequence(
        tokens: [jsonEncode(assessmentJson)],
      );

      final freshEngine = FakeEngine(
        tokenSequences: sequences,
        useFullKey: true,
      );
      await freshEngine.load(
        ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
      );

      final freshGenerator = LlmLessonGenerator(engine: freshEngine, seed: 42);

      final stream = freshGenerator.generate(request);
      final events = <GenerationEvent>[];

      await for (final event in stream) {
        events.add(event);
      }

      await freshEngine.dispose();

      // Should have retried and completed successfully
      final completed = events.whereType<GenerationCompleted>().firstOrNull;
      expect(
        completed,
        isNotNull,
        reason:
            'An incomplete Intentions response should leave an editable draft',
      );

      // Verify the plan is valid
      final plan = completed!.plan;
      expect(plan.assessments.first.competencyIndex, isNull);
      expect(plan.sharedSubTheme, request.sharedSubTheme);
      expect(
        plan.grades.map((grade) => grade.subTheme),
        request.grades.map((input) => input.subTheme),
      );
      expect(plan.grades.every((grade) => grade.objectives.isEmpty), isTrue);
      final issues = validator.validate(plan);
      expect(
        issues.where((issue) => issue.code == 'intentions.no_objective'),
        hasLength(request.grades.length),
      );
      final errors = issues
          .where((i) => i.severity == IssueSeverity.error)
          .toList();
      expect(
        errors,
        isEmpty,
        reason: 'Plan should have zero validation errors after retry',
      );
    });
  });
}

/// Creates a valid generation request for testing
GenerationRequest _validRequest({int sessionMinutes = 90}) {
  final header = PlanHeader(
    school: 'Sampaguita Elementary School',
    teacher: 'Maria Santos',
    learningArea: 'Science',
    date: '2026-08-04',
    term: 'Term 1',
    sessions: 1,
    sessionMinutes: sessionMinutes,
    multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
    gradeLevels: 'III & IV',
  );

  return GenerationRequest(
    header: header,
    grades: [
      GradeInput(
        gradeLabel: 'Grade 3',
        male: 3,
        female: 3,
        subTheme: 'Pag-iisa-isa at paglalarawan',
        competency:
            'Natutukoy ang mga salitang naglalarawan; Nakapagpapahayag ng ideya gamit paglalarawan',
      ),
      GradeInput(
        gradeLabel: 'Grade 4',
        male: 1,
        female: 0,
        subTheme: 'Pangatnig sa teksto',
        competency: 'Nakikilala ang pangunahing ideya; Nagagamit ang pangatnig',
      ),
    ],
    sharedSubTheme: 'Ulat-panahon at paghahanda sa sakuna',
    language: OutputLanguage.filipino,
  );
}

/// Builds token sequences for a complete valid plan generation
Map<String, FakeTokenSequence> _buildValidSequenceForRequest(
  GenerationRequest request,
) {
  final sequences = <String, FakeTokenSequence>{};

  final intentionsPrompt = buildIntentionsPrompt(request);
  sequences['user:$intentionsPrompt;'] = FakeTokenSequence(
    tokens: [_goodIntentionsJson()],
  );

  final learnerContextPrompt = buildLearnerContextPrompt(request);
  sequences['user:$learnerContextPrompt;'] = FakeTokenSequence(
    tokens: [_goodLearnerContextJson()],
  );

  final materialsPrompt = buildMaterialsPrompt(request);
  sequences['user:$materialsPrompt;'] = FakeTokenSequence(
    tokens: [_goodMaterialsJson()],
  );

  final flowPrompt = buildFlowPrompt(request);
  sequences['user:$flowPrompt;'] = FakeTokenSequence(tokens: [_goodFlowJson()]);

  final stageMinutes = switch (request.header.sessionMinutes) {
    60 => [10, 15, 15, 19, 1],
    90 => [15, 22, 22, 30, 1],
    final minutes => throw ArgumentError.value(minutes, 'sessionMinutes'),
  };
  for (final (index, stage) in [
    'Motivation',
    'Direct Teaching',
    'Practice',
    'Activity',
    'Wrap-up',
  ].indexed) {
    final minutes = stageMinutes[index];
    final wholeClass = index == 0 || index == 4;
    final prompt = buildStageActivitiesPrompt(
      request,
      stage: stage,
      minutes: minutes,
      wholeClass: wholeClass,
    );
    final activities = [
      if (wholeClass) 'Review the topic together.',
      if (!wholeClass)
        for (final grade in request.grades)
          'Discuss an example with ${grade.gradeLabel}.',
    ];
    sequences['user:$prompt;'] = FakeTokenSequence(
      tokens: [
        jsonEncode({'activities': activities}),
      ],
    );
  }

  final assessmentPrompt = buildAssessmentPrompt(request);
  sequences['user:$assessmentPrompt;'] = FakeTokenSequence(
    tokens: [_goodAssessmentJson()],
  );

  final waysForwardPrompt = buildWaysForwardPrompt(request);
  sequences['user:$waysForwardPrompt;'] = FakeTokenSequence(
    tokens: [_goodWaysForwardJson()],
  );

  return sequences;
}

/// Modified assessment JSON for per-grade test
String _modifiedAssessmentJson(String modifiedGrade) {
  return '''
{
  "assessments": [
    {
      "gradeLabel": "$modifiedGrade",
      "formative": "Modified formative assessment",
      "exitTask": "Modified exit task",
      "successCriteria": "Modified success criteria",
      "competencyIndex": null
    },
    {
      "gradeLabel": "Grade 4",
      "formative": "Obserbahan ang pakikilahok.",
      "exitTask": "Isulat ang paglalarawan.",
      "successCriteria": "Nailalarawan ang panahon.",
      "competencyIndex": 0
    }
  ]
}
''';
}

/// Good intentions JSON that passes validation
String _goodIntentionsJson() {
  return '''
{
  "sharedSubTheme": "Ulat-panahon at paghahanda sa sakuna",
  "grades": [
    {
      "gradeLabel": "Grade 3",
      "subTheme": "Pag-iisa-isa at paglalarawan",
      "objectives": ["Natutukoy ang mga salitang naglalarawan", "Nakapagbibigay ng payak na paglalarawan"]
    },
    {
      "gradeLabel": "Grade 4",
      "subTheme": "Pangatnig sa teksto",
      "objectives": ["Natutukoy ang pangunahing ideya", "Nakagagamit ang pangatnig"]
    }
  ],
  "bothGradesObjective": "Nauunawaan ang ulat-panahon at nakapagpapahayag ng ideya"
}
''';
}

/// Good learner context JSON
String _goodLearnerContextJson() {
  return r'''{"learnerContext": "Ang mga mag-aaral ay nakatire sa pagitan na kawaranan na may mga kakayang pampobela at mga likas na yaman na kailangang itustus."}
''';
}

/// Good materials JSON
String _goodMaterialsJson() {
  return r'''{"materials": {"items": ["Mga larawan ng panahon", "Activity sheet", "Handouts"], "references": ["DepEd Curriculum Guide", "Science Grade 3 Learner's Module"]}}
''';
}

/// Good flow JSON that matches 90 minutes
String _goodFlowJson() {
  final flow = <String, dynamic>{
    'flow': [
      {
        'minutes': 10,
        'stage': 'Motivation',
        'wholeClass': true,
        'wholeClassActivity': 'Ipakita ang larawan ng ulan.',
        'activityByGrade': <String, String>{},
        'competencyIndexByGrade': <String, int>{},
      },
      {
        'minutes': 15,
        'stage': 'Direct Teaching',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': {
          'Grade 3': 'Basahin at ilarawan ang panahon.',
          'Grade 4': 'Bilugan ang mga pangatnig.',
        },
        'competencyIndexByGrade': {'Grade 3': 0, 'Grade 4': 0},
      },
      {
        'minutes': 10,
        'stage': 'Practice',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': {
          'Grade 3': 'Magbighani ng paglalarawan.',
          'Grade 4': 'Isulat ang liham.',
        },
        'competencyIndexByGrade': {'Grade 3': 0, 'Grade 4': 0},
      },
      {
        'minutes': 20,
        'stage': 'Activity',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': {
          'Grade 3': 'Gawin ang activity sheet.',
          'Grade 4': 'Punan ang patlang.',
        },
        'competencyIndexByGrade': {'Grade 3': 0, 'Grade 4': 0},
      },
      {
        'minutes': 25,
        'stage': 'Application',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': {
          'Grade 3': 'Iguhit ang larawan.',
          'Grade 4': 'Gamitin ang pangatnig.',
        },
        'competencyIndexByGrade': {'Grade 3': 0, 'Grade 4': 0},
      },
      {
        'minutes': 10,
        'stage': 'Wrap-up',
        'wholeClass': true,
        'wholeClassActivity': 'Ipagpakita ang huling gawa.',
        'activityByGrade': <String, String>{},
        'competencyIndexByGrade': <String, int>{},
      },
    ],
  };
  return '${json.encode(flow)}\n';
}

/// Good assessment JSON
String _goodAssessmentJson() {
  return '''
{
  "assessments": [
    {
      "gradeLabel": "Grade 3",
      "formative": "Obserbahan ang pakikilahok sa paglalarawan.",
      "exitTask": "Isulat ang paglalarawan ng ulat-panahon.",
      "successCriteria": "Nakapagpapahayag ng tamang paglalarawan.",
      "competencyIndex": 0
    },
    {
      "gradeLabel": "Grade 4",
      "formative": "Obserbahan ang pangatnig sa teksto.",
      "exitTask": "Punan ang patanggap na pangatnig.",
      "successCriteria": "Nakagagamit ang tamang pangatnig.",
      "competencyIndex": 0
    }
  ]
}
''';
}

/// Good ways forward JSON
String _goodWaysForwardJson() {
  return '''
{
  "waysForward": [
    {
      "gradeLabel": "Grade 3",
      "remediation": "Muling basahin ang lesson at ilarawan ang paglalarawan.",
      "enrichment": "Maghanap ng iba pang halimbawa ng paglalarawan sa mundo."
    },
    {
      "gradeLabel": "Grade 4",
      "remediation": "Magsanay sa paggamit ng pangatnig sa pamamagitan ng mga e-praktik.",
      "enrichment": "Gamitin ang pangatnig sa pagbuo ng sariling liham."
    }
  ],
  "reflectionQuestions": [
    {"gradeLabel": "Grade 3", "text": "Ano ang natutuhan sa paglalarawan?"},
    {"gradeLabel": "Grade 4", "text": "Anong pangatnig ang napagkaloob?"},
    {"gradeLabel": null, "text": "Kumusta ang aralin?"}
  ],
  "notesNextSession": "Ipagpatuloy ang pagtawaran sa susunod na session."
}
''';
}
