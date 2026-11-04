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
    final errorCount =
        issues.where((i) => i.severity == IssueSeverity.error).length;
    final warningCount =
        issues.where((i) => i.severity == IssueSeverity.warning).length;
    final hasIssues = errorCount > 0 || warningCount > 0;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                hasIssues ? Icons.error : Icons.check_circle,
                color: hasIssues
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                hasIssues
                    ? '$errorCount error(s), $warningCount warning(s)'
                    : 'No problems found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasIssues
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            _buildIssuesList(context),
          ],
        ),
      ),
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
            initiallyExpanded: true,
            title: Text(section.eventName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            children: sectionIssues
                .map((issue) => ListTile(
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
                      subtitle: Text(_humanPath(issue.path),
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12)),
                    ))
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  String _humanPath(String path) => path;
}
