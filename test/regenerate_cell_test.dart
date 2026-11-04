// Tests for regenerate cell functionality
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/features/plan_view/flow_table.dart';
import 'package:ai_lesson_planner/features/plan_view/plan_sections.dart';
import 'fixtures/sample_plan.dart' as fixtures;

void main() {
  group('FlowTable regenerate cell', () {
    testWidgets('refresh button shown when onRegenerate provided',
        (WidgetTester tester) async {
      final plan = fixtures.createSamplePlan();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 300,
              child: FlowTable(
                flow: plan.flow,
                gradeLabels: const ['Grade 3', 'Grade 4'],
                onChange: null,
                onRegenerate: (section, gradeLabel) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 2 header buttons + (6 stages * 2 grades) = 14 total refresh icons
      final refreshButtons = find.byIcon(Icons.refresh);
      expect(refreshButtons, findsNWidgets(14));
    });

    testWidgets('tapping refresh button calls callback with gradeLabel',
        (WidgetTester tester) async {
      final plan = fixtures.createSamplePlan();
      String? capturedGrade;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 300,
              child: FlowTable(
                flow: plan.flow,
                gradeLabels: const ['Grade 3', 'Grade 4'],
                onChange: null,
                onRegenerate: (section, gradeLabel) {
                  capturedGrade = gradeLabel;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final refreshButtons = find.byIcon(Icons.refresh);

      // Tap the first refresh button (should be a header button)
      await tester.tap(refreshButtons.first);
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Regenerate Cell'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(capturedGrade, isNull);
    });
  });

  group('AssessmentSection regenerate cell', () {
    testWidgets('refresh buttons render for each grade',
        (WidgetTester tester) async {
      final plan = fixtures.createSamplePlan();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssessmentSection(
              plan: plan,
              onChange: null,
              onRegenerate: (section, gradeLabel) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final refreshButtons = find.byIcon(Icons.refresh);
      expect(refreshButtons, findsNWidgets(2));
    });
  });

  group('WaysForwardSection regenerate cell', () {
    testWidgets('refresh buttons render for each grade',
        (WidgetTester tester) async {
      final plan = fixtures.createSamplePlan();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaysForwardSection(
              plan: plan,
              onChange: null,
              onRegenerate: (section, gradeLabel) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final refreshButtons = find.byIcon(Icons.refresh);
      expect(refreshButtons, findsNWidgets(2));
    });
  });
}
