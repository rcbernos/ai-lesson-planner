/// Mock lesson generator that simulates streaming generation.
/// Used for development and testing before LLM integration.
library;

import 'dart:async';
import 'dart:math';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/models/plan_section_patch.dart';
import 'lesson_generator.dart';

/// Mock implementation that simulates streaming generation with delays.
class MockLessonGenerator implements LessonGenerator {
  final Random _random = Random();
  bool _isCancelled = false;
  int _variantCounter = 0;

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
      _isCancelled = false; // Reset for reuse
      yield GenerationCompleted(_buildPlan(request));
    }
  }

  @override
  Stream<GenerationEvent> generateSection(
    GenerationRequest request,
    PlanSection section,
    LessonPlan current, {
    String? gradeLabel,
  }) async* {
    if (_isCancelled) return;

    yield SectionStarted(section.eventName);

    // Build a fresh plan and apply the section replacement
    final freshPlan = _buildPlan(request);
    final mergedPlan =
        current.replaceSection(section, freshPlan, gradeLabel: gradeLabel);

    // Apply variant marker for visibility
    final variantPlan = _applyVariantMarker(mergedPlan, section, gradeLabel);

    await _simulateDelay();
    if (_isCancelled) return;

    yield SectionCompleted(section.eventName);

    if (!_isCancelled) {
      _isCancelled = false; // Reset for reuse
      yield GenerationCompleted(variantPlan);
    }
  }

  /// Applies a "(variant N)" marker to generated content for visibility.
  LessonPlan _applyVariantMarker(
      LessonPlan plan, PlanSection section, String? gradeLabel) {
    final variant = _variantCounter++;
    final suffix = ' (variant $variant)';

    switch (section) {
      case PlanSection.header:
        return plan; // Header never changes

      case PlanSection.intentions:
        if (gradeLabel != null) {
          final newGrades = plan.grades.map((g) {
            if (g.gradeLabel == gradeLabel) {
              return g.copyWith(
                objectives: g.objectives.map((o) => '$o$suffix').toList(),
              );
            }
            return g;
          }).toList();
          return plan.copyWith(grades: newGrades);
        }
        final newGoals = plan.bothGradesObjective + suffix;
        return plan.copyWith(bothGradesObjective: newGoals);

      case PlanSection.learningExperiences:
        final newFlow = plan.flow.asMap().values.map((s) {
          final newActivityByGrade =
              Map<String, String>.from(s.activityByGrade);
          if (gradeLabel != null &&
              newActivityByGrade.containsKey(gradeLabel)) {
            newActivityByGrade[gradeLabel] =
                '${newActivityByGrade[gradeLabel]}$suffix';
          } else if (gradeLabel == null) {
            newActivityByGrade.updateAll((k, v) => '$v$suffix');
          }
          return s.copyWith(activityByGrade: newActivityByGrade);
        }).toList();
        return plan.copyWith(flow: newFlow);

      case PlanSection.assessment:
        final newAssessments = plan.assessments.map((a) {
          if (gradeLabel != null && a.gradeLabel == gradeLabel) {
            return a.copyWith(
              formative: '${a.formative}$suffix',
              exitTask: '${a.exitTask}$suffix',
            );
          }
          if (gradeLabel == null) {
            return a.copyWith(
              formative: '${a.formative}$suffix',
              exitTask: '${a.exitTask}$suffix',
            );
          }
          return a;
        }).toList();
        return plan.copyWith(assessments: newAssessments);

      case PlanSection.waysForward:
        final newWaysForward = plan.waysForward.map((w) {
          if (gradeLabel != null && w.gradeLabel == gradeLabel) {
            return w.copyWith(
              remediation: '${w.remediation}$suffix',
              enrichment: '${w.enrichment}$suffix',
            );
          }
          return w;
        }).toList();
        final newReflections = plan.reflectionQuestions.map((r) {
          if (r.gradeLabel == gradeLabel) {
            return r.copyWith(text: '${r.text}$suffix');
          }
          return r;
        }).toList();
        return plan.copyWith(
            waysForward: newWaysForward, reflectionQuestions: newReflections);
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
      materials: Materials(
        items: ['Mga larawan', 'Worksheets'],
        references: ['DepEd Curriculum Guide'],
      ),
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
              competencyIndex: 0,
            ))
        .toList();
  }

  List<ReflectionQuestion> _buildReflectionQuestions(
      List<GradeInput> grades, String sharedSubTheme) {
    final questions = <ReflectionQuestion>[];
    for (final g in grades) {
      questions.add(ReflectionQuestion(
        gradeLabel: g.gradeLabel,
        text: 'Ano ang natutuhan sa ${_firstWord(sharedSubTheme)}?',
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

    // Build competency index map for non-whole-class stages
    final competencyIndexByGrade =
        Map.fromEntries(grades.map((g) => MapEntry(g.gradeLabel, 0)));

    return [
      FlowStage(
          minutes: m,
          stage: 'Motivation',
          wholeClass: true,
          activityByGrade: {},
          wholeClassActivity: 'Ipakita ang larawan.',
          competencyIndexByGrade: const {}),
      FlowStage(
          minutes: d,
          stage: 'Direct Teaching',
          wholeClass: false,
          activityByGrade: Map.fromEntries(grades
              .map((g) => MapEntry(g.gradeLabel, 'Basahin at ilarawan.'))),
          wholeClassActivity: '',
          competencyIndexByGrade: competencyIndexByGrade),
      FlowStage(
          minutes: p,
          stage: 'Practice',
          wholeClass: false,
          activityByGrade: Map.fromEntries(grades
              .map((g) => MapEntry(g.gradeLabel, 'Gawin ang worksheet.'))),
          wholeClassActivity: '',
          competencyIndexByGrade: competencyIndexByGrade),
      FlowStage(
          minutes: a,
          stage: 'Activity',
          wholeClass: false,
          activityByGrade: Map.fromEntries(
              grades.map((g) => MapEntry(g.gradeLabel, 'Gumawa ng guhit.'))),
          wholeClassActivity: '',
          competencyIndexByGrade: competencyIndexByGrade),
      FlowStage(
          minutes: w,
          stage: 'Wrap-up',
          wholeClass: true,
          activityByGrade: {},
          wholeClassActivity: 'Ipagpakita ang huling gawa.',
          competencyIndexByGrade: const {}),
    ];
  }
}
