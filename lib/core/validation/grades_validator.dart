/// Grades validation logic for lesson plans.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

import 'validation_issue.dart';

/// Minimum number of grades allowed in a multigrade plan.
const int minGrades = 2;

/// Maximum number of grades allowed in a multigrade plan.
const int maxGrades = 6;

List<ValidationIssue> validateGrades(LessonPlan plan) {
  final issues = <ValidationIssue>[];
  final grades = plan.grades;

  if (grades.length < minGrades) {
    issues.add(ValidationIssue(
      code: 'grades.count',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'grades',
      message:
          'Plan must have at least $minGrades grades (found ${grades.length}).',
    ));
  }

  if (grades.length > maxGrades) {
    issues.add(ValidationIssue(
      code: 'grades.count',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'grades',
      message:
          'Plan must have at most $maxGrades grades (found ${grades.length}).',
    ));
  }

  final labels = <String>[];
  for (var i = 0; i < grades.length; i++) {
    final g = grades[i];
    labels.add(g.gradeLabel);

    if (labels.indexOf(g.gradeLabel) !=
        labels.lastIndexWhere((l) => l == g.gradeLabel)) {
      issues.add(ValidationIssue(
        code: 'grades.duplicate_label',
        severity: IssueSeverity.error,
        section: PlanSection.header,
        path: 'grades[$i]',
        message: 'Duplicate grade label: ${g.gradeLabel}.',
      ));
    }

    if (g.learnersMale < 0 || g.learnersFemale < 0) {
      issues.add(ValidationIssue(
        code: 'grades.learners',
        severity: IssueSeverity.error,
        section: PlanSection.header,
        path: 'grades[$i]',
        message: 'Learner counts cannot be negative.',
      ));
    } else if (g.learnersMale + g.learnersFemale == 0) {
      issues.add(ValidationIssue(
        code: 'grades.learners',
        severity: IssueSeverity.warning,
        section: PlanSection.header,
        path: 'grades[$i]',
        message: 'Total learner count is zero.',
      ));
    }
  }

  return issues;
}
