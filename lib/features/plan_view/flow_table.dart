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
    // Build explicit fixed widths for every column
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(55), // Minutes column
      1: const FixedColumnWidth(110), // Stage name column
      2: const FixedColumnWidth(80), // Whole-class indicator column
      // Give each grade column a guaranteed minimum width (e.g., 180px)
      for (int i = 0; i < gradeLabels.length; i++)
        (i + 3): const FixedColumnWidth(180),
    };

    // Calculate total width for the SizedBox wrapper
    final totalWidth = 55.0 + 110.0 + 80.0 + (gradeLabels.length * 180.0);

    // Build header row: Minutes, Stage, Whole-class, then one column per grade
    final headerCells = [
      const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Min', style: TextStyle(fontWeight: FontWeight.bold))),
      const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Stage', style: TextStyle(fontWeight: FontWeight.bold))),
      const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Whole Class',
              style: TextStyle(fontWeight: FontWeight.bold))),
      for (final label in gradeLabels)
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
    ];

    // Build data rows
    final rows = <TableRow>[];

    for (final stage in flow) {
      final children = <Widget>[
        Padding(
            padding: const EdgeInsets.all(8), child: Text('${stage.minutes}')),
        Padding(padding: const EdgeInsets.all(8), child: Text(stage.stage)),
        Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              stage.wholeClass ? Icons.group_work : Icons.schedule,
              color: stage.wholeClass ? Colors.green : Colors.blue,
              size: 16,
            )),
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
      child: SizedBox(
        // Ensure the table has enough total width to fit all columns comfortably
        width: totalWidth,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade400),
          columnWidths: columnWidths,
          children: [
            // Table Header Row
            TableRow(
                decoration: BoxDecoration(color: Colors.grey),
                children: headerCells),
            // Flow Stage Rows
            ...rows,
          ],
        ),
      ),
    );
  }
}
