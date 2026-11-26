// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/validation/validation_issue.dart';
import 'package:ai_lesson_planner/core/providers.dart';

class ValidationPanel extends ConsumerWidget {
  const ValidationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planEditorProvider);
    if (state == null) return const SizedBox.shrink();
    return ValidationPanelContent(issues: state.issues);
  }
}

class ValidationPanelContent extends StatelessWidget {
  const ValidationPanelContent({required this.issues, super.key});
  final List<ValidationIssue> issues;

  @override
  Widget build(BuildContext context) {
    final errorCount = issues
        .where((i) => i.severity == IssueSeverity.error)
        .length;
    final warningCount = issues
        .where((i) => i.severity == IssueSeverity.warning)
        .length;
    final colors = Theme.of(context).colorScheme;
    final hasIssues = issues.isNotEmpty;
    final icon = Icon(
      errorCount > 0
          ? Icons.error_outline
          : hasIssues
          ? Icons.warning_amber_rounded
          : Icons.check_circle_outline,
      color: errorCount > 0 ? colors.error : colors.onSurfaceVariant,
    );
    final summary = [
      if (errorCount > 0) '$errorCount ${errorCount == 1 ? 'error' : 'errors'}',
      if (warningCount > 0)
        '$warningCount ${warningCount == 1 ? 'warning' : 'warnings'}',
    ].join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: hasIssues
          ? ExpansionTile(
              leading: icon,
              title: const Text('Review plan'),
              subtitle: Text(summary),
              children: [_buildIssuesList(context)],
            )
          : ListTile(leading: icon, title: const Text('No problems found')),
    );
  }

  Widget _buildIssuesList(BuildContext context) {
    final theme = Theme.of(context);
    if (issues.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group issues by section
    final grouped = <PlanSection, List<ValidationIssue>>{};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.section, () => []).add(issue);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final section = entry.key;
        final sectionIssues = entry.value;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ExpansionTile(
            title: Text(
              section.eventName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: sectionIssues
                .map(
                  (issue) => ListTile(
                    dense: true,
                    leading: Icon(
                      issue.severity == IssueSeverity.error
                          ? Icons.error
                          : Icons.warning,
                      color: issue.severity == IssueSeverity.error
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(issue.message),
                  ),
                )
                .toList(),
          ),
        );
      }).toList(),
    );
  }
}
