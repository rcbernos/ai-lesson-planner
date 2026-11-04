// Tests for regenerate section functionality in IlawPlanView
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';
import 'package:ai_lesson_planner/core/providers.dart';

import 'fixtures/sample_plan.dart';

void main() {
  group('IlawPlanView regenerate section', () {
    late LessonPlan plan;
    late PlanEditorNotifier editorNotifier;

    setUp(() {
      plan = createSamplePlan();
      editorNotifier = PlanEditorNotifier();
    });

    tearDown(() {
      editorNotifier.clear();
    });

    testWidgets('regenerate section button is shown when onChange is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planEditorProvider.overrideWith((ref) {
              editorNotifier.load(plan);
              return editorNotifier;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: IlawPlanView(
                plan: plan,
                onChange: (updater) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have refresh buttons for each section (I, L, A, W)
      final refreshButtons = find.byIcon(Icons.refresh);
      expect(refreshButtons, findsNWidgets(4));
    });

    testWidgets('regenerate button is not shown when onChange is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: IlawPlanView(
                plan: plan,
                // No onChange - read-only mode
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No refresh buttons should be visible in read-only mode
      final refreshButtons = find.byIcon(Icons.refresh);
      expect(refreshButtons, findsNothing);
    });

    testWidgets('assessment section shows assessments correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            planEditorProvider.overrideWith((ref) {
              editorNotifier.load(plan);
              return editorNotifier;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: IlawPlanView(
                  plan: plan,
                  onChange: (updater) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the assessment section banner
      final assessmentBanner = find.text('A - Assessment');
      expect(assessmentBanner, findsOneWidget);
    });
  });
}
