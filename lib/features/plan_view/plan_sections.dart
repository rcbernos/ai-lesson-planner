library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// Type alias for plan change callbacks.
typedef PlanChange = void Function(LessonPlan Function(LessonPlan));

/// Header section showing school, teacher, learning area, date, term, sessions, and multigrade model.
class HeaderSection extends StatelessWidget {
  const HeaderSection({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement header widget
    return const SizedBox.shrink();
  }
}

/// Intentions section widget.
class IntentionsSectionWidget extends StatelessWidget {
  const IntentionsSectionWidget({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement intentions widget
    return const SizedBox.shrink();
  }
}
