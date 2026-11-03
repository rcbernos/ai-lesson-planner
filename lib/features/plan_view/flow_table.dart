library;
import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
class FlowTable extends StatelessWidget {
  const FlowTable({required this.flow, required this.gradeLabels, super.key});
  final List<FlowStage> flow;
  final List<String> gradeLabels;
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.black12, width: 1),
      children: [
        TableRow(children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Minutes')),
          const Padding(padding: EdgeInsets.all(8), child: Text('Stage')),
        ]),
        ...flow.map((s) => TableRow(children: [
              Padding(padding: const EdgeInsets.all(8), child: Text('${s.minutes}')),
              Padding(padding: const EdgeInsets.all(8), child: Text(s.stage)),
            ])),
      ],
    );
  }
}