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
    testWidgets('displays section banners with reference format',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: IlawPlanView(plan: plan))));
      // New label format: uppercase, two spaces between letter and word
      expect(find.text('W  WAYS FORWARD'), findsOneWidget);
      expect(find.text('A  ASSESSMENT'), findsOneWidget);
      expect(find.text('I  INTENTIONS'), findsOneWidget);
      expect(find.text('L  LEARNING EXPERIENCE'), findsOneWidget);
      // Old format should not exist
      expect(find.textContaining('W - Ways Forward'), findsNothing);
      expect(find.textContaining('L - Learning Experiences'), findsNothing);
    });
    testWidgets('section banners have reference colors',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: IlawPlanView(plan: plan))));

      // Verify banners are full-width containers with correct colors
      // The SectionBanner returns a Container with the background color
      final ibannerContainer = tester.widget<Container>(find.ancestor(
          of: find.text('I  INTENTIONS'), matching: find.byType(Container)));
      expect(ibannerContainer.color, equals(const Color(0xFF1F3864))); // navy

      final lbannerContainer = tester.widget<Container>(find.ancestor(
          of: find.text('L  LEARNING EXPERIENCE'),
          matching: find.byType(Container)));
      expect(lbannerContainer.color, equals(const Color(0xFF2E6B2E))); // green

      final abannerContainer = tester.widget<Container>(find.ancestor(
          of: find.text('A  ASSESSMENT'), matching: find.byType(Container)));
      expect(abannerContainer.color, equals(const Color(0xFF8C5A1E))); // brown

      final wbannerContainer = tester.widget<Container>(find.ancestor(
          of: find.text('W  WAYS FORWARD'), matching: find.byType(Container)));
      expect(wbannerContainer.color, equals(const Color(0xFF7A2048))); // maroon
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
