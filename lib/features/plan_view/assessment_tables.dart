// ignore_for_file: prefer_const_constructors

library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// Minimum column width for grade columns on narrow screens (dp)
const double kMinGradeColumnWidth = 220.0;

/// Assessment table widget for displaying formative assessments per grade.
/// On narrow screens, wraps in a horizontally scrollable container.
class AssessmentTables extends StatelessWidget {
  const AssessmentTables({
    required this.assessments,
    super.key,
  });

  final List<GradeAssessment> assessments;

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) return const SizedBox.shrink();

    final isNarrow = MediaQuery.of(context).size.width < 600;

    final table = Table(
      columnWidths: {
        0: const FixedColumnWidth(80), // Grade label
        1: const FixedColumnWidth(170), // Formative Assessment
        2: const FixedColumnWidth(170), // Exit Task
        3: FixedColumnWidth(
            isNarrow ? kMinGradeColumnWidth : 170), // Success Criteria
      },
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      children: [
        const TableRow(children: [
          Padding(
              padding: EdgeInsets.all(8),
              child:
                  Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
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
        ...assessments.map((a) => TableRow(children: [
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(a.gradeLabel)),
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(a.formative)),
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(a.exitTask)),
              Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(a.successCriteria)),
            ])),
      ],
    );

    // On narrow screens, wrap in horizontal scroll
    if (isNarrow && assessments.length > 0) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: table,
    );
  }
}

/// Ways Forward table widget for displaying remediation and enrichment per grade.
/// On narrow screens, wraps in a horizontally scrollable container.
class WaysForwardTables extends StatelessWidget {
  const WaysForwardTables({
    required this.waysForward,
    super.key,
  });

  final List<GradeWaysForward> waysForward;

  @override
  Widget build(BuildContext context) {
    if (waysForward.isEmpty) return const SizedBox.shrink();

    final isNarrow = MediaQuery.of(context).size.width < 600;

    final table = Table(
      columnWidths: {
        0: const FixedColumnWidth(80), // Grade label
        1: FixedColumnWidth(
            isNarrow ? kMinGradeColumnWidth : 210), // Remediation
        2: FixedColumnWidth(
            isNarrow ? kMinGradeColumnWidth : 210), // Enrichment
      },
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      children: [
        const TableRow(children: [
          Padding(
              padding: EdgeInsets.all(8),
              child:
                  Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(
              padding: EdgeInsets.all(8),
              child: Text('Remediation',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(
              padding: EdgeInsets.all(8),
              child: Text('Enrichment',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
        ...waysForward.map((w) => TableRow(children: [
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(w.gradeLabel)),
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(w.remediation)),
              Padding(
                  padding: const EdgeInsets.all(8), child: Text(w.enrichment)),
            ])),
      ],
    );

    // On narrow screens, wrap in horizontal scroll
    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: table,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: table,
    );
  }
}
