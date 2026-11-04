// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'cell_edit_dialog.dart';
import 'package:ai_lesson_planner/features/plan_view/plan_sections.dart';

class FlowTable extends StatelessWidget {
  const FlowTable({
    required this.flow,
    required this.gradeLabels,
    this.onChange,
    super.key,
  });

  final List<FlowStage> flow;
  final List<String> gradeLabels;
  final PlanChange? onChange;

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

    for (int stageIndex = 0; stageIndex < flow.length; stageIndex++) {
      final stage = flow[stageIndex];
      final children = <Widget>[
        _buildCell(
          context,
          '${stage.minutes}',
          onTap: onChange != null
              ? () => _editField(context, 'minutes', stageIndex,
                  '${stage.minutes}', true, stage)
              : null,
          isEditable: onChange != null,
        ),
        _buildCell(
          context,
          stage.stage,
          onTap: onChange != null
              ? () => _editField(
                  context, 'stage', stageIndex, stage.stage, false, stage)
              : null,
          isEditable: onChange != null,
        ),
        _buildCell(
          context,
          stage.wholeClass ? Icons.group_work : Icons.schedule,
          icon: true,
          onTap: null, // Icon column is not tappable
          isEditable: onChange != null,
        ),
      ];

      // Add grade column cells
      for (final grade in gradeLabels) {
        final isWholeClassStage = stage.wholeClass;
        final activity = isWholeClassStage
            ? stage.wholeClassActivity
            : (stage.activityByGrade[grade] ?? '-');
        children.add(_buildCell(
          context,
          activity,
          onTap: onChange != null
              ? () => _editField(
                  context,
                  isWholeClassStage ? 'wholeClass' : 'grade_$grade',
                  stageIndex,
                  activity,
                  false,
                  stage,
                  grade: isWholeClassStage ? null : grade)
              : null,
          isEditable: onChange != null,
        ));
      }

      rows.add(TableRow(children: children));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Table(
          border: TableBorder.all(color: Theme.of(context).dividerColor),
          columnWidths: columnWidths,
          children: [
            TableRow(
                decoration:
                    BoxDecoration(color: Theme.of(context).primaryColorLight),
                children: headerCells),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, dynamic content,
      {VoidCallback? onTap, bool isEditable = false, bool icon = false}) {
    final widget = GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: isEditable ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: isEditable ? Theme.of(context).hoverColor : null,
          child: icon
              ? Icon(content as IconData,
                  color:
                      content == Icons.group_work ? Colors.green : Colors.blue,
                  size: 16)
              : Text(content.toString(), textAlign: TextAlign.center),
        ),
      ),
    );
    return widget;
  }

  void _editField(BuildContext context, String field, int stageIndex,
      String initialValue, bool numeric, FlowStage stage,
      {String? grade}) async {
    String title;
    if (field == 'minutes') {
      title = 'Edit Minutes';
    } else if (field == 'wholeClass') {
      title = 'Edit Whole-Class Activity';
    } else if (field.startsWith('grade_')) {
      title = 'Edit Activity for ${field.replaceFirst('grade_', '')}';
    } else if (field == 'stage') {
      title = 'Edit Stage Name';
    } else {
      title = 'Edit Field';
    }

    final result = await showCellEditDialog(
      context,
      title: title,
      initial: initialValue,
      numeric: numeric,
    );

    if (result == null) return;

    if (onChange == null) return;

    // Handle numeric validation
    if (numeric) {
      final parsed = int.tryParse(result);
      if (parsed == null) return; // Dialog already showed error, just in case
    }

    // Create updated stage
    FlowStage updatedStage;
    if (field == 'minutes') {
      updatedStage = stage.copyWith(minutes: int.parse(result));
    } else if (field == 'stage') {
      updatedStage = stage.copyWith(stage: result);
    } else if (field == 'wholeClass') {
      updatedStage = stage.copyWith(wholeClassActivity: result);
    } else if (field.startsWith('grade_') && grade != null) {
      updatedStage = stage
          .copyWith(activityByGrade: {...stage.activityByGrade, grade: result});
    } else {
      return;
    }

    // Update the flow in the plan
    final newFlow = [
      for (int i = 0; i < flow.length; i++)
        i == stageIndex ? updatedStage : flow[i],
    ];

    onChange!((oldPlan) => oldPlan.copyWith(flow: newFlow));
  }
}
