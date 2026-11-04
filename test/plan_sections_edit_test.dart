// Tests for plan_sections.dart editing functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/features/plan_view/plan_sections.dart';
import 'fixtures/sample_plan.dart';

void main() {
  group('plan_sections edit tests', () {
    testWidgets('read-only mode shows no edit hints',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderSection(
              plan: plan,
              onChange: null,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sampaguita Elementary School'));
      await tester.pump();

      expect(find.text('Edit School'), findsNothing);
    });

    testWidgets('AssessmentSection renders without errors',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssessmentSection(
              plan: plan,
              onChange: null,
            ),
          ),
        ),
      );

      expect(find.text('Formative'), findsOneWidget);
      expect(find.text('Exit Task'), findsOneWidget);
    });

    testWidgets('WaysForwardSection renders without errors',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaysForwardSection(
              plan: plan,
              onChange: null,
            ),
          ),
        ),
      );

      expect(find.text('Remediation'), findsOneWidget);
      expect(find.text('Enrichment'), findsOneWidget);
    });

    testWidgets('ReflectionSection renders without errors',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReflectionSection(
              plan: plan,
              onChange: null,
            ),
          ),
        ),
      );

      expect(find.text('Reflection Questions'), findsOneWidget);
    });

    testWidgets('FooterSection renders without errors',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FooterSection(
              plan: plan,
              onChange: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('Prepared by:'), findsOneWidget);
    });

    test('splitLines helper drops blank lines', () {
      expect(splitLines('a\n\nb\n\n\nc'), equals(['a', 'b', 'c']));
      expect(splitLines('single'), equals(['single']));
      expect(splitLines(''), equals([]));
    });

    test('joinLines helper joins with newlines', () {
      expect(joinLines(['a', 'b', 'c']), equals('a\nb\nc'));
    });
  });
}
