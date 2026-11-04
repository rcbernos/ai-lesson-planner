// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'plan_sections.dart'; // for PlanChange typedef

/// Assessment section showing formative assessments, exit tasks, and success criteria.
class AssessmentSection extends StatelessWidget {
  const AssessmentSection({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.all(8), child: Text(a.formative)),
                Padding(
                    padding: const EdgeInsets.all(8), child: Text(a.exitTask)),
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(a.successCriteria)),
              ]))
        ],
      ),
    );
  }
}

/// Ways Forward section showing remediation and enrichment for each grade.
class WaysForwardSection extends StatelessWidget {
  const WaysForwardSection({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

/// Reflection section showing grade-specific and whole-class reflection questions.
class ReflectionSection extends StatelessWidget {
  const ReflectionSection({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
    if (plan.reflectionQuestions.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Text('Reflection Questions',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            ])),
    ]);
  }
}

/// Footer section showing who prepared and checked the plan, and AI use declaration.
class FooterSection extends StatelessWidget {
  const FooterSection({required this.plan, this.onChange, super.key});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Prepared by: ${plan.preparedBy}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('Checked by: ${plan.checkedBy}'),
        ]),
        Expanded(
            child: Text(plan.aiUseDeclaration,
                textAlign: TextAlign.right,
                style: const TextStyle(fontStyle: FontStyle.italic))),
      ]));
}
