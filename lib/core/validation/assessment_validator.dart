/// Assessment validation logic for lesson plans.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'validation_issue.dart';

List<ValidationIssue> validateAssessment(LessonPlan plan) {
  final issues = <ValidationIssue>[];
  final assessments = plan.assessments;

  for (final grade in plan.grades) {
    final gradeLabel = grade.gradeLabel;
    GradeAssessment? assessment;
    for (final a in assessments) {
      if (a.gradeLabel == gradeLabel) {
        assessment = a;
        break;
      }
    }

    if (assessment == null) {
      issues.add(ValidationIssue(
        code: 'assessment.missing_grade',
        severity: IssueSeverity.error,
        section: PlanSection.assessment,
        path: 'assessments[$gradeLabel]',
        message: 'No assessment for $gradeLabel.',
      ));
      continue;
    }

    if (assessment.formative.isEmpty) {
      issues.add(ValidationIssue(
        code: 'assessment.missing_grade',
        severity: IssueSeverity.error,
        section: PlanSection.assessment,
        path: 'assessments[$gradeLabel].formative',
        message: 'Formative assessment is required for $gradeLabel.',
      ));
    }

    if (assessment.exitTask.isEmpty) {
      issues.add(ValidationIssue(
        code: 'assessment.missing_exit_task',
        severity: IssueSeverity.warning,
        section: PlanSection.assessment,
        path: 'assessments[$gradeLabel].exitTask',
        message: 'Exit task is not defined for $gradeLabel.',
      ));
    }

    if (assessment.competencyIndex != null) {
      final compIdx = assessment.competencyIndex!;
      if (compIdx >= grade.competencies.length) {
        issues.add(ValidationIssue(
          code: 'competency.index_out_of_range',
          severity: IssueSeverity.error,
          section: PlanSection.assessment,
          path: 'assessments[$gradeLabel].competencyIndex',
          message:
              'Competency index $compIdx is out of range for $gradeLabel (${grade.competencies.length} competencies).',
        ));
      }
    }
  }

  return issues;
}
