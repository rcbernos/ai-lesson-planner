/// Mock lesson generator that simulates streaming generation.
/// Used for development and testing before LLM integration.
library;

import 'dart:async';
import 'dart:math';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'lesson_generator.dart';

/// Mock implementation that simulates streaming generation with delays.
class MockLessonGenerator implements LessonGenerator {
  final Random _random = Random();
  bool _isCancelled = false;

  @override
  Stream<GenerationEvent> generate(GenerationRequest request) async* {
    // Check if already cancelled
    if (_isCancelled) return;

    // Section 1: Intentions
    if (_isCancelled) return;
    yield SectionStarted('Intentions');
    await _simulateDelay();
    if (_isCancelled) return;
    yield SectionCompleted('Intentions');

    // Section 2: Learning Experiences
    if (_isCancelled) return;
    yield SectionStarted('Learning Experiences');
    await _simulateDelay();
    if (_isCancelled) return;
    yield SectionCompleted('Learning Experiences');

    // Section 3: Assessment
    if (_isCancelled) return;
    yield SectionStarted('Assessment');
    await _simulateDelay();
    if (_isCancelled) return;
    yield SectionCompleted('Assessment');

    // Section 4: Ways Forward
    if (_isCancelled) return;
    yield SectionStarted('Ways Forward');
    await _simulateDelay();
    if (_isCancelled) return;
    yield SectionCompleted('Ways Forward');

    // Final: complete plan (only if not cancelled)
    if (!_isCancelled) {
      yield GenerationCompleted(_buildPlan(request));
    }
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(Duration(milliseconds: 50 + 30 * _random.nextInt(2)));
  }

  @override
  void cancel() {
    _isCancelled = true;
  }

  // --- Build Plan Methods ---

  LessonPlan _buildPlan(GenerationRequest request) {
    final grades = request.grades;
    final header = request.header;

    final gradeBlocks = grades
        .map((g) => GradeBlock(
              gradeLabel: g.gradeLabel,
              learnersMale: g.male,
              learnersFemale: g.female,
              subTheme: g.subTheme,
              contentStandard: _contentStandard(g.gradeLabel),
              performanceStandard: _performanceStandard(g.gradeLabel),
              competencies: [g.competency],
              objectives: [
                'Natutukoy ang ${g.subTheme.split(' ').first}.',
                'Nakapagpapahayag ng ideya.'
              ],
            ))
        .toList();

    return LessonPlan(
      header: header,
      grades: gradeBlocks,
      sharedSubTheme: request.sharedSubTheme,
      bothGradesObjective: _objective(request.sharedSubTheme),
      learnerContext: 'Ang mga mag-aaral ay nakatira sa pagitan na kawaranan.',
      materials: ['Mga larawan', 'Worksheets'],
      references: ['DepEd Curriculum Guide'],
      flow: _buildFlow(header.sessionMinutes, grades),
      assessments: _buildAssessments(grades),
      reflectionQuestions:
          _buildReflectionQuestions(grades, request.sharedSubTheme),
      waysForward: _buildWaysForward(grades),
      notesNextSession: 'Ipatuloy sa susunod.',
      preparedBy: header.teacher,
      checkedBy: 'Juan Dela Cruz',
      aiUseDeclaration: defaultAiUseDeclaration,
    );
  }

  String _contentStandard(String gradeLabel) {
    return 'Naipamamalas ng mag-aaral na unawa sa teksto.';
  }

  String _performanceStandard(String gradeLabel) {
    return 'Nagagamit ang mga salitang naglalarawan.';
  }

  String _objective(String sharedSubTheme) {
    return 'Nauunawaan at nakapagpapahayag ng ideya sa $sharedSubTheme.';
  }

  List<GradeAssessment> _buildAssessments(List<GradeInput> grades) {
    return grades
        .map((g) => GradeAssessment(
              gradeLabel: g.gradeLabel,
              formative: 'Obserbahan ang pakikilahok.',
              exitTask: 'Isulat ang sumusunod.',
              successCriteria: 'Nailalarawan at nakapagpapahayag.',
            ))
        .toList();
  }

  List<ReflectionQuestion> _buildReflectionQuestions(
      List<GradeInput> grades, String sharedSubTheme) {
    final questions = <ReflectionQuestion>[];
    for (final g in grades) {
      questions.add(ReflectionQuestion(
        gradeLabel: g.gradeLabel,
        text: 'Ano ang natutuhan sa $_firstWord(sharedSubTheme)?',
      ));
    }
    questions
        .add(ReflectionQuestion(gradeLabel: null, text: 'Kumusta ang aralin?'));
    return questions;
  }

  String _firstWord(String text) {
    return text.split(' ').first;
  }

  List<GradeWaysForward> _buildWaysForward(List<GradeInput> grades) {
    return grades
        .map((g) => GradeWaysForward(
              gradeLabel: g.gradeLabel,
              remediation: 'Muling basahin.',
              enrichment: 'Maghanap ng iba pang halimbawa.',
            ))
        .toList();
  }

  List<FlowStage> _buildFlow(int sessionMinutes, List<GradeInput> grades) {
    final total = sessionMinutes;
    final m = total ~/ 6;
    final d = total ~/ 4;
    final p = total ~/ 4;
    final a = total ~/ 3;
    final w = total - m - d - p - a;

    return [
      FlowStage(
          minutes: m,
          stage: 'Motivation',
          wholeClass: true,
          activityByGrade: {},
          wholeClassActivity: 'Ipakita ang larawan.'),
      FlowStage(
        minutes: d,
        stage: 'Direct Teaching',
        wholeClass: false,
        activityByGrade: Map.fromEntries(
            grades.map((g) => MapEntry(g.gradeLabel, 'Basahin at ilarawan.'))),
        wholeClassActivity: '',
      ),
      FlowStage(
        minutes: p,
        stage: 'Practice',
        wholeClass: false,
        activityByGrade: Map.fromEntries(
            grades.map((g) => MapEntry(g.gradeLabel, 'Gawin ang worksheet.'))),
        wholeClassActivity: '',
      ),
      FlowStage(
        minutes: a,
        stage: 'Activity',
        wholeClass: false,
        activityByGrade: Map.fromEntries(
            grades.map((g) => MapEntry(g.gradeLabel, 'Gumawa ng guhit.'))),
        wholeClassActivity: '',
      ),
      FlowStage(
          minutes: w,
          stage: 'Wrap-up',
          wholeClass: true,
          activityByGrade: {},
          wholeClassActivity: 'Ipagpakita ang huling gawa.'),
    ];
  }
}
