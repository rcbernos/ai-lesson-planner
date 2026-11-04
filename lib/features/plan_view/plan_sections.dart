// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter/material.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'cell_edit_dialog.dart';

/// Type alias for plan change callbacks.
typedef PlanChange = void Function(LessonPlan Function(LessonPlan));

/// Callback type for regenerating a section's grade slice.
typedef RegenCallback = void Function(PlanSection section, String gradeLabel);

/// Helper to split multi-line text into list items, dropping blank lines.
List<String> splitLines(String text) =>
    text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

/// Helper to join list items with newlines.
String joinLines(List<String> items) => items.join('\n');

/// Header section with editable fields for school, teacher, dates, sessions, etc.
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.plan, this.onChange});
  final LessonPlan plan;
  final PlanChange? onChange;

  void _updateHeader(String field, String value) {
    if (onChange == null) return;
    final newHeader = _applyHeaderChange(plan.header, field, value);
    onChange!((p) => p.copyWith(header: newHeader));
  }

  PlanHeader _applyHeaderChange(PlanHeader h, String field, String value) {
    switch (field) {
      case 'school':
        return h.copyWith(school: value);
      case 'teacher':
        return h.copyWith(teacher: value);
      case 'learningArea':
        return h.copyWith(learningArea: value);
      case 'date':
        return h.copyWith(date: value);
      case 'term':
        return h.copyWith(term: value);
      case 'sessions':
        return h.copyWith(sessions: int.tryParse(value) ?? h.sessions);
      case 'sessionMinutes':
        return h.copyWith(
            sessionMinutes: int.tryParse(value) ?? h.sessionMinutes);
      case 'multigradeModel':
        return h.copyWith(multigradeModel: value);
      default:
        return h;
    }
  }

  Widget _editableField(
      BuildContext context, String label, String value, bool canEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: canEdit
              ? () async {
                  final r = await showCellEditDialog(context,
                      title: 'Edit $label', initial: value);
                  if (r != null) _updateHeader(label, r);
                }
              : null,
          child: MouseRegion(
            cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: canEdit ? Theme.of(context).hoverColor : null,
              child: Text(value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _numericField(
      BuildContext context, String label, String value, bool canEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: canEdit
              ? () async {
                  final r = await showCellEditDialog(context,
                      title: 'Edit $label', initial: value, numeric: true);
                  if (r != null) _updateHeader(label, r);
                }
              : null,
          child: MouseRegion(
            cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: canEdit ? Theme.of(context).hoverColor : null,
              child: Text(value),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = onChange != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: _editableField(
                    context, 'school', plan.header.school, canEdit)),
            Expanded(
                child: _editableField(
                    context, 'teacher', plan.header.teacher, canEdit)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _editableField(context, 'learningArea',
                    plan.header.learningArea, canEdit)),
            Expanded(
                child:
                    _editableField(context, 'date', plan.header.date, canEdit)),
            Expanded(
                child:
                    _editableField(context, 'term', plan.header.term, canEdit)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _numericField(
                    context, 'sessions', '${plan.header.sessions}', canEdit)),
            Expanded(
                child: _numericField(context, 'sessionMinutes',
                    '${plan.header.sessionMinutes}', canEdit)),
            Expanded(
                child: _editableField(context, 'multigradeModel',
                    plan.header.multigradeModel, canEdit)),
          ]),
        ]),
      ),
    );
  }
}

/// Intentions section with editable objectives, learner context.
class IntentionsSectionWidget extends StatelessWidget {
  const IntentionsSectionWidget({super.key, required this.plan, this.onChange});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
    final canEdit = onChange != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(plan.sharedSubTheme,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _editField(context, 'Both Grades Objective', plan.bothGradesObjective,
              canEdit),
          const SizedBox(height: 8),
          _editField(context, 'Learner Context', plan.learnerContext, canEdit),
          const SizedBox(height: 16),
          _objectivesTable(context, canEdit),
        ]),
      ),
    );
  }

  Widget _editField(
      BuildContext context, String label, String value, bool canEdit) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      GestureDetector(
        onTap: canEdit
            ? () async {
                final r = await showCellEditDialog(context,
                    title: 'Edit $label', initial: value);
                if (r != null && onChange != null) {
                  switch (label) {
                    case 'Both Grades Objective':
                      onChange!((p) => p.copyWith(bothGradesObjective: r));
                      break;
                    case 'Learner Context':
                      onChange!((p) => p.copyWith(learnerContext: r));
                      break;
                  }
                }
              }
            : null,
        child: MouseRegion(
          cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: canEdit ? Theme.of(context).hoverColor : null,
            child: Text(value,
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        ),
      ),
    ]);
  }

  Widget _objectivesTable(BuildContext context, bool canEdit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
        columnWidths: {
          0: const FixedColumnWidth(130),
          for (int i = 0; i < plan.grades.length; i++)
            (i + 1): const FixedColumnWidth(200),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
            children: [
              const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Standard / Objective',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              for (final g in plan.grades)
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(g.gradeLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          _tableRow('Content Standard',
              plan.grades.map((g) => g.contentStandard).toList()),
          _tableRow('Performance Standard',
              plan.grades.map((g) => g.performanceStandard).toList()),
          _tableRow('Competencies',
              plan.grades.map((g) => g.competencies.join(', ')).toList()),
          _editableObjectivesRow(context, canEdit),
        ],
      ),
    );
  }

  TableRow _tableRow(String label, List<String> values) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text(label)),
      for (final v in values)
        Padding(padding: const EdgeInsets.all(8), child: Text(v)),
    ]);
  }

  TableRow _editableObjectivesRow(BuildContext context, bool canEdit) {
    return TableRow(children: [
      const Padding(padding: EdgeInsets.all(8), child: Text('Objectives')),
      for (int i = 0; i < plan.grades.length; i++)
        GestureDetector(
          onTap: canEdit
              ? () async {
                  final text = await showCellEditDialog(
                    context,
                    title: 'Edit Objectives',
                    initial: joinLines(plan.grades[i].objectives),
                    maxLines: 10,
                  );
                  if (text == null) return;
                  final newObj = splitLines(text);
                  final newGrade = plan.grades[i].copyWith(objectives: newObj);
                  if (onChange != null) {
                    onChange!((p) => p.copyWith(grades: [
                          for (int j = 0; j < p.grades.length; j++)
                            if (j == i) newGrade else p.grades[j],
                        ]));
                  }
                }
              : null,
          child: MouseRegion(
            cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: canEdit ? Theme.of(context).hoverColor : null,
              child: Text(plan.grades[i].objectives.join(', ')),
            ),
          ),
        ),
    ]);
  }
}

/// Assignment section with editable assessment fields.
class AssessmentSection extends StatelessWidget {
  const AssessmentSection({
    super.key,
    required this.plan,
    this.onChange,
    this.onRegenerate,
  });
  final LessonPlan plan;
  final PlanChange? onChange;
  final RegenCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (plan.assessments.isEmpty) return const SizedBox.shrink();
    final canEdit = onChange != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(80),
          1: FixedColumnWidth(170),
          2: FixedColumnWidth(170),
          3: FixedColumnWidth(170),
          4: FixedColumnWidth(40), // Refresh icon column
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
            Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox.shrink()), // Header for refresh column
          ]),
          for (final a in plan.assessments) _assessmentRow(context, a, canEdit),
        ],
      ),
    );
  }

  TableRow _assessmentRow(
      BuildContext context, GradeAssessment a, bool canEdit) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text(a.gradeLabel)),
      _editableCell(context, a.formative, canEdit,
          (v) => _updateAssessment('formative', a.gradeLabel, v)),
      _editableCell(context, a.exitTask, canEdit,
          (v) => _updateAssessment('exitTask', a.gradeLabel, v)),
      _editableCell(context, a.successCriteria, canEdit,
          (v) => _updateAssessment('successCriteria', a.gradeLabel, v)),
      Center(
        child: onRegenerate != null
            ? IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: Colors.blue),
                tooltip: 'Regenerate assessment for ${a.gradeLabel}',
                onPressed: () => _showRegenerateConfirm(context, a.gradeLabel),
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _editableCell(BuildContext context, String value, bool canEdit,
      void Function(String) onChanged) {
    return GestureDetector(
      onTap: canEdit
          ? () async {
              final r = await showCellEditDialog(context,
                  title: 'Edit', initial: value);
              if (r != null) onChanged(r);
            }
          : null,
      child: MouseRegion(
        cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: canEdit ? Theme.of(context).hoverColor : null,
          child: Text(value),
        ),
      ),
    );
  }

  void _updateAssessment(String field, String gradeLabel, String value) {
    if (onChange == null) return;
    final idx = plan.grades.indexWhere((g) => g.gradeLabel == gradeLabel);
    if (idx < 0 || idx >= plan.assessments.length) return;
    final current = plan.assessments[idx];
    final updated = switch (field) {
      'formative' => current.copyWith(formative: value),
      'exitTask' => current.copyWith(exitTask: value),
      'successCriteria' => current.copyWith(successCriteria: value),
      _ => current,
    };
    onChange!((p) => p.copyWith(assessments: [
          for (int i = 0; i < p.assessments.length; i++)
            if (i == idx) updated else p.assessments[i],
        ]));
  }

  /// Shows a confirmation dialog before regenerating a grade's assessment.
  void _showRegenerateConfirm(BuildContext context, String gradeLabel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate Assessment'),
        content: Text(
            'This replaces your edits in the assessment for $gradeLabel. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRegenerate?.call(PlanSection.assessment, gradeLabel);
    }
  }
}

/// Ways Forward section with editable remediation and enrichment.
class WaysForwardSection extends StatelessWidget {
  const WaysForwardSection({
    super.key,
    required this.plan,
    this.onChange,
    this.onRegenerate,
  });
  final LessonPlan plan;
  final PlanChange? onChange;
  final RegenCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (plan.waysForward.isEmpty) return const SizedBox.shrink();
    final canEdit = onChange != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(80),
          1: FixedColumnWidth(210),
          2: FixedColumnWidth(210),
          3: FixedColumnWidth(40), // Refresh icon column
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
            Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox.shrink()), // Header for refresh column
          ]),
          for (final w in plan.waysForward) _waysRow(context, w, canEdit),
        ],
      ),
    );
  }

  TableRow _waysRow(BuildContext context, GradeWaysForward w, bool canEdit) {
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text(w.gradeLabel)),
      _editableCell(context, w.remediation, canEdit,
          (v) => _updateWays('remediation', w.gradeLabel, v)),
      _editableCell(context, w.enrichment, canEdit,
          (v) => _updateWays('enrichment', w.gradeLabel, v)),
      Center(
        child: onRegenerate != null
            ? IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: Colors.blue),
                tooltip: 'Regenerate ways forward for ${w.gradeLabel}',
                onPressed: () => _showRegenerateConfirm(context, w.gradeLabel),
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _editableCell(BuildContext context, String value, bool canEdit,
      void Function(String) onChanged) {
    return GestureDetector(
      onTap: canEdit
          ? () async {
              final r = await showCellEditDialog(context,
                  title: 'Edit', initial: value);
              if (r != null) onChanged(r);
            }
          : null,
      child: MouseRegion(
        cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: canEdit ? Theme.of(context).hoverColor : null,
          child: Text(value),
        ),
      ),
    );
  }

  void _updateWays(String field, String gradeLabel, String value) {
    if (onChange == null) return;
    final idx = plan.grades.indexWhere((g) => g.gradeLabel == gradeLabel);
    if (idx < 0 || idx >= plan.waysForward.length) return;
    final current = plan.waysForward[idx];
    final updated = switch (field) {
      'remediation' => current.copyWith(remediation: value),
      'enrichment' => current.copyWith(enrichment: value),
      _ => current,
    };
    onChange!((p) => p.copyWith(waysForward: [
          for (int i = 0; i < p.waysForward.length; i++)
            if (i == idx) updated else p.waysForward[i],
        ]));
  }

  /// Shows a confirmation dialog before regenerating a grade's ways forward.
  void _showRegenerateConfirm(BuildContext context, String gradeLabel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate Ways Forward'),
        content: Text(
            'This replaces your edits in the remediation/enrichment for $gradeLabel. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRegenerate?.call(PlanSection.waysForward, gradeLabel);
    }
  }
}

/// Reflection questions section with editable questions.
class ReflectionSection extends StatelessWidget {
  const ReflectionSection({super.key, required this.plan, this.onChange});
  final LessonPlan plan;
  final PlanChange? onChange;

  void _editQuestion(BuildContext context, int index) async {
    if (onChange == null) return;
    final q = plan.reflectionQuestions[index];
    final text = await showCellEditDialog(context,
        title: 'Edit Question', initial: q.text);
    if (text == null) return;
    final newQ = q.copyWith(text: text);
    onChange!((p) => p.copyWith(reflectionQuestions: [
          for (int i = 0; i < p.reflectionQuestions.length; i++)
            if (i == index) newQ else p.reflectionQuestions[i],
        ]));
  }

  @override
  Widget build(BuildContext context) {
    if (plan.reflectionQuestions.isEmpty) return const SizedBox.shrink();
    final canEdit = onChange != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Text('Reflection Questions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (int i = 0; i < plan.reflectionQuestions.length; i++)
        GestureDetector(
          onTap: canEdit ? () => _editQuestion(context, i) : null,
          child: MouseRegion(
            cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                if (plan.reflectionQuestions[i].gradeLabel != null)
                  SizedBox(
                      width: 80,
                      child: Text('${plan.reflectionQuestions[i].gradeLabel}:',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(plan.reflectionQuestions[i].text)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

/// Footer section with editable notes and declarations.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key, required this.plan, this.onChange});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
    final canEdit = onChange != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _editableText(context, 'Prepared by: ${plan.preparedBy}',
              'Prepared by', plan.preparedBy, canEdit),
          _editableText(context, 'Checked by: ${plan.checkedBy}', 'Checked by',
              plan.checkedBy, canEdit),
        ]),
        Expanded(
          child: Text(plan.aiUseDeclaration,
              textAlign: TextAlign.right,
              style: const TextStyle(fontStyle: FontStyle.italic)),
        ),
      ]),
    );
  }

  Widget _editableText(BuildContext context, String display, String fieldName,
      String value, bool canEdit) {
    return GestureDetector(
      onTap: canEdit
          ? () async {
              final r = await showCellEditDialog(context,
                  title: 'Edit $fieldName', initial: value);
              if (r != null && onChange != null) {
                switch (fieldName) {
                  case 'Prepared by':
                    onChange!((p) => p.copyWith(preparedBy: r));
                    break;
                  case 'Checked by':
                    onChange!((p) => p.copyWith(checkedBy: r));
                    break;
                  default:
                    break;
                }
              }
            }
          : null,
      child: MouseRegion(
        cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
        child: Text(display,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: canEdit ? null : Colors.black87)),
      ),
    );
  }
}

/// Notes next session section.
class NotesSection extends StatelessWidget {
  const NotesSection({super.key, required this.plan, this.onChange});
  final LessonPlan plan;
  final PlanChange? onChange;

  @override
  Widget build(BuildContext context) {
    final canEdit = onChange != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Notes for Next Session',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: canEdit
              ? () async {
                  final r = await showCellEditDialog(context,
                      title: 'Edit Notes',
                      initial: plan.notesNextSession,
                      maxLines: 10);
                  if (r != null && onChange != null)
                    onChange!((p) => p.copyWith(notesNextSession: r));
                }
              : null,
          child: MouseRegion(
            cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: canEdit ? Theme.of(context).hoverColor : null,
              child: Text(plan.notesNextSession),
            ),
          ),
        ),
      ]),
    );
  }
}
