// Tests for PlanWorkspace widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/features/plan_view/plan_workspace.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'fixtures/sample_plan.dart';

void main() {
  group('PlanWorkspace', () {
    testWidgets('renders when no plan is loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: PlanWorkspace()),
          ),
        ),
      );

      expect(find.text('No plan loaded'), findsOneWidget);
    });

    testWidgets('displays plan and dirty chip after edit',
        (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: PlanWorkspace(),
              ),
            ),
          ),
        ),
      );

      // Load the plan
      await tester.pumpAndSettle();
      final container =
          ProviderScope.containerOf(tester.element(find.byType(PlanWorkspace)));
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      // Verify header is displayed
      expect(find.text('School'), findsOneWidget);

      // No dirty chip initially
      expect(find.text('Unsaved changes'), findsNothing);

      // Simulate an edit through the editor state
      container.read(planEditorProvider.notifier).update(
            (p) => p.copyWith(sharedSubTheme: 'Updated Theme'),
          );
      await tester.pumpAndSettle();

      // Dirty chip should appear
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('Undo button appears after edit', (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: PlanWorkspace(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final container =
          ProviderScope.containerOf(tester.element(find.byType(PlanWorkspace)));
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      // Undo button not visible initially
      expect(find.byIcon(Icons.undo), findsNothing);

      // Make an edit
      container.read(planEditorProvider.notifier).update(
            (p) => p.copyWith(sharedSubTheme: 'First Change'),
          );
      await tester.pumpAndSettle();

      // Undo button should appear after one edit (canUndo = true)
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('Undo restores previous plan', (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: PlanWorkspace(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final container =
          ProviderScope.containerOf(tester.element(find.byType(PlanWorkspace)));
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      final state = container.read(planEditorProvider);
      final originalTheme = state!.plan.sharedSubTheme;

      // Make edits
      container.read(planEditorProvider.notifier).update(
            (p) => p.copyWith(sharedSubTheme: 'First Change'),
          );
      container.read(planEditorProvider.notifier).update(
            (p) => p.copyWith(sharedSubTheme: 'Second Change'),
          );
      await tester.pumpAndSettle();

      // Verify second edit
      expect(container.read(planEditorProvider)!.plan.sharedSubTheme,
          equals('Second Change'));

      // Undo
      container.read(planEditorProvider.notifier).undo();
      await tester.pumpAndSettle();

      // Should be back to first change
      expect(container.read(planEditorProvider)!.plan.sharedSubTheme,
          equals('First Change'));

      // Undo again
      container.read(planEditorProvider.notifier).undo();
      await tester.pumpAndSettle();

      // Should be back to original
      expect(container.read(planEditorProvider)!.plan.sharedSubTheme,
          equals(originalTheme));
    });

    testWidgets('Save clears dirty flag', (WidgetTester tester) async {
      final plan = createSamplePlan();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 800,
                child: PlanWorkspace(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final container =
          ProviderScope.containerOf(tester.element(find.byType(PlanWorkspace)));
      container.read(planEditorProvider.notifier).load(plan);
      await tester.pumpAndSettle();

      // Make an edit
      container.read(planEditorProvider.notifier).update(
            (p) => p.copyWith(sharedSubTheme: 'Updated'),
          );
      await tester.pumpAndSettle();

      expect(container.read(planEditorProvider)!.dirty, isTrue);

      // Mark as saved (simulates successful save)
      container.read(planEditorProvider.notifier).markSaved(1);
      await tester.pumpAndSettle();

      expect(container.read(planEditorProvider)!.dirty, isFalse);
      expect(container.read(planEditorProvider)!.savedId, equals(1));
    });
  });
}
