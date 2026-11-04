/// Header validation logic for lesson plans.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'validation_issue.dart';

List<ValidationIssue> validateHeader(LessonPlan plan) {
  final issues = <ValidationIssue>[];
  final h = plan.header;

  if (h.school.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.school',
      message: 'School name is required.',
    ));
  }

  if (h.teacher.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.teacher',
      message: 'Teacher name is required.',
    ));
  }

  if (h.learningArea.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.learningArea',
      message: 'Learning area is required.',
    ));
  }

  if (h.date.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.date',
      message: 'Date is required.',
    ));
  }

  if (h.term.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.term',
      message: 'Term is required.',
    ));
  }

  if (h.sessions < 1) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.sessions',
      message: 'Number of sessions must be at least 1.',
    ));
  }

  if (h.sessionMinutes <= 0) {
    issues.add(const ValidationIssue(
      code: 'header.required',
      severity: IssueSeverity.error,
      section: PlanSection.header,
      path: 'header.sessionMinutes',
      message: 'Session minutes must be greater than 0.',
    ));
  }

  if (plan.aiUseDeclaration.isEmpty) {
    issues.add(const ValidationIssue(
      code: 'declaration.missing',
      severity: IssueSeverity.warning,
      section: PlanSection.header,
      path: 'aiUseDeclaration',
      message: 'AI use declaration is missing.',
    ));
  }

  return issues;
}
