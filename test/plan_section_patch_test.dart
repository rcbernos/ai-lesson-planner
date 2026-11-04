import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/models/plan_section_patch.dart';
import 'package:test/test.dart';

import 'fixtures/sample_plan.dart';

void main() {
  group('PlanSectionPatch extension', () {
    late LessonPlan originalPlan;
    late LessonPlan modifiedPlan;
    late LessonPlan modifiedFlowPlan;
    late LessonPlan modifiedAssessmentPlan;
    late LessonPlan modifiedWaysForwardPlan;

    setUp(() {
      originalPlan = createSamplePlan();
      modifiedPlan = originalPlan.copyWith(
        grades: [
          originalPlan.grades[0].copyWith(
            objectives: ['Modified objective 1', 'Modified objective 2'],
          ),
          originalPlan.grades[1].copyWith(
            objectives: ['Modified objective A'],
          ),
        ],
      );
      modifiedFlowPlan = originalPlan.copyWith(
        flow: originalPlan.flow.asMap().entries.map((e) {
          final stage = e.value;
          final newActivityByGrade =
              Map<String, String>.from(stage.activityByGrade);
          newActivityByGrade['Grade 3'] =
              'Modified activity for stage ${e.key + 1}';
          return FlowStage(
            minutes: stage.minutes,
            stage: stage.stage,
            wholeClass: stage.wholeClass,
            activityByGrade: newActivityByGrade,
            wholeClassActivity: stage.wholeClassActivity,
          );
        }).toList(),
      );
      modifiedAssessmentPlan = originalPlan.copyWith(
        assessments: [
          GradeAssessment(
            gradeLabel: 'Grade 3',
            formative: 'Modified formative assessment',
            exitTask: 'Modified exit task',
            successCriteria: 'Modified success criteria',
          ),
          GradeAssessment(
            gradeLabel: 'Grade 4',
            formative: 'Obserbahan ang pangatnig.',
            exitTask: 'Punan ang patlang.',
            successCriteria: 'Nakagagamit ang pangatnig.',
          ),
        ],
      );
      modifiedWaysForwardPlan = originalPlan.copyWith(
        waysForward: [
          GradeWaysForward(
            gradeLabel: 'Grade 3',
            remediation: 'Modified remediation',
            enrichment: 'Modified enrichment',
          ),
          GradeWaysForward(
            gradeLabel: 'Grade 4',
            remediation: 'Magsanay.',
            enrichment: 'Gamitin nang higit.',
          ),
        ],
        reflectionQuestions: [
          ReflectionQuestion(
              gradeLabel: 'Grade 3', text: 'Modified reflection for Grade 3'),
          ReflectionQuestion(gradeLabel: 'Grade 4', text: 'Anong pangatnig?'),
          ReflectionQuestion(gradeLabel: null, text: 'Kumusta ang aralin?'),
        ],
      );
    });

    test('header section returns unchanged', () {
      final result = originalPlan.replaceSection(
        PlanSection.header,
        modifiedPlan,
      );
      expect(result.header.school, equals(originalPlan.header.school));
      expect(result.header.teacher, equals(originalPlan.header.teacher));
    });

    test('intentions full section replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.intentions,
        modifiedPlan,
      );
      expect(result.grades[0].objectives,
          equals(['Modified objective 1', 'Modified objective 2']));
      expect(result.grades[1].objectives, equals(['Modified objective A']));
      expect(result.grades[0].contentStandard,
          equals(originalPlan.grades[0].contentStandard));
      expect(
          result.grades[0].subTheme, equals(originalPlan.grades[0].subTheme));
    });

    test('intentions grade slice replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.intentions,
        modifiedPlan,
        gradeLabel: 'Grade 3',
      );
      expect(result.grades[0].objectives,
          equals(['Modified objective 1', 'Modified objective 2']));
      expect(result.grades[1].objectives,
          equals(originalPlan.grades[1].objectives));
    });

    test('learningExperiences full section replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.learningExperiences,
        modifiedFlowPlan,
      );
      expect(result.learnerContext, equals(modifiedFlowPlan.learnerContext));
      expect(result.materials, equals(modifiedFlowPlan.materials));
      expect(result.flow.length, equals(modifiedFlowPlan.flow.length));
      expect(result.header.school, equals(originalPlan.header.school));
      expect(result.sharedSubTheme, equals(originalPlan.sharedSubTheme));
    });

    test('learningExperiences grade slice replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.learningExperiences,
        modifiedFlowPlan,
        gradeLabel: 'Grade 3',
      );
      for (var i = 0; i < result.flow.length; i++) {
        expect(result.flow[i].minutes, equals(originalPlan.flow[i].minutes));
        expect(result.flow[i].stage, equals(originalPlan.flow[i].stage));
        expect(
            result.flow[i].wholeClass, equals(originalPlan.flow[i].wholeClass));
      }
      for (var i = 0; i < result.flow.length; i++) {
        if (originalPlan.flow[i].wholeClass) continue;
        final newActivity = result.flow[i].activityByGrade['Grade 3'] ?? '';
        expect(newActivity,
            equals(modifiedFlowPlan.flow[i].activityByGrade['Grade 3']));
      }
    });

    test('assessment full section replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.assessment,
        modifiedAssessmentPlan,
      );
      expect(result.assessments.length, equals(2));
      expect(result.assessments[0].formative,
          equals('Modified formative assessment'));
      expect(
          result.assessments[1].formative, equals('Obserbahan ang pangatnig.'));
      expect(result.header.school, equals(originalPlan.header.school));
    });

    test('assessment grade slice replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.assessment,
        modifiedAssessmentPlan,
        gradeLabel: 'Grade 3',
      );
      expect(result.assessments[0].formative,
          equals('Modified formative assessment'));
      expect(result.assessments[1].formative,
          equals(originalPlan.assessments[1].formative));
    });

    test('waysForward full section replacement', () {
      final result = originalPlan.replaceSection(
        PlanSection.waysForward,
        modifiedWaysForwardPlan,
      );
      expect(result.waysForward.length, equals(2));
      expect(result.waysForward[0].remediation, equals('Modified remediation'));
      expect(result.reflectionQuestions.length, equals(3));
      expect(result.header.school, equals(originalPlan.header.school));
    });

    test('waysForward grade slice replacement preserves whole-class questions',
        () {
      final result = originalPlan.replaceSection(
        PlanSection.waysForward,
        modifiedWaysForwardPlan,
        gradeLabel: 'Grade 3',
      );
      expect(result.waysForward[0].gradeLabel, equals('Grade 3'));
      expect(result.waysForward[0].remediation, equals('Modified remediation'));
      final wholeClassQ = result.reflectionQuestions
          .where((q) => q.gradeLabel == null)
          .toList();
      expect(wholeClassQ.length, equals(1));
      expect(wholeClassQ[0].text, equals('Kumusta ang aralin?'));
      final grade3Q = result.reflectionQuestions
          .where((q) => q.gradeLabel == 'Grade 3')
          .toList();
      expect(grade3Q.length, equals(1));
      expect(grade3Q[0].text, equals('Modified reflection for Grade 3'));
    });

    test('unknown grade label throws ArgumentError', () {
      expect(
        () => originalPlan.replaceSection(
          PlanSection.intentions,
          modifiedPlan,
          gradeLabel: 'Grade 99',
        ),
        throwsArgumentError,
      );
    });

    test('flow stage count mismatch throws for learningExperiences grade slice',
        () {
      final planWithDifferentFlow = originalPlan.copyWith(
        flow: [
          FlowStage(
            minutes: 10,
            stage: 'Motivation',
            wholeClass: true,
            activityByGrade: {},
            wholeClassActivity: 'Test',
          ),
        ],
      );
      expect(
        () => originalPlan.replaceSection(
          PlanSection.learningExperiences,
          planWithDifferentFlow,
          gradeLabel: 'Grade 3',
        ),
        throwsArgumentError,
      );
    });

    test('no mutation of original plan', () {
      final originalHeader = originalPlan.header;
      final originalFlow = originalPlan.flow.first;
      originalPlan.replaceSection(
        PlanSection.learningExperiences,
        modifiedFlowPlan,
        gradeLabel: 'Grade 3',
      );
      expect(originalPlan.header, equals(originalHeader));
      expect(originalPlan.flow.first.minutes, equals(originalFlow.minutes));
      expect(originalPlan.flow.first.stage, equals(originalFlow.stage));
    });
  });
}
