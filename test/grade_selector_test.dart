import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/features/plan_view/grade_selector.dart';
// Fixture path assumes the test sits in test/ (same level as fixtures/).
import 'fixtures/sample_plan.dart';
// GradeBlock and PlanHeader are `part` files of lesson_plan.dart, so they
// cannot be imported on their own. Importing lesson_plan.dart is enough.

/// Only the grade labels matter to the chip, so reuse the fixture and swap
/// its grades.
LessonPlan createMockPlan(List<String> labels) =>
    createSamplePlan().copyWith(grades: [
      for (final l in labels)
        GradeBlock(
          gradeLabel: l,
          learnersMale: 1,
          learnersFemale: 1,
          subTheme: '',
          contentStandard: '',
          performanceStandard: '',
          competencies: const [],
          objectives: const [],
        ),
    ]);

Widget _host(LessonPlan plan, ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: GradeSelectorChip(plan: plan)),
      ),
    );

// find.text() returns the Text widget, not the ChoiceChip around it.
Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);
bool _isSelected(WidgetTester t, String label) =>
    t.widget<ChoiceChip>(_chip(label)).selected;

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  testWidgets('starts with All Grades selected', (tester) async {
    final plan = createMockPlan(['Grade 3', 'Grade 4']);
    await tester.pumpWidget(_host(plan, container));

    expect(_isSelected(tester, 'All Grades'), isTrue);
    expect(_isSelected(tester, 'Grade 3'), isFalse);
    expect(_isSelected(tester, 'Grade 4'), isFalse);
  });

  testWidgets('tapping a grade selects it and updates the provider',
      (tester) async {
    final plan = createMockPlan(['Grade 3', 'Grade 4']);
    await tester.pumpWidget(_host(plan, container));

    await tester.tap(_chip('Grade 4'));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'Grade 4'), isTrue);
    expect(_isSelected(tester, 'All Grades'), isFalse);
    expect(container.read(gradeSelectorProvider), 'Grade 4');
  });

  testWidgets('tapping All Grades clears the selection', (tester) async {
    final plan = createMockPlan(['Grade 3', 'Grade 4']);
    await tester.pumpWidget(_host(plan, container));

    await tester.tap(_chip('Grade 3'));
    await tester.pumpAndSettle();
    await tester.tap(_chip('All Grades'));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'All Grades'), isTrue);
    expect(container.read(gradeSelectorProvider), isNull);
  });

  testWidgets('a grade that is not in the plan counts as All Grades',
      (tester) async {
    final plan = createMockPlan(['Grade 3', 'Grade 4']);
    container.read(gradeSelectorProvider.notifier).selectGrade('Grade 9');
    await tester.pumpWidget(_host(plan, container));

    expect(_isSelected(tester, 'All Grades'), isTrue);
    expect(effectiveGrade(plan, 'Grade 9'), isNull);
  });

  testWidgets('6 grades fit on a 360 dp wide screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final plan = createMockPlan(
        ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6']);
    await tester.pumpWidget(_host(plan, container));

    expect(tester.takeException(), isNull);
    expect(find.byType(ChoiceChip), findsNWidgets(7));
  });
}