import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/sample_plan.dart';

void main() {
  group('PlanEditorNotifier', () {
    late PlanEditorNotifier notifier;

    setUp(() {
      notifier = PlanEditorNotifier();
    });

    tearDown(() {
      notifier.clear();
    });

    test('update runs validator and sets dirty', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      expect(notifier.state?.dirty, isFalse);
      expect(notifier.state?.issues, isEmpty);

      // Update with a change
      notifier.update((p) => p.copyWith(sharedSubTheme: 'Updated Theme'));

      expect(notifier.state?.dirty, isTrue);
      expect(notifier.state?.plan.sharedSubTheme, equals('Updated Theme'));
    });

    test('undo restores previous plan', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      // Make a change
      notifier.update((p) => p.copyWith(sharedSubTheme: 'First Change'));

      // Make another change
      notifier.update((p) => p.copyWith(sharedSubTheme: 'Second Change'));

      // Undo should restore the first change
      notifier.undo();
      expect(notifier.state?.plan.sharedSubTheme, equals('First Change'));
      expect(notifier.state?.canUndo, isTrue);

      // Undo again should restore original
      notifier.undo();
      expect(notifier.state?.plan.sharedSubTheme,
          equals('Ulat-panahon at paghahanda sa sakuna'));
    });

    test('history is capped at 20 steps', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      // Make 25 changes - history will cap at 20
      for (var i = 0; i < 25; i++) {
        notifier.update((p) => p.copyWith(sharedSubTheme: 'Change $i'));
      }

      // History has 20 entries, can undo 20 times
      expect(notifier.state?.canUndo, isTrue);

      // Undo once, should have 19 more undo steps
      notifier.undo();
      expect(notifier.state?.canUndo, isTrue);

      // Undo 19 more times - total 20 undos exhausted
      for (var i = 0; i < 19; i++) {
        notifier.undo();
      }
      expect(notifier.state?.canUndo, isFalse);
    });

    test('markSaved clears dirty', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      notifier.update((p) => p.copyWith(sharedSubTheme: 'Changed'));
      expect(notifier.state?.dirty, isTrue);

      notifier.markSaved(42);
      expect(notifier.state?.dirty, isFalse);
      expect(notifier.state?.savedId, equals(42));
    });

    test('load resets history', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      notifier.update((p) => p.copyWith(sharedSubTheme: 'First'));
      notifier.update((p) => p.copyWith(sharedSubTheme: 'Second'));

      // Load a different plan
      final newPlan = plan.copyWith(sharedSubTheme: 'New Plan');
      notifier.load(newPlan, savedId: 10);

      expect(notifier.state?.savedId, equals(10));
      expect(notifier.state?.dirty, isFalse);
      expect(notifier.state?.canUndo, isFalse);
      expect(notifier.state?.plan.sharedSubTheme, equals('New Plan'));
    });

    test('clear resets to null', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      expect(notifier.state, isNotNull);
      notifier.clear();
      expect(notifier.state, isNull);
    });

    test('validation issues are computed on update', () {
      // Create a plan with an invalid session (0 minutes)
      final plan = createSamplePlan().copyWith(
        header: createSamplePlan().header.copyWith(sessionMinutes: 0),
      );
      notifier.load(plan);

      // The plan has an invalid sessionMinutes
      notifier.update((p) => p);
      expect(notifier.state?.issues, isNotEmpty);
      final issues = notifier.state?.issues ?? [];
      final errorCodes = issues.map((i) => i.code).toSet();
      expect(errorCodes, contains('header.required'));
    });

    test('applyRegenerated works like update', () {
      final plan = createSamplePlan();
      notifier.load(plan);

      final regeneratedPlan = plan.copyWith(sharedSubTheme: 'Regenerated');
      notifier.applyRegenerated(regeneratedPlan);

      expect(notifier.state?.dirty, isTrue);
      expect(notifier.state?.canUndo, isTrue);
      expect(notifier.state?.plan.sharedSubTheme, equals('Regenerated'));
    });
  });
}
