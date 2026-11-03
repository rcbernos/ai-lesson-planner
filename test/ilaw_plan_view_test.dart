library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures/sample_plan.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';

void main() {
  group('IlawPlanView widget', () {
    testWidgets('renders without overflow errors', (WidgetTester tester) async {
      final plan = createSamplePlan();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: IlawPlanView(plan: plan))));
      expect(find.byType(IlawPlanView), findsOneWidget);
    });
    testWidgets('displays section banners', (WidgetTester tester) async {
      final plan = createSamplePlan();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: IlawPlanView(plan: plan))));
      expect(find.textContaining('W - Ways Forward'), findsOneWidget);
      expect(find.textContaining('A - Assessment'), findsOneWidget);
      expect(find.textContaining('I - Intentions'), findsOneWidget);
      expect(find.textContaining('L - Learning Experiences'), findsOneWidget);
    });
    test('plan fixture has correct structure', () {
      final plan = createSamplePlan();
      expect(plan.grades.length, equals(2));
      expect(plan.flow.length, greaterThan(0));
      expect(plan.waysForward.length, equals(2));
      expect(plan.assessments.length, equals(2));
      expect(plan.reflectionQuestions.length, greaterThan(0));
    });
    test('header fields are correct', () {
      final plan = createSamplePlan();
      expect(plan.header.school, equals('Sampaguita Elementary School'));
      expect(plan.header.teacher, equals('Maria Santos'));
      expect(plan.header.sessionMinutes, equals(90));
    });
  });
}
