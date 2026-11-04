import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/validation/plan_validator.dart';
import 'package:ai_lesson_planner/core/validation/validation_issue.dart';
import 'package:test/test.dart';

import 'fixtures/sample_plan.dart';

void main() {
  group('PlanValidator', () {
    late LessonPlan validPlan;
    late PlanValidator validator;

    setUp(() {
      validPlan = createSamplePlan();
      validator = PlanValidator();
    });

    test('valid plan has zero errors', () {
      final issues = validator.validate(validPlan);
      expect(issues.where((i) => i.severity == IssueSeverity.error), isEmpty);
    });

    test('header.required: empty school', () {
      final issues = validator.validate(
          validPlan.copyWith(header: validPlan.header.copyWith(school: '')));
      expect(issues.first.code, 'header.required');
      expect(issues.first.path, 'header.school');
    });
  });
}
