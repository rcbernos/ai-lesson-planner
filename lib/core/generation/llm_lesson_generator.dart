/// LLM Lesson Generator implementation using LlmEngine.
library;

import 'dart:async';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/section_runner.dart';
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/models/plan_section_patch.dart';
import 'package:ai_lesson_planner/core/validation/plan_validator.dart';

const String defaultAiUseDeclaration =
    'Ang planong ito ay burador na binuo ng AI. Dapat itong repasuhin at ayusin ng guro bago gamitin.';

class LlmLessonGenerator implements LessonGenerator {
  LlmLessonGenerator({required LlmEngine engine, int? seed})
      : _engine = engine,
        _seed = seed;

  final LlmEngine _engine;
  final int? _seed;
  StreamSubscription<String>? _tokenSub;
  bool _isCancelled = false;
  LessonPlan? _lastPlan;
  final PlanValidator validator = PlanValidator();

  @override
  Stream<GenerationEvent> generate(GenerationRequest request) async* {
    _isCancelled = false;
    _lastPlan = null;

    yield* _generateIntentions(request);
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    yield* _generateLearningExperience(request);
    if (_isCancelled) {
      yield* _emitFailure('Generation cancelled');
      return;
    }

    final plan = _lastPlan!;
    yield GenerationCompleted(plan);
  }

  Stream<GenerationEvent> _generateIntentions(GenerationRequest request) async* {
    yield SectionStarted('Intentions');

    final prompt = buildIntentionsPrompt(request);
    final response = await _streamTokens(prompt);
    final json = extractJson(response);
    
    _lastPlan = _buildPlanFromIntentions(json, request);
    var issues = validator.validateSection(_lastPlan!, PlanSection.intentions);

    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        prompt,
      );
      final retryResponse = await _streamTokens(retryPrompt);
      _lastPlan = _buildPlanFromIntentions(extractJson(retryResponse), request);
      issues = validator.validateSection(_lastPlan!, PlanSection.intentions);

      if (issues.isNotEmpty) {
        yield GenerationFailed(issues.map((i) => i.message).join('; '));
        _isCancelled = false;
        return;
      }
    }

    yield SectionCompleted('Intentions');
    yield GenerationCompleted(_lastPlan!);
  }

  Stream<GenerationEvent> _generateLearningExperience(GenerationRequest request) async* {
    yield SectionStarted('Learner Context');
    await _streamTokens(buildLearnerContextPrompt(request));
    yield SectionCompleted('Learner Context');

    yield SectionStarted('Materials');
    await _streamTokens(buildMaterialsPrompt(request));
    yield SectionCompleted('Materials');

    yield SectionStarted('Flow');
    final flowResponse = await _streamTokens(buildFlowPrompt(request));
    final flowJson = extractJson(flowResponse);
    
    _lastPlan = _buildCompletePlan(request, flowJson);
    
    var issues = validator.validateSection(_lastPlan!, PlanSection.learningExperiences);
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(
        issues.map((i) => i.message).toList(),
        buildFlowPrompt(request),
      );
      final retryResponse = await _streamTokens(retryPrompt);
      _lastPlan = _buildCompletePlan(request, extractJson(retryResponse));
      issues = validator.validateSection(_lastPlan!, PlanSection.learningExperiences);

      if (issues.isNotEmpty) {
        yield GenerationFailed(issues.map((i) => i.message).join('; '));
        _isCancelled = false;
        return;
      }
    }
    
    yield SectionCompleted('Flow');
    yield GenerationCompleted(_lastPlan!);
  }

  Future<String> _streamTokens(String prompt) async {
    final messages = [ChatMsg(role: 'system', content: prompt)];
    final params = GenParams(
      temperature: 0.3,
      maxTokens: 1024,
      seed: _seed,
    );

    final buffer = StringBuffer();
    final completer = Completer<String>();

    _tokenSub = _engine.complete(messages, params).listen(
      (token) => buffer.write(token),
      onDone: () {
        if (!_isCancelled && !completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
    );

    return completer.future;
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
      final gJson = gradesJson.length > i && gradesJson[i] is Map<String, dynamic>
          ? gradesJson[i] as Map<String, dynamic>
          : null;

      final objectives = (gJson?['objectives'] as List?)
              ?.cast<String>() ??
          [];
      final subTheme = gJson?['subTheme'] as String? ?? g.subTheme;

      grades.add(GradeBlock(
        gradeLabel: g.gradeLabel,
        learnersMale: g.male,
        learnersFemale: g.female,
        subTheme: subTheme,
        contentStandard: g.subTheme,
        performanceStandard: '',
        competencies: g.competency.split('; ').where((s) => s.trim().isNotEmpty).toList(),
        objectives: objectives,
      ));
    }

    return LessonPlan(
      header: request.header,
      grades: grades,
      sharedSubTheme: json['sharedSubTheme'] as String? ?? '',
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

  LessonPlan _buildCompletePlan(
    GenerationRequest request,
    Map<String, dynamic>? flowJson,
  ) {
    final basePlan = _buildPlanFromIntentions(null, request);
    if (flowJson == null) {
      return basePlan;
    }

    final flowStages = _buildFlowStages(flowJson, request.header.sessionMinutes, request.grades);
    final assessments = _buildAssessments(request.grades);
    final waysForward = _buildWaysForward(request.grades);
    final reflectionQuestions = _buildReflectionQuestions(request.grades, flowJson);
    
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
    final competencyCounts = grades.map(
      (g) => g.competency.split('; ').where((s) => s.trim().isNotEmpty).length
    ).toList();

    for (var i = 0; i < flowList.length; i++) {
      final stageJson = flowList[i] as Map<String, dynamic>? ?? {};
      if (stageJson.isEmpty) continue;

      final minutes = stageJson['minutes'] as int? ?? 0;
      final stageName = stageJson['stage'] as String? ?? 'Activity';
      final wholeClass = stageJson['wholeClass'] as bool? ?? false;
      final wholeClassActivity = stageJson['wholeClassActivity'] as String? ?? '';
      
      final activityByGrade = <String, String>{};
      final activityJson = stageJson['activityByGrade'] as Map<String, dynamic>?;
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
      final compIdxJson = stageJson['competencyIndexByGrade'] as Map<String, dynamic>?;
      if (compIdxJson != null) {
        for (final entry in compIdxJson.entries) {
          final idx = entry.value as int? ?? 0;
          final gradeIdx = gradeLabels.indexOf(entry.key);
          if (gradeIdx >= 0 && 
              gradeIdx < competencyCounts.length && 
              competencyCounts[gradeIdx] > 0) {
            competencyIndexByGrade[entry.key] = idx.clamp(0, competencyCounts[gradeIdx] - 1);
          }
        }
      }

      stages.add(FlowStage(
        minutes: minutes,
        stage: stageName,
        wholeClass: wholeClass,
        activityByGrade: activityByGrade,
        wholeClassActivity: wholeClassActivity,
        competencyIndexByGrade: competencyIndexByGrade,
      ));
    }

    return stages;
  }

  List<FlowStage> _buildDefaultFlow(int sessionMinutes, List<GradeInput> grades) {
    final total = sessionMinutes;
    if (total < 10) return [];
    final m = (total ~/ 6).clamp(1, total - 5);
    final d = (total ~/ 4).clamp(1, total - m - 3);
    final p = (total ~/ 4).clamp(1, total - m - d - 2);
    final a = (total ~/ 3).clamp(1, total - m - d - p);
    final w = total - m - d - p - a;

    return [
      FlowStage(
        minutes: m, stage: 'Motivation', wholeClass: true,
        activityByGrade: {}, wholeClassActivity: 'Ipakita ang larawan.',
        competencyIndexByGrade: const {},
      ),
      FlowStage(
        minutes: d, stage: 'Direct Teaching', wholeClass: false,
        activityByGrade: Map.fromEntries(
          grades.map((g) => MapEntry(g.gradeLabel, 'Binary na tawag at ilarawan ang kulay ng tema.')),
        ),
        wholeClassActivity: '', competencyIndexByGrade: {},
      ),
      FlowStage(
        minutes: p, stage: 'Practice', wholeClass: false,
        activityByGrade: Map.fromEntries(
          grades.map((g) => MapEntry(g.gradeLabel, 'Gawin ang worksheet na may mga larawan.')),
        ),
        wholeClassActivity: '', competencyIndexByGrade: {},
      ),
      FlowStage(
        minutes: a, stage: 'Activity', wholeClass: false,
        activityByGrade: Map.fromEntries(
          grades.map((g) => MapEntry(g.gradeLabel, 'Gumawa ng mapa o diagrama.')),
        ),
        wholeClassActivity: '', competencyIndexByGrade: {},
      ),
      FlowStage(
        minutes: w, stage: 'Wrap-up', wholeClass: true,
        activityByGrade: {}, wholeClassActivity: 'Ipagpakita ang huling gawa.',
        competencyIndexByGrade: const {},
      ),
    ];
  }

  List<GradeAssessment> _buildAssessments(List<GradeInput> grades) {
    return grades.map((g) {
      final compCount = g.competency.split('; ').where((s) => s.trim().isNotEmpty).length;
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
    return grades.map((g) => GradeWaysForward(
      gradeLabel: g.gradeLabel,
      remediation: 'Muling basahin ang lesson.',
      enrichment: 'Maghanap ng iba pang halimbawa.',
    )).toList();
  }

  List<ReflectionQuestion> _buildReflectionQuestions(
    List<GradeInput> grades, Map<String, dynamic>? flowJson,
  ) {
    final questions = <ReflectionQuestion>[];
    for (final g in grades) {
      questions.add(ReflectionQuestion(gradeLabel: g.gradeLabel, text: 'Ano ang natutuhan?'));
    }
    questions.add(ReflectionQuestion(gradeLabel: null, text: 'Kumusta ang aralin?'));
    return questions;
  }

  LessonPlan _buildPlaceholderPlan(GenerationRequest request) {
    final grades = request.grades;
    final totalMinutes = request.header.sessionMinutes;
    return LessonPlan(
      header: request.header,
      grades: grades.map((g) => GradeBlock(
        gradeLabel: g.gradeLabel,
        learnersMale: g.male, learnersFemale: g.female,
        subTheme: g.subTheme, contentStandard: g.subTheme,
        performanceStandard: '',
        competencies: g.competency.split('; ').where((s) => s.trim().isNotEmpty).toList(),
        objectives: ['Natutukoy ang tema.', 'Nakapagpapahayag ng ideya.'],
      )).toList(),
      sharedSubTheme: request.sharedSubTheme,
      bothGradesObjective: 'Nauunawaan at nakapagpapahayag ng ideya.',
      learnerContext: 'Ang mga mag-aaral ay nakatire sa pagitan na kawaranan.',
      materials: Materials(items: ['Mga larawan', 'Worksheets'], references: ['DepEd Curriculum Guide']),
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
        PlanSection.intentions, sourcePlan, gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
    }

    final issues = validator.validateSection(mergedPlan, PlanSection.intentions);
    if (issues.isNotEmpty) {
      final retryPrompt = buildRetryPrompt(issues.map((i) => i.message).toList(), prompt);
      final retryResponse = await _streamTokens(retryPrompt);
      final retryJson = extractJson(retryResponse);
      final retrySource = _buildPlanFromIntentions(retryJson, request);

      try {
        mergedPlan = current.replaceSection(
          PlanSection.intentions, retrySource, gradeLabel: gradeLabel,
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
        PlanSection.learningExperiences, sourcePlan, gradeLabel: gradeLabel,
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

  Stream<GenerationEvent> _regenerateAssessment(
    GenerationRequest request,
    LessonPlan current,
    String? gradeLabel,
  ) async* {
    final sourcePlan = _buildPlaceholderPlan(request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = current.replaceSection(
        PlanSection.assessment, sourcePlan, gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
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
    final sourcePlan = _buildPlaceholderPlan(request);

    LessonPlan mergedPlan;
    try {
      mergedPlan = current.replaceSection(
        PlanSection.waysForward, sourcePlan, gradeLabel: gradeLabel,
      );
    } catch (e) {
      yield GenerationFailed('Failed to merge regenerated section: $e');
      _isCancelled = false;
      return;
    }

    _lastPlan = mergedPlan;
    yield SectionCompleted('Ways Forward');
    yield GenerationCompleted(mergedPlan);
  }

  @override
  void cancel() {
    _isCancelled = true;
    _tokenSub?.cancel();
    _engine.cancel();
  }
}
