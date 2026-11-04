import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// Severity level for validation issues.
enum IssueSeverity { error, warning }

/// A validation issue found during plan validation.
class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.severity,
    required this.section,
    required this.path,
    required this.message,
  });

  /// Stable identifier for this issue type.
  final String code;

  /// Whether this issue blocks critical operations.
  final IssueSeverity severity;

  /// The plan section this issue belongs to.
  final PlanSection section;

  /// Path to the specific element in the plan.
  /// E.g., 'grades[0]', 'flow[2].activityByGrade[Grade 3]'.
  final String path;

  /// Plain English description, safe to paste into an LLM retry prompt.
  final String message;

  @override
  String toString() => '$code ($severity): $message';
}
