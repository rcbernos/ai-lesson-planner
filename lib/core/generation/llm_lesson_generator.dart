/// LLM Lesson Generator implementation using LlmEngine.
library;

import 'dart:async';
import 'dart:convert';

import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/section_runner.dart';
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/validation/plan_validator.dart';
import 'package:ai_lesson_planner/core/validation/validation_issue.dart';

const String defaultAiUseDeclaration =
    'Ang planong ito ay burador na binuo ng AI. Dapat itong repasuhin at ayusin ng guro bago gamitin.';

class LlmLessonGenerator implements LessonGenerator {
  LlmLessonGenerator({required LlmEngine engine, int? seed})
    : _engine = engine,
      _seed = seed;

  final LlmEngine _engine;
  final int? _seed;
  bool _isCancelled = false;
  LessonPlan? _lastPlan;
  final PlanValidator validator = PlanValidator();

  @override
  Stream<GenerationEvent> generate(GenerationRequest request) async* {
    _isCancelled = false;
    _lastPlan = null;

    await for (final event in _generateIntentions(request)) {
      yield event;
      if (event is GenerationFailed) return;
    }
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    await for (final event in _generateLearningExperience(request)) {
      yield event;
      if (event is GenerationFailed) return;
    }
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    await for (final event in _generateAssessment(request)) {
      yield event;
      if (event is GenerationFailed) return;
    }
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    await for (final event in _generateWaysForward(request)) {
      yield event;
      if (event is GenerationFailed) return;
    }
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    final plan = _lastPlan!;
    yield GenerationCompleted(plan);
  }

  Stream<GenerationEvent> _generateIntentions(
    GenerationRequest request,
  ) async* {
    yield SectionStarted('Intentions');

    final prompt = buildIntentionsPrompt(request);
    Map<String, dynamic> json;
    try {
      json = await _requestSectionJson(prompt, 'grades', request);
    } on FormatException {
      // An editable plan can still be drafted from the teacher's inputs.
      // The validator flags missing objectives for the teacher to complete.
      json = const {};
    }
    if (_isCancelled) return;

    _lastPlan = _buildPlanFromIntentions(json, request);
    final errors = validator
        .validateSection(_lastPlan!, PlanSection.intentions)
        .where((issue) => issue.severity == IssueSeverity.error);
    if (errors.isNotEmpty) {
      yield GenerationFailed(errors.map((issue) => issue.message).join('; '));
      return;
    }

    yield SectionCompleted('Intentions');
  }

  Stream<GenerationEvent> _generateLearningExperience(
    GenerationRequest request,
  ) async* {
    yield SectionStarted('Learner Context');
    final context = extractJson(
      await _streamTokens(buildLearnerContextPrompt(request)),
    )?['learnerContext'];
    final learnerContext = context is String ? context.trim() : '';
    yield SectionCompleted('Learner Context');

    yield SectionStarted('Materials');
    final generatedMaterials = extractJson(
      await _streamTokens(buildMaterialsPrompt(request)),
    )?['materials'];
    final items = generatedMaterials is Map
        ? generatedMaterials['items']
        : null;
    final references = generatedMaterials is Map
        ? generatedMaterials['references']
        : null;
    final materials = Materials(
      items: items is List ? items.whereType<String>().toList() : [],
      references: references is List
          ? references.whereType<String>().toList()
          : [],
    );
    yield SectionCompleted('Materials');

    yield SectionStarted('Flow');
    final flow = <FlowStage>[];
    final stages = _buildDefaultFlow(
      request.header.sessionMinutes,
      request.grades,
    );
    for (final stage in stages) {
      final activities = await _generateStageActivities(request, stage);
      if (_isCancelled) return;
      flow.add(
        stage.copyWith(
          wholeClassActivity: stage.wholeClass ? activities.single : '',
          activityByGrade: stage.wholeClass
              ? {}
              : {
                  for (var i = 0; i < request.grades.length; i++)
                    request.grades[i].gradeLabel: activities[i],
                },
        ),
      );
    }
    _lastPlan = _mergeLearningExperience(
      request: request,
      flowJson: null,
      learnerContext: learnerContext,
      materials: materials,
    ).copyWith(flow: flow);

    final errors = validator
        .validateSection(_lastPlan!, PlanSection.learningExperiences)
        .where((issue) => issue.severity == IssueSeverity.error);
    if (errors.isNotEmpty) {
      yield GenerationFailed(errors.map((issue) => issue.message).join('; '));
      return;
    }

    yield SectionCompleted('Flow');
  }

  Future<List<String>> _generateStageActivities(
    GenerationRequest request,
    FlowStage stage,
  ) async {
    final count = stage.wholeClass ? 1 : request.grades.length;
    final prompt = buildStageActivitiesPrompt(
      request,
      stage: stage.stage,
      minutes: stage.minutes,
      wholeClass: stage.wholeClass,
    );
    final slots = List.filled(count, 'string').join(' "," ws ');
    final grammar =
        'root ::= "{" ws "\\"activities\\"" ws ":" ws '
        '"[" ws $slots "]" ws "}"\n'
        r"""
string ::= "\"" char{1,159} [.!?] "\"" ws
char ::= [^"\\\x00-\x1F] | "\\" ["\\/bfnrt]
ws ::= [ \t\n\r]{0,4}
""";
    final retryPrompt = buildRetryPrompt([
      'Return exactly $count short non-empty activity strings.',
    ], prompt);
    final activities = List<String>.filled(count, '');
    for (final attempt in [prompt, retryPrompt]) {
      final response = await _streamTokens(attempt, grammar: grammar);
      if (_isCancelled) return const [];
      final values = extractJson(response)?['activities'];
      if (values is! List || values.length != count) continue;
      for (var i = 0; i < count; i++) {
        if (activities[i].isEmpty && values[i] is String) {
          final text = (values[i] as String).split('<|').first.trim();
          final sentences = RegExp(r'[^.!?]+[.!?]+').allMatches(text);
          activities[i] = sentences.map((match) => match[0]!.trim()).join(' ');
        }
      }
      if (activities.every((activity) => activity.isNotEmpty))
        return activities;
    }
    final placeholder = request.language == OutputLanguage.filipino
        ? 'Magdagdag ng gawain para sa bahaging ito.'
        : 'Add an activity for this stage.';
    return activities.map((text) => text.isEmpty ? placeholder : text).toList();
  }

  Future<Map<String, dynamic>> _requestSectionJson(
    String prompt,
    String field,
    GenerationRequest request,
  ) async {
    final grammar = _sectionGrammar(field, request);
    final response = await _streamTokens(prompt, grammar: grammar);
    if (_isCancelled) return const {};
    try {
      return _requireSectionJson(response, field);
    } on FormatException {
      final retry = await _streamTokens(
        buildRetryPrompt([
          'Return a non-empty $field list in a JSON object.',
        ], prompt),
        grammar: grammar,
      );
      if (_isCancelled) return const {};
      return _requireSectionJson(retry, field);
    }
  }

  Map<String, dynamic> _requireSectionJson(String response, String field) {
    final json = extractJson(response);
    final values = json?[field];
    if (json != null &&
        values is List &&
        values.isNotEmpty &&
        values.every(
          (value) => value is Map<String, dynamic> && value.isNotEmpty,
        )) {
      return json;
    }
    throw FormatException(
      'The local model did not return usable $field content.',
    );
  }

  String _sectionGrammar(String field, GenerationRequest request) {
    final gradeLabelKey = jsonEncode(jsonEncode("gradeLabel"));
    final rows = request.grades
        .asMap()
        .entries
        .map((entry) {
          final label = jsonEncode(jsonEncode(entry.value.gradeLabel));
          return 'grade-${entry.key} ::= "{" ws $gradeLabelKey colon $label ws';
        })
        .join('\n');
    String gradeRows(String details) => [
      for (var i = 0; i < request.grades.length; i++) 'grade-$i $details',
    ].join(' comma ');
    final root = switch (field) {
      'grades' =>
        r'root ::= "{" ws "\"sharedSubTheme\"" colon string comma "\"grades\"" colon "[" ws ' +
            gradeRows('grade-details') +
            r' "]" ws comma "\"bothGradesObjective\"" colon string "}"',
      'flow' =>
        r'root ::= "{" ws "\"flow\"" colon "[" ws stage (comma stage)* "]" ws "}"',
      'assessments' =>
        r'root ::= "{" ws "\"assessments\"" colon "[" ws ' +
            gradeRows('assessment-details') +
            r' "]" ws "}"',
      'waysForward' =>
        r'root ::= "{" ws "\"waysForward\"" colon "[" ws ' +
            gradeRows('followup-details') +
            r' "]" ws comma "\"reflectionQuestions\"" colon "[" ws (question (comma question)*)? "]" ws comma "\"notesNextSession\"" colon string "}"',
      _ => throw ArgumentError.value(field, 'field'),
    };
    return '$root\n$rows\n'
        r'''
grade-details ::= comma "\"subTheme\"" colon string comma "\"objectives\"" colon "[" ws string (comma string)? "]" ws "}" ws
stage ::= "{" ws "\"minutes\"" colon integer comma "\"stage\"" colon string comma "\"wholeClass\"" colon boolean comma "\"wholeClassActivity\"" colon string comma "\"activityByGrade\"" colon text-map comma "\"competencyIndexByGrade\"" colon index-map "}" ws
assessment-details ::= comma "\"formative\"" colon string comma "\"exitTask\"" colon string comma "\"successCriteria\"" colon string comma "\"competencyIndex\"" colon nullable-index "}" ws
followup-details ::= comma "\"remediation\"" colon string comma "\"enrichment\"" colon string "}" ws
question ::= "{" ws "\"gradeLabel\"" colon (string | "null" ws) comma "\"text\"" colon string "}" ws
text-map ::= "{" ws (string colon string (comma string colon string)*)? "}" ws
index-map ::= "{" ws (string colon integer (comma string colon integer)*)? "}" ws
nullable-index ::= integer | "null" ws
integer ::= ("0" | [1-9] [0-9]*) ws
boolean ::= ("true" | "false") ws
string ::= "\"" char{0,120} "\"" ws
char ::= [^"\\\x00-\x1F] | "\\" ["\\/bfnrt]
colon ::= ":" ws
comma ::= "," ws
ws ::= [ \t\n\r]{0,4}
''';
  }

  Future<String> _streamTokens(String prompt, {String? grammar}) async {
    final messages = [ChatMsg(role: 'user', content: prompt)];
    final params = GenParams(
      temperature: 0.3,
      maxTokens: 1024,
      seed: _seed,
      grammar: grammar,
    );

    final buffer = StringBuffer();
    if (_isCancelled) return '';
    await for (final token in _engine.complete(messages, params)) {
      if (_isCancelled) break;
      buffer.write(token);
    }
    return _isCancelled ? '' : buffer.toString();
  }

  LessonPlan _buildPlanFromIntentions(
    Map<String, dynamic>? json,
    GenerationRequest request,
  ) {
    if (json == null) return _buildPlaceholderPlan(request);

    final grades = <GradeBlock>[];
    final gradesJson = json['grades'] as List? ?? [];

    for (var i = 0; i < request.grades.length; i++) {
      final g = request.grades[i];
      final gJson =
          gradesJson.length > i && gradesJson[i] is Map<String, dynamic>
          ? gradesJson[i] as Map<String, dynamic>
          : null;

      final rawObjectives = gJson?['objectives'];
      final objectives = rawObjectives is List
          ? rawObjectives
                .whereType<String>()
                .map((text) => text.split('<|').first.trim())
                .where(
                  (text) => RegExp(r'[\p{L}]', unicode: true).hasMatch(text),
                )
                .toList()
          : <String>[];
      final subTheme = gJson?['subTheme'] as String? ?? g.subTheme;

      grades.add(
        GradeBlock(
          gradeLabel: g.gradeLabel,
          learnersMale: g.male,
          learnersFemale: g.female,
          subTheme: subTheme,
          contentStandard: g.subTheme,
          performanceStandard: '',
          competencies: g.competency
              .split('; ')
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          objectives: objectives,
        ),
      );
    }

    return LessonPlan(
      header: request.header,
      grades: grades,
      sharedSubTheme:
          json['sharedSubTheme'] as String? ?? request.sharedSubTheme,
      bothGradesObjective: json['bothGradesObjective'] as String? ?? '',
      learnerContext: '',
      materials: Materials(),
      flow: [],
      assessments: [],
      reflectionQuestions: [],
      waysForward: [],
      notesNextSession: '',
      preparedBy: request.header.teacher,
      checkedBy: request.header.teacher,
      aiUseDeclaration: '',
      language: request.language == OutputLanguage.filipino ? 'fil' : 'en',
    );
  }

  /// Merges flow, assessments, ways forward onto existing plan (preserves intentions).
  LessonPlan _mergeLearningExperience({
    required GenerationRequest request,
    required Map<String, dynamic>? flowJson,
    required String learnerContext,
    required Materials materials,
  }) {
    final basePlan = _lastPlan ?? _buildPlaceholderPlan(request);

    final flowStages = _buildFlowStages(
      flowJson,
      request.header.sessionMinutes,
      request.grades,
    );
    final assessments = _buildAssessments(request.grades);
    final waysForward = _buildWaysForward(request.grades);
    final reflectionQuestions = _buildReflectionQuestions(
      request.grades,
      flowJson,
    );

    return basePlan.copyWith(
      flow: flowStages,
      assessments: assessments,
      waysForward: waysForward,
      reflectionQuestions: reflectionQuestions,
      notesNextSession: 'Usapan ang aralin sa susunod na session.',
      learnerContext: learnerContext.isEmpty
          ? 'Ang mga mag-aaral ay nakatire sa pagitan na kawaranan.'
          : learnerContext,
      materials: materials.items.isEmpty
          ? Materials(
              items: ['Mga larawan', 'Handouts', 'Manipulatives'],
              references: ['DepEd Curriculum Guide'],
            )
          : materials,
      aiUseDeclaration: defaultAiUseDeclaration,
    );
  }

  LessonPlan _buildCompletePlan(
    GenerationRequest request,
    Map<String, dynamic>? flowJson,
  ) {
    final basePlan = _buildPlanFromIntentions(null, request);
    if (flowJson == null) {
      return basePlan;
    }

    final flowStages = _buildFlowStages(
      flowJson,
      request.header.sessionMinutes,
      request.grades,
    );
    final assessments = _buildAssessments(request.grades);
    final waysForward = _buildWaysForward(request.grades);
    final reflectionQuestions = _buildReflectionQuestions(
      request.grades,
      flowJson,
    );

    return basePlan.copyWith(
      flow: flowStages,
      assessments: assessments,
      waysForward: waysForward,
      reflectionQuestions: reflectionQuestions,
      notesNextSession: 'Usapan ang aralin sa susunod na session.',
      learnerContext: 'Ang mga mag-aaral ay nakatire sa pagitan na kawaranan.',
      materials: Materials(
        items: ['Mga larawan', 'Handouts', 'Manipulatives'],
        references: ['DepEd Curriculum Guide'],
      ),
      aiUseDeclaration: defaultAiUseDeclaration,
    );
  }

  List<FlowStage> _buildFlowStages(
    Map<String, dynamic>? flowJson,
    int sessionMinutes,
    List<GradeInput> grades,
  ) {
    if (flowJson == null) {
      return _buildDefaultFlow(sessionMinutes, grades);
    }

    final flowList = (flowJson['flow'] as List?) ?? [];
    final stages = <FlowStage>[];
    final gradeLabels = grades.map((g) => g.gradeLabel).toList();
    final competencyCounts = grades
        .map(
          (g) =>
              g.competency.split('; ').where((s) => s.trim().isNotEmpty).length,
        )
        .toList();

    for (var i = 0; i < flowList.length; i++) {
      final stageJson = flowList[i] as Map<String, dynamic>? ?? {};
      if (stageJson.isEmpty) continue;

      final minutes = stageJson['minutes'] as int? ?? 0;
      final stageName = stageJson['stage'] as String? ?? 'Activity';
      final wholeClass = stageJson['wholeClass'] as bool? ?? false;
      final wholeClassActivity =
          stageJson['wholeClassActivity'] as String? ?? '';

      final activityByGrade = <String, String>{};
      final activityJson =
          stageJson['activityByGrade'] as Map<String, dynamic>?;
      if (activityJson != null) {
        for (final entry in activityJson.entries) {
          activityByGrade[entry.key] = entry.value as String? ?? '';
        }
      } else {
        for (final label in gradeLabels) {
          activityByGrade[label] = 'Gumawa ng activity na may akda.';
        }
      }

      final competencyIndexByGrade = <String, int>{};
      final compIdxJson =
          stageJson['competencyIndexByGrade'] as Map<String, dynamic>?;
      if (compIdxJson != null) {
        for (final entry in compIdxJson.entries) {
          final idx = entry.value as int? ?? 0;
          final gradeIdx = gradeLabels.indexOf(entry.key);
          if (gradeIdx >= 0 &&
              gradeIdx < competencyCounts.length &&
              competencyCounts[gradeIdx] > 0) {
            competencyIndexByGrade[entry.key] = idx.clamp(
              0,
              competencyCounts[gradeIdx] - 1,
            );
          }
        }
      }

      stages.add(
        FlowStage(
          minutes: minutes,
          stage: stageName,
          wholeClass: wholeClass,
          activityByGrade: activityByGrade,
          wholeClassActivity: wholeClassActivity,
          competencyIndexByGrade: competencyIndexByGrade,
        ),
      );
    }

    return stages;
  }

  List<FlowStage> _buildDefaultFlow(
    int sessionMinutes,
    List<GradeInput> grades,
  ) {
    final total = sessionMinutes;
    if (total < 10) return [];
    final m = (total ~/ 6).clamp(1, total - 5);
    final d = (total ~/ 4).clamp(1, total - m - 3);
    final p = (total ~/ 4).clamp(1, total - m - d - 2);
    final a = (total ~/ 3).clamp(1, total - m - d - p - 1);
    final w = total - m - d - p - a;

    return [
      FlowStage(
        minutes: m,
        stage: 'Motivation',
        wholeClass: true,
        activityByGrade: {},
        wholeClassActivity: 'Ipakita ang larawan.',
        competencyIndexByGrade: const {},
      ),
      FlowStage(
        minutes: d,
        stage: 'Direct Teaching',
        wholeClass: false,
        activityByGrade: Map.fromEntries(
          grades.map(
            (g) => MapEntry(
              g.gradeLabel,
              'Binary na tawag at ilarawan ang kulay ng tema.',
            ),
          ),
        ),
        wholeClassActivity: '',
        competencyIndexByGrade: {},
      ),
      FlowStage(
        minutes: p,
        stage: 'Practice',
        wholeClass: false,
        activityByGrade: Map.fromEntries(
          grades.map(
            (g) => MapEntry(
              g.gradeLabel,
              'Gawin ang worksheet na may mga larawan.',
            ),
          ),
        ),
        wholeClassActivity: '',
        competencyIndexByGrade: {},
      ),
      FlowStage(
        minutes: a,
        stage: 'Activity',
        wholeClass: false,
        activityByGrade: Map.fromEntries(
          grades.map(
            (g) => MapEntry(g.gradeLabel, 'Gumawa ng mapa o diagrama.'),
          ),
        ),
        wholeClassActivity: '',
        competencyIndexByGrade: {},
      ),
      FlowStage(
        minutes: w,
        stage: 'Wrap-up',
        wholeClass: true,
        activityByGrade: {},
        wholeClassActivity: 'Ipagpakita ang huling gawa.',
        competencyIndexByGrade: const {},
      ),
    ];
  }

  List<GradeAssessment> _buildAssessments(List<GradeInput> grades) {
    return grades.map((g) {
      final compCount = g.competency
          .split('; ')
          .where((s) => s.trim().isNotEmpty)
          .length;
      final compIdx = compCount > 0 ? 0 : null;
      return GradeAssessment(
        gradeLabel: g.gradeLabel,
        formative: 'Obserbahan ang pakikilahok.',
        exitTask: 'Isulat ang sumusunod.',
        successCriteria: 'Nakapagpapahayag ng tamang ideya.',
        competencyIndex: compIdx,
      );
    }).toList();
  }

  List<GradeWaysForward> _buildWaysForward(List<GradeInput> grades) {
    return grades
        .map(
          (g) => GradeWaysForward(
            gradeLabel: g.gradeLabel,
            remediation: 'Muling basahin ang lesson.',
            enrichment: 'Maghanap ng iba pang halimbawa.',
          ),
        )
        .toList();
  }

  List<ReflectionQuestion> _buildReflectionQuestions(
    List<GradeInput> grades,
    Map<String, dynamic>? flowJson,
  ) {
    final questions = <ReflectionQuestion>[];
    for (final g in grades) {
      questions.add(
        ReflectionQuestion(
          gradeLabel: g.gradeLabel,
          text: 'Ano ang natutuhan?',
        ),
      );
    }
    questions.add(
      ReflectionQuestion(gradeLabel: null, text: 'Kumusta ang aralin?'),
    );
    return questions;
  }

  LessonPlan _buildPlaceholderPlan(GenerationRequest request) {
    final grades = request.grades;
    final totalMinutes = request.header.sessionMinutes;
    return LessonPlan(
      header: request.header,
      grades: grades
          .map(
            (g) => GradeBlock(
              gradeLabel: g.gradeLabel,
              learnersMale: g.male,
              learnersFemale: g.female,
              subTheme: g.subTheme,
              contentStandard: g.subTheme,
              performanceStandard: '',
              competencies: g.competency
                  .split('; ')
                  .where((s) => s.trim().isNotEmpty)
                  .toList(),
              objectives: ['Natutukoy ang tema.', 'Nakapagpapahayag ng ideya.'],
            ),
          )
          .toList(),
      sharedSubTheme: request.sharedSubTheme,
      bothGradesObjective: 'Nauunawaan at nakapagpapahayag ng ideya.',
      learnerContext: 'Ang mga mag-aaral ay nakatire sa pagitan na kawaranan.',
      materials: Materials(
        items: ['Mga larawan', 'Worksheets'],
        references: ['DepEd Curriculum Guide'],
      ),
      flow: _buildDefaultFlow(totalMinutes, grades),
      assessments: _buildAssessments(grades),
      reflectionQuestions: _buildReflectionQuestions(grades, null),
      waysForward: _buildWaysForward(grades),
      notesNextSession: 'Ipatuloy sa susunod.',
      preparedBy: request.header.teacher,
      checkedBy: request.header.teacher,
      aiUseDeclaration: '',
      language: request.language == OutputLanguage.filipino ? 'fil' : 'en',
    );
  }

  Stream<GenerationEvent> _emitFailure(String message) {
    _isCancelled = false;
    return Stream.value(GenerationFailed(message));
  }

  @override
  Stream<GenerationEvent> generateSection(
    GenerationRequest request,
    PlanSection section,
    LessonPlan current, {
    String? gradeLabel,
  }) async* {
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    yield SectionStarted(section.eventName);

    switch (section) {
      case PlanSection.intentions:
        yield* _regenerateIntentions(request, current, gradeLabel);
      case PlanSection.learningExperiences:
        yield* _regenerateLearningExperience(request, current, gradeLabel);
      case PlanSection.assessment:
        yield* _regenerateAssessment(request, current, gradeLabel);
      case PlanSection.waysForward:
        yield* _regenerateWaysForward(request, current, gradeLabel);
      case PlanSection.header:
        yield SectionCompleted(section.eventName);
        yield GenerationCompleted(current);
    }
  }

  Stream<GenerationEvent> _regenerateIntentions(
    GenerationRequest request,
    LessonPlan current,
    String? gradeLabel,
  ) async* {
    final prompt = buildIntentionsPrompt(request);
    final response = await _streamTokens(prompt);
    final json = extractJson(response);

    final sourcePlan = _buildPlanFromIntentions(json, request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = current.replaceSection(
        PlanSection.intentions,
        sourcePlan,
        gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
    }

    final issues = validator.validateSection(
      mergedPlan,
      PlanSection.intentions,
    );
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        prompt,
      );
      final retryResponse = await _streamTokens(retryPrompt);
      if (_isCancelled) return;
      final retryJson = extractJson(retryResponse);
      final retrySource = _buildPlanFromIntentions(retryJson, request);

      try {
        mergedPlan = current.replaceSection(
          PlanSection.intentions,
          retrySource,
          gradeLabel: gradeLabel,
        );
      } catch (e) {
        yield GenerationFailed('Failed to merge regenerated section: $e');
        _isCancelled = false;
        return;
      }
    }

    _lastPlan = mergedPlan;
    yield SectionCompleted('Intentions');
    yield GenerationCompleted(mergedPlan);
  }

  Stream<GenerationEvent> _regenerateLearningExperience(
    GenerationRequest request,
    LessonPlan current,
    String? gradeLabel,
  ) async* {
    final prompt = buildFlowPrompt(request);
    final response = await _streamTokens(prompt);
    final json = extractJson(response);

    final sourcePlan = _buildCompletePlan(request, json);

    LessonPlan mergedPlan;
    try {
      mergedPlan = current.replaceSection(
        PlanSection.learningExperiences,
        sourcePlan,
        gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
    }

    yield SectionCompleted('Flow');
    _lastPlan = mergedPlan;
    yield GenerationCompleted(mergedPlan);
  }

  Stream<GenerationEvent> _generateAssessment(
    GenerationRequest request,
  ) async* {
    yield SectionStarted('Assessment');

    final prompt = buildAssessmentPrompt(request);
    final json = await _requestSectionJson(prompt, 'assessments', request);
    if (_isCancelled) return;

    final sourcePlan = _buildPlanFromAssessment(json, request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = _lastPlan!.replaceSection(
        PlanSection.assessment,
        sourcePlan,
        gradeLabel: null,
      );
    } catch (e) {
      yield* _emitFailure('Failed to merge regenerated section: $e');
      return;
    }

    _lastPlan = mergedPlan;
    var issues = validator.validateSection(_lastPlan!, PlanSection.assessment);
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        prompt,
      );
      final retryResponse = await _streamTokens(
        retryPrompt,
        grammar: _sectionGrammar('assessments', request),
      );
      if (_isCancelled) return;
      final retryJson = _requireSectionJson(retryResponse, 'assessments');
      final retrySource = _buildPlanFromAssessment(retryJson, request);

      mergedPlan = _lastPlan!.replaceSection(
        PlanSection.assessment,
        retrySource,
        gradeLabel: null,
      );
      _lastPlan = mergedPlan;
      issues = validator.validateSection(_lastPlan!, PlanSection.assessment);

      if (issues.isNotEmpty) {
        yield* _emitFailure(issues.map((i) => i.message).join('; '));
        return;
      }
    }

    yield SectionCompleted('Assessment');
  }

  Stream<GenerationEvent> _generateWaysForward(
    GenerationRequest request,
  ) async* {
    yield SectionStarted('Ways Forward');

    final prompt = buildWaysForwardPrompt(request);
    final json = await _requestSectionJson(prompt, 'waysForward', request);
    if (_isCancelled) return;

    final sourcePlan = _buildPlanFromWaysForward(json, request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = _lastPlan!.replaceSection(
        PlanSection.waysForward,
        sourcePlan,
        gradeLabel: null,
      );
    } catch (e) {
      yield* _emitFailure('Failed to merge regenerated section: $e');
      return;
    }

    _lastPlan = mergedPlan;
    final issues = [
      ...validator.validateSection(_lastPlan!, PlanSection.waysForward),
      ...validator.validateReflection(_lastPlan!),
    ];
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((issue) => issue.message).toList(),
        prompt,
      );
      try {
        final response = await _streamTokens(
          retryPrompt,
          grammar: _sectionGrammar('waysForward', request),
        );
        if (_isCancelled) return;
        final retrySource = _buildPlanFromWaysForward(
          _requireSectionJson(response, 'waysForward'),
          request,
        );
        final revised = mergedPlan.replaceSection(
          PlanSection.waysForward,
          retrySource,
        );
        final revisedIssues = [
          ...validator.validateSection(revised, PlanSection.waysForward),
          ...validator.validateReflection(revised),
        ];
        if (revisedIssues.length < issues.length) _lastPlan = revised;
      } on FormatException {
        // Keep the editable draft and surface its validation warnings.
      }
    }
    final errors = validator
        .validateSection(_lastPlan!, PlanSection.waysForward)
        .where((issue) => issue.severity == IssueSeverity.error);
    if (errors.isNotEmpty) {
      yield* _emitFailure(errors.map((issue) => issue.message).join('; '));
      return;
    }

    yield SectionCompleted('Ways Forward');
  }

  Stream<GenerationEvent> _regenerateAssessment(
    GenerationRequest request,
    LessonPlan current,
    String? gradeLabel,
  ) async* {
    yield SectionStarted('Assessment');

    final prompt = buildAssessmentPrompt(request);
    final response = await _streamTokens(prompt);
    final json = extractJson(response);

    final sourcePlan = _buildPlanFromAssessment(json, request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = current.replaceSection(
        PlanSection.assessment,
        sourcePlan,
        gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
    }

    var issues = validator.validateSection(mergedPlan, PlanSection.assessment);
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        prompt,
      );
      final retryResponse = await _streamTokens(retryPrompt);
      final retryJson = extractJson(retryResponse);
      final retrySource = _buildPlanFromAssessment(retryJson, request);

      try {
        mergedPlan = current.replaceSection(
          PlanSection.assessment,
          retrySource,
          gradeLabel: gradeLabel,
        );
      } catch (e) {
        yield GenerationFailed('Failed to merge regenerated section: $e');
        _isCancelled = false;
        return;
      }
      issues = validator.validateSection(mergedPlan, PlanSection.assessment);

      if (issues.isNotEmpty) {
        yield GenerationFailed(issues.map((i) => i.message).join('; '));
        _isCancelled = false;
        return;
      }
    }

    _lastPlan = mergedPlan;
    yield SectionCompleted('Assessment');
    yield GenerationCompleted(mergedPlan);
  }

  Stream<GenerationEvent> _regenerateWaysForward(
    GenerationRequest request,
    LessonPlan current,
    String? gradeLabel,
  ) async* {
    yield SectionStarted('Ways Forward');

    final prompt = buildWaysForwardPrompt(request);
    final response = await _streamTokens(prompt);
    final json = extractJson(response);

    final sourcePlan = _buildPlanFromWaysForward(json, request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = current.replaceSection(
        PlanSection.waysForward,
        sourcePlan,
        gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
    }

    var issues = validator.validateSection(mergedPlan, PlanSection.waysForward);
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        prompt,
      );
      final retryResponse = await _streamTokens(retryPrompt);
      final retryJson = extractJson(retryResponse);
      final retrySource = _buildPlanFromWaysForward(retryJson, request);

      try {
        mergedPlan = current.replaceSection(
          PlanSection.waysForward,
          retrySource,
          gradeLabel: gradeLabel,
        );
      } catch (e) {
        yield GenerationFailed('Failed to merge regenerated section: $e');
        _isCancelled = false;
        return;
      }
      issues = validator.validateSection(mergedPlan, PlanSection.waysForward);

      if (issues.isNotEmpty) {
        yield GenerationFailed(issues.map((i) => i.message).join('; '));
        _isCancelled = false;
        return;
      }
    }

    // Also validate reflection questions
    issues = validator.validateSection(mergedPlan, PlanSection.waysForward);
    final reflectionIssues = validator.validateReflection(mergedPlan);
    issues.addAll(reflectionIssues);

    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        prompt,
      );
      final retryResponse = await _streamTokens(retryPrompt);
      final retryJson = extractJson(retryResponse);

      try {
        mergedPlan = current.replaceSection(
          PlanSection.waysForward,
          _buildPlanFromWaysForward(retryJson, request),
          gradeLabel: gradeLabel,
        );
      } catch (e) {
        yield GenerationFailed('Failed to merge regenerated section: $e');
        _isCancelled = false;
        return;
      }
    }

    _lastPlan = mergedPlan;
    yield SectionCompleted('Ways Forward');
  }

  /// Builds a LessonPlan from Assessment JSON response.
  LessonPlan _buildPlanFromAssessment(
    Map<String, dynamic>? json,
    GenerationRequest request,
  ) {
    if (json == null) return _buildPlaceholderPlan(request);

    final assessments = <GradeAssessment>[];
    final competencyCounts = {
      for (final grade in request.grades)
        grade.gradeLabel: grade.competency
            .split('; ')
            .where((value) => value.trim().isNotEmpty)
            .length,
    };
    final assessmentsJson = json['assessments'] as List<dynamic>? ?? [];

    for (final a in assessmentsJson) {
      if (a is Map<String, dynamic>) {
        final label = a['gradeLabel'] as String? ?? '';
        final index = a['competencyIndex'];
        final count = competencyCounts[label] ?? 0;
        assessments.add(
          GradeAssessment(
            gradeLabel: label,
            formative: a['formative'] as String? ?? '',
            exitTask: a['exitTask'] as String? ?? '',
            successCriteria: a['successCriteria'] as String? ?? '',
            competencyIndex: index is int && index >= 0 && index < count
                ? index
                : null,
          ),
        );
      }
    }

    return LessonPlan(
      header: request.header,
      grades: request.grades
          .map(
            (g) => GradeBlock(
              gradeLabel: g.gradeLabel,
              learnersMale: g.male,
              learnersFemale: g.female,
              subTheme: g.subTheme,
              contentStandard: g.subTheme,
              performanceStandard: '',
              competencies: g.competency
                  .split('; ')
                  .where((s) => s.trim().isNotEmpty)
                  .toList(),
              objectives: [],
            ),
          )
          .toList(),
      sharedSubTheme: request.sharedSubTheme,
      bothGradesObjective: '',
      learnerContext: '',
      materials: Materials(),
      flow: [],
      assessments: assessments,
      reflectionQuestions: [],
      waysForward: [],
      notesNextSession: '',
      preparedBy: request.header.teacher,
      checkedBy: request.header.teacher,
      aiUseDeclaration: '',
      language: request.language == OutputLanguage.filipino ? 'fil' : 'en',
    );
  }

  /// Builds a LessonPlan from Ways Forward JSON response.
  LessonPlan _buildPlanFromWaysForward(
    Map<String, dynamic>? json,
    GenerationRequest request,
  ) {
    if (json == null) return _buildPlaceholderPlan(request);

    final knownGrades = {
      for (final grade in request.grades) grade.gradeLabel: grade,
    };
    String normalize(String text) => text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim();
    String followupText(Object? value, String competency) {
      if (value is! String) return '';
      final normalized = normalize(value);
      final copiesCompetency = [
        competency,
        ...competency.split(';'),
      ].any((item) => normalized == normalize(item));
      return copiesCompetency ? '' : value.trim();
    }

    final rows = json['waysForward'];
    final waysForward = <GradeWaysForward>[];
    if (rows is List) {
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final grade = knownGrades[row['gradeLabel']];
        if (grade == null) continue;
        final remediation = followupText(row['remediation'], grade.competency);
        final enrichment = followupText(row['enrichment'], grade.competency);
        waysForward.add(
          GradeWaysForward(
            gradeLabel: grade.gradeLabel,
            remediation: remediation,
            enrichment: normalize(remediation) == normalize(enrichment)
                ? ''
                : enrichment,
          ),
        );
      }
    }

    final reflectionQuestions = <ReflectionQuestion>[];
    final questions = json['reflectionQuestions'];
    if (questions is List) {
      for (final question in questions.whereType<Map<String, dynamic>>()) {
        final rawLabel = question['gradeLabel'];
        if (rawLabel != null && rawLabel is! String) continue;
        final label = (rawLabel as String?)?.replaceFirst(
          RegExp(r'^gradle(?=\s+\d)', caseSensitive: false),
          'Grade',
        );
        if (label != null && !knownGrades.containsKey(label)) continue;
        final text = question['text'];
        if (text is! String || text.trim().isEmpty) continue;
        final corrected = text.replaceAllMapped(
          RegExp(r'\bgradle(?=\s+\d)', caseSensitive: false),
          (_) => 'Grade',
        );
        final mentionedGrades = RegExp(
          r'\bgrade\s+(\d+)\b',
          caseSensitive: false,
        ).allMatches(corrected);
        if (mentionedGrades.any(
          (match) => !knownGrades.containsKey('Grade ${match[1]}'),
        )) {
          continue;
        }
        reflectionQuestions.add(
          ReflectionQuestion(gradeLabel: label, text: corrected),
        );
      }
    }

    final notesNextSession = json['notesNextSession'] as String? ?? '';

    return LessonPlan(
      header: request.header,
      grades: request.grades
          .map(
            (g) => GradeBlock(
              gradeLabel: g.gradeLabel,
              learnersMale: g.male,
              learnersFemale: g.female,
              subTheme: g.subTheme,
              contentStandard: g.subTheme,
              performanceStandard: '',
              competencies: g.competency
                  .split('; ')
                  .where((s) => s.trim().isNotEmpty)
                  .toList(),
              objectives: [],
            ),
          )
          .toList(),
      sharedSubTheme: request.sharedSubTheme,
      bothGradesObjective: '',
      learnerContext: '',
      materials: Materials(),
      flow: [],
      assessments: [],
      reflectionQuestions: reflectionQuestions,
      waysForward: waysForward,
      notesNextSession: notesNextSession,
      preparedBy: request.header.teacher,
      checkedBy: request.header.teacher,
      aiUseDeclaration: '',
      language: request.language == OutputLanguage.filipino ? 'fil' : 'en',
    );
  }

  @override
  void cancel() {
    _isCancelled = true;
    unawaited(_engine.cancel());
  }
}
