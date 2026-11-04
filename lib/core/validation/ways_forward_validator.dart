/// Ways forward and reflection validation logic for lesson plans.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'validation_issue.dart';

List<ValidationIssue> validateWaysForward(LessonPlan plan) {
  final issues = <ValidationIssue>[];
  final waysForward = plan.waysForward;

  for (final grade in plan.grades) {
    final gradeLabel = grade.gradeLabel;
    GradeWaysForward? wf;
    for (final w in waysForward) {
      if (w.gradeLabel == gradeLabel) {
        wf = w;
        break;
      }
    }

    if (wf == null) {
      issues.add(ValidationIssue(
        code: 'ways_forward.missing_grade',
        severity: IssueSeverity.error,
        section: PlanSection.waysForward,
        path: 'waysForward[$gradeLabel]',
        message: 'No ways forward entry for $gradeLabel.',
      ));
      continue;
    }

    if (wf.remediation.isEmpty) {
      issues.add(ValidationIssue(
        code: 'ways_forward.missing_remediation',
        severity: IssueSeverity.warning,
        section: PlanSection.waysForward,
        path: 'waysForward[$gradeLabel].remediation',
        message: 'Remediation is not defined for $gradeLabel.',
      ));
    }

    if (wf.enrichment.isEmpty) {
      issues.add(ValidationIssue(
        code: 'ways_forward.missing_enrichment',
        severity: IssueSeverity.warning,
        section: PlanSection.waysForward,
        path: 'waysForward[$gradeLabel].enrichment',
        message: 'Enrichment is not defined for $gradeLabel.',
      ));
    }
  }

  return issues;
}

List<ValidationIssue> validateReflection(LessonPlan plan) {
  final issues = <ValidationIssue>[];

  if (plan.reflectionQuestions.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'reflection.empty',
      severity: IssueSeverity.warning,
      section: PlanSection.waysForward,
      path: 'reflectionQuestions',
      message: 'No reflection questions defined.',
    ));
  }

  return issues;
}
