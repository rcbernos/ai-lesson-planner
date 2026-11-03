// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'flow_table.dart';

class IlawPlanView extends StatelessWidget {
  const IlawPlanView({required this.plan, super.key});
  final LessonPlan plan;
  List<String> get grades => plan.grades.map((g) => g.gradeLabel).toList();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(),
        _section('I - Intentions', Colors.orange),
        _intentionsSection(),
        _section('L - Learning Experiences', Colors.blue),
        FlowTable(flow: plan.flow, gradeLabels: grades),
        _section('A - Assessment', Colors.green),
        _assessmentsSection(),
        _section('W - Ways Forward', Colors.purple),
        _waysForwardSection(),
        _reflectionSection(),
        _footer(),
      ]),
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
  Widget _section(String t, Color c) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(Icons.circle, color: c, size: 16),
        const SizedBox(width: 8),
        Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c))
      ]));
  Widget _intentionsSection() {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.sharedSubTheme,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(plan.bothGradesObjective,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(plan.learnerContext,
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              // Standards & Objectives Matrix Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade400),
                  columnWidths: {
                    0: const FixedColumnWidth(130), // Row label header
                    for (int i = 0; i < plan.grades.length; i++)
                      (i + 1): const FixedColumnWidth(200), // Per-grade columns
                  },
                  children: [
                    // Header row with grade labels
                    TableRow(
                      decoration: BoxDecoration(color: const Color(0xFFEEEEEE)),
                      children: [
                        const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Standard / Objective',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        for (final grade in plan.grades)
                          Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(grade.gradeLabel,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
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
