// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'flow_table.dart';
import 'plan_sections.dart'; // for PlanChange typedef
import 'header_table.dart' as header;
import 'assessment_tables.dart'; // AssessmentTables, WaysForwardTables
import 'grade_selector.dart';

// Reference ILAW banner colors (from reference DLPs)
const Color _bannerNavy = Color(0xFF1F3864); // Intentions (I)
const Color _bannerGreen = Color(0xFF2E6B2E); // Learning Experiences (L)
const Color _bannerBrown = Color(0xFF8C5A1E); // Assessment (A)
const Color _bannerMaroon = Color(0xFF7A2048); // Ways Forward (W)

// Section banner labels (per reference format)
const String _labelIntentions = 'I  INTENTIONS';
const String _labelLearningExperiences = 'L  LEARNING EXPERIENCE';
const String _labelAssessment = 'A  ASSESSMENT';
const String _labelWaysForward = 'W  WAYS FORWARD';

/// Section banner widget for ILAW section headers (I, L, A, W).
/// Full-width filled bar with reference colors and optional actions.
class SectionBanner extends StatelessWidget {
  const SectionBanner(this.section, {this.actions = const [], super.key});
  final PlanSection section;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final Map<PlanSection, Color> colors = {
      PlanSection.intentions: _bannerNavy,
      PlanSection.learningExperiences: _bannerGreen,
      PlanSection.assessment: _bannerBrown,
      PlanSection.waysForward: _bannerMaroon,
    };
    final color = colors[section] ?? Colors.grey;
    final Map<PlanSection, String> labels = {
      PlanSection.intentions: _labelIntentions,
      PlanSection.learningExperiences: _labelLearningExperiences,
      PlanSection.assessment: _labelAssessment,
      PlanSection.waysForward: _labelWaysForward,
    };

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(children: [
        Expanded(
            child: Text(labels[section] ?? section.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        const Spacer(),
        ...actions,
      ]),
    );
  }
}

class IlawPlanView extends ConsumerWidget {
  const IlawPlanView({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  List<String> get grades => plan.grades.map((g) => g.gradeLabel).toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // null means "All Grades". effectiveGrade also returns null when the
    // stored selection is not a grade of this plan.
    final selectedGrade =
        effectiveGrade(plan, ref.watch(gradeSelectorProvider));
    final bool all = selectedGrade == null;

    final visibleGrades = all ? grades : [selectedGrade];
    final visibleAssessments = plan.assessments
        .where((a) => all || a.gradeLabel == selectedGrade)
        .toList();
    final visibleWaysForward = plan.waysForward
        .where((w) => all || w.gradeLabel == selectedGrade)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradeSelectorChip(plan: plan),
          const SizedBox(height: 8),
          header.HeaderSection(plan: plan, onChange: onChange),
          _banner(context, ref, PlanSection.intentions),
          _intentionsSection(context, selectedGrade),
          _banner(context, ref, PlanSection.learningExperiences),
          LearningExperienceSectionWidget(plan: plan, onChange: onChange),
          FlowTable(
            flow: plan.flow,
            gradeLabels: visibleGrades,
            onChange: onChange,
          ),
          _banner(context, ref, PlanSection.assessment),
          AssessmentTables(assessments: visibleAssessments),
          _banner(context, ref, PlanSection.waysForward),
          WaysForwardTables(waysForward: visibleWaysForward),
          _reflectionSection(selectedGrade),
          _footer(),
        ],
      ),
    );
  }

  /// Section banner with a regenerate button when the plan is editable.
  Widget _banner(BuildContext context, WidgetRef ref, PlanSection section) {
    return SectionBanner(
      section,
      actions: onChange != null
          ? [_buildRegenerateButton(context, ref, section)]
          : const [],
    );
  }

  /// Builds a refresh button for regenerating a section.
  Widget _buildRegenerateButton(
      BuildContext context, WidgetRef ref, PlanSection section) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Regenerate ${section.eventName}',
      onPressed: () => _showRegenerateConfirmation(context, ref, section),
    );
  }

  /// Shows confirmation dialog before regenerating a section.
  void _showRegenerateConfirmation(
      BuildContext context, WidgetRef ref, PlanSection section) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate Section'),
        content:
            const Text('This replaces your edits in this section. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref
                  .read(generationControllerProvider.notifier)
                  .regenerateSection(section);
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  Widget _intentionsSection(BuildContext context, String? selectedGrade) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE);
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    // selectedGrade is already validated by effectiveGrade, so this cannot
    // come back empty for a grade that is not in the plan.
    final filteredGrades = selectedGrade != null
        ? plan.grades.where((g) => g.gradeLabel == selectedGrade).toList()
        : plan.grades;

    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedGrade != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Focus: $selectedGrade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _bannerNavy,
                  ),
                ),
              ),
            Text(plan.sharedSubTheme,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 8),
            Text(plan.bothGradesObjective,
                style: TextStyle(fontSize: 14, color: textColor)),
            const SizedBox(height: 8),
            Text(plan.learnerContext,
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: textColor)),
            const SizedBox(height: 16),
            // Standards & Objectives matrix table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: borderColor),
                columnWidths: {
                  0: const FixedColumnWidth(130),
                  for (int i = 0; i < filteredGrades.length; i++)
                    (i + 1): const FixedColumnWidth(200),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: headerColor),
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Standard / Objective',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      for (final grade in filteredGrades)
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(grade.gradeLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black))),
                    ],
                  ),
                  TableRow(children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Content Standard')),
                    for (final grade in filteredGrades)
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(grade.contentStandard)),
                  ]),
                  TableRow(children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Performance Standard')),
                    for (final grade in filteredGrades)
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(grade.performanceStandard)),
                  ]),
                  TableRow(children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Competencies')),
                    for (final grade in filteredGrades)
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(grade.competencies.join(', '))),
                  ]),
                  TableRow(children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Objectives')),
                    for (final grade in filteredGrades)
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(grade.objectives.join(', '))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reflectionSection(String? selectedGrade) {
    // Whole-class questions (gradeLabel == null) always show.
    final questions = plan.reflectionQuestions
        .where((q) =>
            selectedGrade == null ||
            q.gradeLabel == null ||
            q.gradeLabel == selectedGrade)
        .toList();
    if (questions.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text('Reflection Questions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (final q in questions)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (q.gradeLabel != null)
                  Expanded(
                      flex: 2,
                      child: Text('${q.gradeLabel}:',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(q.text)),
              ],
            )),
    ]);
  }

  Widget _footer() => Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prepared by: ${plan.preparedBy}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('Checked by: ${plan.checkedBy}'),
                  const SizedBox(height: 8),
                  Text(plan.aiUseDeclaration,
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ]);
          }
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Prepared by: ${plan.preparedBy}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('Checked by: ${plan.checkedBy}')
                ]),
                Expanded(
                    child: Text(plan.aiUseDeclaration,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontStyle: FontStyle.italic)))
              ]);
        },
      ));
}
