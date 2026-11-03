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
        // Whole class activity spans all grade columns
        final spanCount = gradeLabels.length;
        children
            .addAll(List.generate(spanCount, (_) => const SizedBox.shrink()));
        // We'll use a different approach - add the activity in the first grade cell
        // and let the visual indicator show it's whole class
        if (gradeLabels.isNotEmpty) {
          children[2] = Padding(
              padding: const EdgeInsets.all(8),
              child:
                  Text(stage.wholeClassActivity, textAlign: TextAlign.center));
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
