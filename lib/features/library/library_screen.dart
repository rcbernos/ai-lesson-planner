/// Library screen for viewing and managing saved lesson plans.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/services/database/plan_repository.dart'
    show SavedPlanInfo;

/// Provider for the list of saved plans.
final savedPlansProvider =
    FutureProvider.autoDispose<List<SavedPlanInfo>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getAllSavedPlans();
});

/// Library screen displaying saved lesson plans.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(savedPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: asyncPlans.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text(
                'No saved plans yet.\nGenerate a plan and save it here.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _PlanListItem(
                plan: plan,
                onDelete: () =>
                    _showDeleteDialog(context, ref, plan.id, plan.title),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading plans: $error'),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    int planId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final repository = ref.read(planRepositoryProvider);
              await repository.deletePlan(planId);
              // Trigger refresh by invalidating the provider
              ref.invalidate(savedPlansProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan deleted')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// A list item displaying plan metadata with navigation to view.
class _PlanListItem extends ConsumerWidget {
  const _PlanListItem({
    required this.plan,
    required this.onDelete,
  });

  final SavedPlanInfo plan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(plan.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Grade: ${plan.gradeLevels} | Subject: ${plan.subject}\nCreated: ${plan.date}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: () {
          _openPlanView(context, ref, plan.id);
        },
      ),
    );
  }

  Future<void> _openPlanView(
      BuildContext context, WidgetRef ref, int planId) async {
    final repository = ref.read(planRepositoryProvider);
    final plan = await repository.getPlanById(planId);
    if (plan == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan not found')),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Saved Plan'),
          ),
          body: IlawPlanView(plan: plan),
        ),
      ),
    );
  }
}
