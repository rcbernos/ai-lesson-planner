// Tests for ValidationPanel widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/features/plan_view/validation_panel.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'fixtures/sample_plan.dart';

void main() {
  group('ValidationPanel', () {
    testWidgets('shows "No problems found" for valid plan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ValidationPanelContent(issues: [])),
        ),
      );

      expect(find.text('No problems found'), findsOneWidget);
    });

    testWidgets('shows existing errors at load without expanding the list', (
      WidgetTester tester,
    ) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        const ProviderScope(
          child: const MaterialApp(
            home: const Scaffold(
              body: const SizedBox(
                width: 800,
                height: 800,
                child: const ValidationPanel(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ValidationPanel)),
      );
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      final editor = container.read(planEditorProvider.notifier);
      editor.load(plan.copyWith(flow: []));
      await tester.pumpAndSettle();

      expect(find.text('1 error'), findsOneWidget);
      expect(find.text('Lesson flow cannot be empty.'), findsNothing);
      editor.update((draft) => draft.copyWith(sharedSubTheme: 'New theme'));
      await tester.pumpAndSettle();

      expect(find.text('1 error'), findsOneWidget);
      await tester.tap(find.text('Review plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learning Experiences'));
      await tester.pumpAndSettle();
      expect(find.text('Lesson flow cannot be empty.'), findsOneWidget);
    });
  });
}
