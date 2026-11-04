/// Plan validation with stable issue codes.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'validation_issue.dart';

import 'header_validator.dart';
import 'grades_validator.dart';
import 'intentions_validator.dart';
import 'flow_validator.dart';
import 'assessment_validator.dart';
import 'ways_forward_validator.dart';

/// Validates lesson plans with stable issue codes.
class PlanValidator {
  /// Validates the entire plan and returns all issues found.
  List<ValidationIssue> validate(LessonPlan plan) => [
        ...validateHeader(plan),
        ...validateGrades(plan),
        ...validateIntentions(plan),
        ...validateFlow(plan),
        ...validateAssessment(plan),
        ...validateWaysForward(plan),
        ...validateReflection(plan),
      ];

  /// Returns only the issues that belong to the given section.
  List<ValidationIssue> validateSection(LessonPlan plan, PlanSection section) =>
      validate(plan).where((issue) => issue.section == section).toList();
}
