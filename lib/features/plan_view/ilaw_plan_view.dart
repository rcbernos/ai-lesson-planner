// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'flow_table.dart'; // for RegenCallback typedef
import 'plan_sections.dart'; // for PlanChange typedef

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
/// Displays as a full-width filled bar with reference colors.
/// Built in IlawPlanView as per spec, with optional actions for future use.
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
        Text(labels[section] ?? section.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
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
    final isEditable = onChange != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        SectionBanner(
          PlanSection.intentions,
          actions: isEditable
              ? [_buildRegenerateButton(context, ref, PlanSection.intentions)]
              : [],
        ),
        _intentionsSection(context),
        SectionBanner(
          PlanSection.learningExperiences,
          actions: isEditable
              ? [
                  _buildRegenerateButton(
                      context, ref, PlanSection.learningExperiences)
                ]
              : [],
        ),
        FlowTable(
          flow: plan.flow,
          gradeLabels: grades,
          onChange: onChange,
        ),
        SectionBanner(
          PlanSection.assessment,
          actions: isEditable
              ? [_buildRegenerateButton(context, ref, PlanSection.assessment)]
              : [],
        ),
        _assessmentsSection(),
        SectionBanner(
          PlanSection.waysForward,
          actions: isEditable
              ? [_buildRegenerateButton(context, ref, PlanSection.waysForward)]
              : [],
        ),
        _waysForwardSection(),
        _reflectionSection(),
        _footer(),
      ]),
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

  Widget _header() => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Row 1: School and Teacher
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('School',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(plan.header.school),
                  ])),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Teacher',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(plan.header.teacher),
                  ])),
            ]),
            const SizedBox(height: 12),
            // Row 2: Learning Area, Date, Term
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Learning Area',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(plan.header.learningArea),
                  ])),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Date',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(plan.header.date),
                  ])),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Term',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(plan.header.term),
                  ])),
            ]),
            const SizedBox(height: 12),
            // Row 3: Sessions, Session Minutes, Multigrade Model
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Sessions',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${plan.header.sessions}'),
                  ])),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Session Minutes',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${plan.header.sessionMinutes}'),
                  ])),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Multigrade Model',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(plan.header.multigradeModel),
                  ])),
            ]),
          ])));

  Widget _intentionsSection(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final headerColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE);
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Card(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              // Standards & Objectives Matrix Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: borderColor),
                  columnWidths: {
                    0: const FixedColumnWidth(130), // Row label header
                    for (int i = 0; i < plan.grades.length; i++)
                      (i + 1): const FixedColumnWidth(200), // Per-grade columns
                  },
                  children: [
                    // Header row with grade labels
                    TableRow(
                      decoration: BoxDecoration(color: headerColor),
                      children: [
                        const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Standard / Objective',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        for (final grade in plan.grades)
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(grade.gradeLabel,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black))),
                      ],
                    ),
                    // Content Standard Row
                    TableRow(children: [
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Content Standard')),
                      for (final grade in plan.grades)
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(grade.contentStandard)),
                    ]),
                    // Performance Standard Row
                    TableRow(children: [
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Performance Standard')),
                      for (final grade in plan.grades)
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(grade.performanceStandard)),
                    ]),
                    // Competencies Row
                    TableRow(children: [
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Competencies')),
                      for (final grade in plan.grades)
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(grade.competencies.join(', '))),
                    ]),
                    // Objectives Row
                    TableRow(children: [
                      const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Objectives')),
                      for (final grade in plan.grades)
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(grade.objectives.join(', '))),
                    ]),
                  ],
                ),
              ),
            ])));
  }

  Widget _assessmentsSection() {
    if (plan.assessments.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
            columnWidths: const {
              0: FixedColumnWidth(80), // Grade label
              1: FixedColumnWidth(170), // Formative Assessment
              2: FixedColumnWidth(170), // Exit Task
              3: FixedColumnWidth(170), // Success Criteria
            },
            border: TableBorder.all(color: Colors.grey.shade400),
            children: [
              const TableRow(children: [
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Grade',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Formative',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Exit Task',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Success Criteria',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
              ...plan.assessments.map((a) => TableRow(children: [
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(a.gradeLabel)),
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(a.formative)),
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(a.exitTask)),
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(a.successCriteria)),
                  ]))
            ]));
  }

  Widget _waysForwardSection() {
    if (plan.waysForward.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
            columnWidths: const {
              0: FixedColumnWidth(80), // Grade label
              1: FixedColumnWidth(210), // Remediation
              2: FixedColumnWidth(210), // Enrichment
            },
            border: TableBorder.all(color: Colors.grey.shade400),
            children: [
              const TableRow(children: [
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Grade',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Remediation',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Enrichment',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
              ...plan.waysForward.map((w) => TableRow(children: [
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(w.gradeLabel)),
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(w.remediation)),
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(w.enrichment)),
                  ]))
            ]));
  }

  Widget _reflectionSection() {
    if (plan.reflectionQuestions.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text('Reflection Questions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (final q in plan.reflectionQuestions)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              if (q.gradeLabel != null)
                SizedBox(
                    width: 80,
                    child: Text('${q.gradeLabel}:',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text(q.text)),
            ]))
    ]);
  }

  Widget _footer() => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Prepared by: ${plan.preparedBy}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('Checked by: ${plan.checkedBy}')
        ]),
        Expanded(
            child: Text(plan.aiUseDeclaration,
                textAlign: TextAlign.right,
                style: const TextStyle(fontStyle: FontStyle.italic)))
      ]));
}
