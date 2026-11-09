// ignore_for_file: prefer_const_constructors

library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'cell_edit_dialog.dart';
import 'plan_sections.dart'; // for PlanChange typedef

/// Converts Arabic numeral to Roman numeral (supports 1-10).
String _toRoman(int n) {
  const numerals = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X'
  ];
  return n >= 1 && n <= 10 ? numerals[n - 1] : '$n';
}

/// Formats learner count string for grades, e.g., "Gr.3: 6 │ Gr.4: 1 (M-3, F-3)".
String _formatLearnerCounts(List<GradeBlock> grades) {
  final parts = <String>[];
  for (final grade in grades) {
    final label = grade.gradeLabel.replaceAll('Grade ', 'Gr.');
    final total = grade.learnersMale + grade.learnersFemale;
    final mfPart = '(M-${grade.learnersMale}, F-${grade.learnersFemale})';
    parts.add('$label: $total $mfPart');
  }
  return parts.join(' │ ');
}

/// Header section with 4-column table layout per ILAW reference format.
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.plan, this.onChange});
  final LessonPlan plan;
  final PlanChange? onChange;

  static const Color _navy = Color(0xFF1F3864);

  @override
  Widget build(BuildContext context) {
    final isEditable = onChange != null;
    final gradeLevelsDisplay = plan.header.gradeLevels.isNotEmpty
        ? plan.header.gradeLevels
        : _toRoman(plan.grades.length);
    final sessions = plan.header.sessions;
    final sessionWord = sessions == 1 ? 'session' : 'sessions';
    final sessionString =
        '$sessions $sessionWord, ${plan.header.sessionMinutes} minutes';
    final learnerCountStr = _formatLearnerCounts(plan.grades);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'DAILY LESSON PLAN FOR GRADE $gradeLevelsDisplay',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(120), // Label column
                1: FlexColumnWidth(), // Value column 1
                2: FixedColumnWidth(120), // Label column
                3: FlexColumnWidth(), // Value column 2
              },
              children: [
                _buildSchoolRow(context, isEditable, gradeLevelsDisplay),
                _buildTeacherRow(context, isEditable),
                _buildDateRow(context, isEditable),
                _buildTimeLearnerRow(sessionString, learnerCountStr),
                _buildMultigradeRow(context, isEditable),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildSchoolRow(
      BuildContext context, bool isEditable, String gradeLevels) {
    return TableRow(children: [
      _labelCell('School'),
      _editableCell(context, 'School', plan.header.school, isEditable),
      _labelCell('Grade Levels'),
      _editableCell(context, 'Grade Levels', gradeLevels, isEditable),
    ]);
  }

  TableRow _buildTeacherRow(BuildContext context, bool isEditable) {
    return TableRow(children: [
      _labelCell('Teacher'),
      _editableCell(context, 'Teacher', plan.header.teacher, isEditable),
      _labelCell('Learning Area'),
      _editableCell(
          context, 'Learning Area', plan.header.learningArea, isEditable),
    ]);
  }

  TableRow _buildDateRow(BuildContext context, bool isEditable) {
    return TableRow(children: [
      _labelCell('Teaching Date'),
      _editableCell(context, 'Date', plan.header.date, isEditable),
      _labelCell('Quarter/Term'),
      _editableCell(context, 'Term', plan.header.term, isEditable),
    ]);
  }

  TableRow _buildTimeLearnerRow(String sessionString, String learnerCountStr) {
    return TableRow(children: [
      _labelCell('Time / Sessions'),
      _valueCell(sessionString),
      _labelCell('No. of Learners'),
      _valueCell(learnerCountStr),
    ]);
  }

  TableRow _buildMultigradeRow(BuildContext context, bool isEditable) {
    // Row 5: Multigrade Model label in col 0, value spanning cols 1-3
    return TableRow(children: [
      _labelCell('Multigrade Model'),
      _editableCell(
          context, 'Multigrade Model', plan.header.multigradeModel, isEditable),
      const SizedBox.shrink(), // placeholder for col 2
      const SizedBox.shrink(), // placeholder for col 3
    ]);
  }

  Widget _labelCell(String label) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _navy)),
    );
  }

  Widget _editableCell(
      BuildContext context, String label, String value, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: isEditable
            ? () async {
                final result = await showCellEditDialog(context,
                    title: 'Edit $label', initial: value);
                if (result != null && onChange != null) {
                  _applyHeaderChange(label, result);
                }
              }
            : null,
        child: MouseRegion(
          cursor: isEditable ? SystemMouseCursors.click : MouseCursor.defer,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: isEditable ? Theme.of(context).hoverColor : null),
            child: Text(value),
          ),
        ),
      ),
    );
  }

  void _applyHeaderChange(String field, String value) {
    final newHeader = switch (field) {
      'School' => plan.header.copyWith(school: value),
      'Grade Levels' => plan.header.copyWith(gradeLevels: value),
      'Teacher' => plan.header.copyWith(teacher: value),
      'Learning Area' => plan.header.copyWith(learningArea: value),
      'Date' => plan.header.copyWith(date: value),
      'Term' => plan.header.copyWith(term: value),
      'Multigrade Model' => plan.header.copyWith(multigradeModel: value),
      _ => plan.header,
    };
    onChange!((p) => p.copyWith(header: newHeader));
  }

  Widget _valueCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(value),
    );
  }
}
