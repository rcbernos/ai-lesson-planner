// ignore_for_file: prefer_const_constructors

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'package:ai_lesson_planner/core/validation/validation_issue.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/features/plan_view/validation_panel.dart';
import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';

/// Workspace widget that displays an editable lesson plan.
/// Shows Save button, dirty indicator, Undo button, and the plan view.
class PlanWorkspace extends ConsumerWidget {
  const PlanWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planEditorProvider);

    if (state == null) {
      return const Scaffold(
        body: Center(child: Text('No plan loaded')),
      );
    }

    final plan = state.plan;
    final issues = state.issues;
    final errorCount =
        issues.where((i) => i.severity == IssueSeverity.error).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Plan'),
        actions: [
          if (state.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: () => ref.read(planEditorProvider.notifier).undo(),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Plan',
            onPressed: () => _savePlan(context, ref, state, errorCount),
          ),
          if (state.savedId != null)
            IconButton(
              icon: const Icon(Icons.content_copy),
              tooltip: 'Save as Copy',
              onPressed: () => _saveAsCopy(context, ref, state),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ValidationPanel(),
            _buildIndicatorBar(context, state),
            IlawPlanView(
              plan: plan,
              onChange: (updater) =>
                  ref.read(planEditorProvider.notifier).update(updater),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorBar(BuildContext context, PlanEditorState state) {
    if (!state.dirty) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text('Unsaved changes',
                style: TextStyle(
                    color: Colors.amber[700], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _savePlan(BuildContext context, WidgetRef ref, PlanEditorState state,
      int errorCount) {
    final plan = state.plan;
    final savedId = state.savedId;
    final repository = ref.read(planRepositoryProvider);

    if (savedId != null) {
      // Update existing plan
      repository.update(savedId, plan).then((success) {
        if (!context.mounted) return;

        ref.read(planEditorProvider.notifier).markSaved(savedId);

        if (errorCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved with $errorCount errors')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan saved successfully!')),
          );
        }
      }).catchError((error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $error')),
        );
      });
    } else {
      // Insert new plan
      repository.savePlan(plan).then((id) {
        if (!context.mounted) return;

        ref.read(planEditorProvider.notifier).markSaved(id);

        if (errorCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved with $errorCount errors')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan saved successfully!')),
          );
        }
      }).catchError((error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $error')),
        );
      });
    }
  }

  void _saveAsCopy(BuildContext context, WidgetRef ref, PlanEditorState state) {
    final plan = state.plan;
    final repository = ref.read(planRepositoryProvider);

    repository.savePlan(plan).then((id) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copy saved successfully!')),
      );
    }).catchError((error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save as copy failed: $error')),
      );
    });
  }
}
