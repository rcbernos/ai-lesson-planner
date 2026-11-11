import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// Holds the selected grade label. `null` means "All Grades".
class GradeSelectorNotifier extends StateNotifier<String?> {
  GradeSelectorNotifier() : super(null);

  void selectGrade(String gradeLabel) => state = gradeLabel;
  void deselectGrade() => state = null;
}

/// Lives in this file on purpose: nothing in core/providers.dart changes.
final gradeSelectorProvider =
    StateNotifierProvider<GradeSelectorNotifier, String?>(
  (_) => GradeSelectorNotifier(),
);

/// The selection is global, so it can name a grade the current plan does not
/// have (for example after opening another plan). Treat that as "All Grades".
String? effectiveGrade(LessonPlan plan, String? selected) {
  if (selected == null) return null;
  return plan.grades.any((g) => g.gradeLabel == selected) ? selected : null;
}

/// Chip row for focusing the plan view on one grade (narrow screens).
class GradeSelectorChip extends ConsumerWidget {
  const GradeSelectorChip({required this.plan, super.key});

  final LessonPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = effectiveGrade(plan, ref.watch(gradeSelectorProvider));
    final notifier = ref.read(gradeSelectorProvider.notifier);

    // Wrap, not Row: 6 grades overflow a 360 dp screen in a Row.
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: const Text('All Grades'),
          selected: selected == null,
          onSelected: (_) => notifier.deselectGrade(),
        ),
        for (final g in plan.grades)
          ChoiceChip(
            label: Text(g.gradeLabel),
            selected: selected == g.gradeLabel,
            onSelected: (_) => notifier.selectGrade(g.gradeLabel),
          ),
      ],
    );
  }
}