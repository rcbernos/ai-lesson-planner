/// Flow validation logic for lesson plans.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'validation_issue.dart';

List<ValidationIssue> validateFlow(LessonPlan plan) {
  final issues = <ValidationIssue>[];
  final flow = plan.flow;

  if (flow.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'flow.empty',
      severity: IssueSeverity.error,
      section: PlanSection.learningExperiences,
      path: 'flow',
      message: 'Lesson flow cannot be empty.',
    ));
    return issues;
  }

  for (var i = 0; i < flow.length; i++) {
    final stage = flow[i];

    if (stage.minutes <= 0) {
      issues.add(ValidationIssue(
        code: 'flow.stage_minutes',
        severity: IssueSeverity.error,
        section: PlanSection.learningExperiences,
        path: 'flow[$i]',
        message:
            'Stage "${stage.stage}" has invalid minutes (${stage.minutes}).',
      ));
    }

    if (stage.wholeClass && stage.wholeClassActivity.isEmpty) {
      issues.add(ValidationIssue(
        code: 'flow.missing_whole_class',
        severity: IssueSeverity.error,
        section: PlanSection.learningExperiences,
        path: 'flow[$i].wholeClassActivity',
        message: 'Whole-class activity is required for stage "${stage.stage}".',
      ));
    }

    if (!stage.wholeClass) {
      for (final gradeLabel in plan.grades.map((g) => g.gradeLabel)) {
        final activity = stage.activityByGrade[gradeLabel];
        if (activity == null || activity.isEmpty) {
          issues.add(ValidationIssue(
            code: 'flow.missing_grade_activity',
            severity: IssueSeverity.error,
            section: PlanSection.learningExperiences,
            path: 'flow[$i].activityByGrade[$gradeLabel]',
            message:
                'Activity required for $gradeLabel in stage "${stage.stage}".',
          ));
        }

        final compIdx = stage.competencyIndexByGrade[gradeLabel];
        if (compIdx != null) {
          final gradeIdx =
              plan.grades.indexWhere((g) => g.gradeLabel == gradeLabel);
          if (gradeIdx >= 0 &&
              compIdx >= plan.grades[gradeIdx].competencies.length) {
            issues.add(ValidationIssue(
              code: 'competency.index_out_of_range',
              severity: IssueSeverity.error,
              section: PlanSection.learningExperiences,
              path: 'flow[$i].competencyIndexByGrade[$gradeLabel]',
              message:
                  'Competency index $compIdx is out of range for ${plan.grades[gradeIdx].gradeLabel}.',
            ));
          }
        } else {
          issues.add(ValidationIssue(
            code: 'competency.missing_ref',
            severity: IssueSeverity.warning,
            section: PlanSection.learningExperiences,
            path: 'flow[$i].competencyIndexByGrade[$gradeLabel]',
            message:
                'No competency reference for $gradeLabel in stage "${stage.stage}".',
          ));
        }
      }
    }
  }

  final flowMinutes = flow.fold<int>(0, (sum, s) => sum + s.minutes);
  if (flowMinutes != plan.header.sessionMinutes) {
    issues.add(ValidationIssue(
      code: 'flow.minutes_sum',
      severity: IssueSeverity.error,
      section: PlanSection.learningExperiences,
      path: 'flow',
      message:
          'The lesson flow adds up to $flowMinutes minutes but the session is ${plan.header.sessionMinutes} minutes.',
    ));
  }

  return issues;
}
