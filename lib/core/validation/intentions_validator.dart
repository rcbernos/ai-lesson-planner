/// Intentions validation logic for lesson plans.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'validation_issue.dart';

List<ValidationIssue> validateIntentions(LessonPlan plan) {
  final issues = <ValidationIssue>[];
  final grades = plan.grades;

  for (var i = 0; i < grades.length; i++) {
    final g = grades[i];

    if (g.competencies.isEmpty) {
      issues.add(ValidationIssue(
        code: 'intentions.no_competency',
        severity: IssueSeverity.error,
        section: PlanSection.intentions,
        path: 'grades[$i]',
        message: 'Grade ${g.gradeLabel} has no competencies defined.',
      ));
    }

    if (g.objectives.isEmpty) {
      issues.add(ValidationIssue(
        code: 'intentions.no_objective',
        severity: IssueSeverity.warning,
        section: PlanSection.intentions,
        path: 'grades[$i]',
        message: 'Grade ${g.gradeLabel} has no objectives defined.',
      ));
    }
  }

  return issues;
}
