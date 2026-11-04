// Tests for ValidationPanel widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/features/plan_view/validation_panel.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'fixtures/sample_plan.dart';

void main() {
  group('ValidationPanel', () {
    testWidgets('shows "No problems found" for valid plan',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: ValidationPanel(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
          tester.element(find.byType(ValidationPanel)));
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      expect(find.text('No problems found'), findsOneWidget);
    });

    testWidgets('shows error summary when issues exist',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: ValidationPanel(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
          tester.element(find.byType(ValidationPanel)));
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      // Initially no errors
      expect(find.text('No problems found'), findsOneWidget);

      // Break the flow minutes
      container.read(planEditorProvider.notifier).update((p) => p.copyWith(
            flow: p.flow.map((s) => s.copyWith(minutes: 0)).toList(),
          ));
      await tester.pumpAndSettle();

      // Should show error count in title
      expect(find.textContaining('error'), findsWidgets);
    });
  });
}
