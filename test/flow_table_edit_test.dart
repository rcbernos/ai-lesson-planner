// Tests for flow table cell editing functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/features/plan_view/flow_table.dart';
import 'fixtures/sample_plan.dart';

void main() {
  group('FlowTable cell edit', () {
    testWidgets('tapping grade cell and confirming calls onChange',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      String? capturedChange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800, // Ensure table is visible
              child: FlowTable(
                flow: plan.flow,
                gradeLabels: const ['Grade 3', 'Grade 4'],
                onChange: (updater) {
                  final newPlan = updater(plan);
                  capturedChange = newPlan.flow[1].activityByGrade['Grade 3'];
                },
              ),
            ),
          ),
        ),
      );

      // Verify the activity text is findable
      expect(find.text('Basahin at ilarawan ang panahon.'), findsOneWidget);

      // Find the text for Grade 3's Direct Teaching activity
      await tester.tap(find.text('Basahin at ilarawan ang panahon.'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Activity for Grade 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Baguhin ang text.');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(capturedChange, equals('Baguhin ang text.'));
    });

    testWidgets('cancelling dialog changes nothing',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      var callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlowTable(
              flow: plan.flow,
              gradeLabels: const ['Grade 3', 'Grade 4'],
              onChange: (updater) {
                callCount++;
                updater(plan);
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Basahin at ilarawan ang panahon.'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(callCount, equals(0));
    });

    testWidgets('table renders with all expected text',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: FlowTable(
                flow: plan.flow,
                gradeLabels: const ['Grade 3', 'Grade 4'],
                onChange: null,
              ),
            ),
          ),
        ),
      );

      // Check that all key texts are found
      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Stage'), findsOneWidget);
      expect(find.text('Direct Teaching'), findsOneWidget);
      expect(find.text('15'), findsWidgets); // Multiple stages have 15 minutes
      // Grade activities
      expect(find.text('Basahin at ilarawan ang panahon.'), findsOneWidget);
      expect(find.text('Bilugan ang mga pangatnig.'), findsOneWidget);
    });

    testWidgets('editing minutes validates integer input and updates',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      String? savedMinutes;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlowTable(
              flow: plan.flow,
              gradeLabels: const ['Grade 3', 'Grade 4'],
              onChange: (updater) {
                final newPlan = updater(plan);
                savedMinutes = newPlan.flow[1].minutes.toString();
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '25');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(savedMinutes, equals('25'));
    });

    testWidgets('editing stage name updates correctly',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      String? savedStageName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlowTable(
              flow: plan.flow,
              gradeLabels: const ['Grade 3', 'Grade 4'],
              onChange: (updater) {
                final newPlan = updater(plan);
                savedStageName = newPlan.flow[1].stage;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Direct Teaching'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Pamagitan');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(savedStageName, equals('Pamagitan'));
    });
  });
}
