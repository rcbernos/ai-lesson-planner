// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

class FlowTable extends StatelessWidget {
  const FlowTable({required this.flow, required this.gradeLabels, super.key});
  final List<FlowStage> flow;
  final List<String> gradeLabels;

  @override
  Widget build(BuildContext context) {
    // Build header row: Minutes, Stage, then one column per grade
    final headerCells = [
      Padding(padding: const EdgeInsets.all(8), child: Text('Minutes')),
      Padding(padding: const EdgeInsets.all(8), child: Text('Stage')),
      for (final grade in gradeLabels)
        Padding(
            padding: const EdgeInsets.all(8),
            child: Text(grade, style: TextStyle(fontWeight: FontWeight.bold))),
    ];

    // Build columnWidths map - Minutes is fixed, others are flex
    final columnWidths = {
      0: const FixedColumnWidth(50), // Minutes column
      for (int i = 0; i < gradeLabels.length + 1; i++)
        i + 1: const FlexColumnWidth(1), // Stage + grade columns
    };

    // Build data rows
    final rows = <TableRow>[];

    for (final stage in flow) {
      final children = <Widget>[
        Padding(
            padding: const EdgeInsets.all(8), child: Text('${stage.minutes}')),
        Padding(padding: const EdgeInsets.all(8), child: Text(stage.stage)),
      ];

      // Add grade column cells
      if (stage.wholeClass) {
        // Whole class activity - show in all grade columns
        for (int i = 0; i < gradeLabels.length; i++) {
          children.add(Padding(
              padding: const EdgeInsets.all(8),
              child:
                  Text(stage.wholeClassActivity, textAlign: TextAlign.center)));
        }
      } else {
        // Per-grade activities
        for (final grade in gradeLabels) {
          final activity = stage.activityByGrade[grade] ?? '-';
          children.add(Padding(
              padding: const EdgeInsets.all(8),
              child: Text(activity, textAlign: TextAlign.center)));
        }
      }

      rows.add(TableRow(children: children));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: columnWidths,
        border: TableBorder.all(color: Colors.black12, width: 1),
        children: [
          TableRow(
              decoration: const BoxDecoration(color: Colors.grey),
              children: headerCells),
          ...rows,
        ],
      ),
    );
  }
}
