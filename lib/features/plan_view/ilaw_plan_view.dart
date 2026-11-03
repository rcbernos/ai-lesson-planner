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
      child: Column(children: [
        _header(), _section('I - Intentions', Colors.orange), _section('L - Learning Experiences', Colors.blue), FlowTable(flow: plan.flow, gradeLabels: grades),
        _section('A - Assessment', Colors.green), _section('W - Ways Forward', Colors.purple),
        _footer(),
      ]),
    );
  }
  Widget _header() => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Row(children: [Expanded(child: Text('School', style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(plan.header.school))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: Text('Teacher', style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(plan.header.teacher))]),
  ])));
  Widget _section(String t, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(Icons.circle, color: c, size: 16), const SizedBox(width: 8), Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c))]));
  Widget _footer() => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Prepared by: ${plan.preparedBy}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Checked by: ${plan.checkedBy}')
            ]),
            Expanded(child: Text(plan.aiUseDeclaration, textAlign: TextAlign.right, style: const TextStyle(fontStyle: FontStyle.italic)))
          ]));
}