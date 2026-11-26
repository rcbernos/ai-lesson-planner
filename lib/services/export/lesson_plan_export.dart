import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docs_gee/docs_gee.dart' as word;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;

import '../../core/models/lesson_plan.dart';

enum PlanExportFormat {
  pdf('PDF', 'pdf', 'application/pdf'),
  docx(
    'Word',
    'docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),
  lms('Lesson plan bundle', 'lms', 'application/zip');

  const PlanExportFormat(this.label, this.extension, this.mimeType);
  final String label;
  final String extension;
  final String mimeType;
}

/// Produces portable export bytes from the current lesson plan.
Future<Uint8List> exportLessonPlan(
  LessonPlan plan,
  PlanExportFormat format,
) async {
  if (format == PlanExportFormat.lms) {
    final payload = utf8.encode(jsonEncode(plan.toJson()));
    final archive = Archive()..addFile(ArchiveFile.bytes('plan.json', payload));
    return ZipEncoder().encodeBytes(archive);
  }

  final blocks = _documentBlocks(plan);
  if (format == PlanExportFormat.docx) {
    final doc = word.Document(title: 'Daily Lesson Plan');
    for (final (level, text) in blocks) {
      if (level > 0) {
        doc.addParagraph(word.Paragraph.heading(text, level: level));
      } else {
        doc.addParagraph(word.Paragraph.text(text));
      }
    }
    return Uint8List.fromList(word.DocxGenerator().generate(doc));
  }

  final regular = pdf.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final bold = pdf.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  final doc = pdf.Document(title: 'Daily Lesson Plan');
  doc.addPage(
    pdf.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pdf.EdgeInsets.all(44),
      theme: pdf.ThemeData.withFont(base: regular, bold: bold),
      maxPages: 500,
      footer: (context) => pdf.Align(
        alignment: pdf.Alignment.centerRight,
        child: pdf.Text(
          '${context.pageNumber}',
          style: const pdf.TextStyle(fontSize: 9),
        ),
      ),
      build: (_) => [
        for (final (level, text) in blocks) ...[
          if (level > 0) ...[
            pdf.NewPage(freeSpace: 42),
            pdf.SizedBox(height: 7),
          ],
          pdf.Text(
            text,
            overflow: pdf.TextOverflow.span,
            style: pdf.TextStyle(
              fontSize: switch (level) {
                1 => 20,
                2 => 14,
                3 => 11,
                _ => 10,
              },
              fontWeight: level > 0
                  ? pdf.FontWeight.bold
                  : pdf.FontWeight.normal,
            ),
          ),
          pdf.SizedBox(height: 2),
        ],
      ],
    ),
  );
  return doc.save();
}

List<(int, String)> _documentBlocks(LessonPlan plan) {
  final header = plan.header;
  final blocks = <(int, String)>[];
  void heading(String value, [int level = 2]) => blocks.add((level, value));
  void line(String label, String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    final lines = text.split(RegExp(r'\r?\n'));
    blocks.add((0, label.isEmpty ? lines.first : '$label: ${lines.first}'));
    for (final next in lines.skip(1)) {
      if (next.trim().isNotEmpty) blocks.add((0, next));
    }
  }

  String? linkedCompetency(String gradeLabel, int? index) {
    final grade = plan.grades
        .where((grade) => grade.gradeLabel == gradeLabel)
        .firstOrNull;
    if (grade == null ||
        index == null ||
        index < 0 ||
        index >= grade.competencies.length) {
      return null;
    }
    return grade.competencies[index];
  }

  heading('Daily Lesson Plan', 1);
  line('School', header.school);
  line('Teacher', header.teacher);
  line('Learning area', header.learningArea);
  line('Grade levels', plan.grades.map((grade) => grade.gradeLabel).join(', '));
  line('Date', header.date);
  line('Term', header.term);
  line(
    'Sessions',
    '${header.sessions} at ${header.sessionMinutes} minutes each',
  );
  line('Multigrade model', header.multigradeModel);

  heading('Intentions');
  line('Shared sub-theme', plan.sharedSubTheme);
  line('Shared objective', plan.bothGradesObjective);
  for (final grade in plan.grades) {
    heading(grade.gradeLabel, 3);
    line(
      'Learners',
      '${grade.learnersMale} male, ${grade.learnersFemale} female',
    );
    line('Sub-theme', grade.subTheme);
    line('Content standard', grade.contentStandard);
    line('Performance standard', grade.performanceStandard);
    for (final competency in grade.competencies) {
      line('Competency', competency);
    }
    for (final objective in grade.objectives) {
      line('Objective', objective);
    }
  }

  heading('Learning Experience');
  line('Learner context', plan.learnerContext);
  for (final item in plan.materials.items) {
    line('Material', item);
  }
  for (final reference in plan.materials.references) {
    line('Reference', reference);
  }
  for (final stage in plan.flow) {
    heading('${stage.stage} (${stage.minutes} min)', 3);
    if (stage.wholeClass) {
      line('Whole class', stage.wholeClassActivity);
    } else {
      for (final grade in plan.grades) {
        final label = grade.gradeLabel;
        line(label, stage.activityByGrade[label] ?? '');
        line(
          'Competency',
          linkedCompetency(label, stage.competencyIndexByGrade[label]) ?? '',
        );
      }
    }
  }

  heading('Assessment');
  for (final assessment in plan.assessments) {
    heading(assessment.gradeLabel, 3);
    line('Formative assessment', assessment.formative);
    line('Exit task', assessment.exitTask);
    line('Success criteria', assessment.successCriteria);
    line(
      'Competency',
      linkedCompetency(assessment.gradeLabel, assessment.competencyIndex) ?? '',
    );
  }

  heading('Ways Forward');
  for (final row in plan.waysForward) {
    heading(row.gradeLabel, 3);
    line('Remediation', row.remediation);
    line('Enrichment', row.enrichment);
  }
  if (plan.reflectionQuestions.isNotEmpty) heading('Reflection Questions', 3);
  for (final question in plan.reflectionQuestions) {
    line(question.gradeLabel ?? 'Whole class', question.text);
  }
  line('Notes for next session', plan.notesNextSession);
  line(
    'Prepared by',
    [
      plan.preparedBy,
      plan.preparedByRole,
    ].where((value) => value.trim().isNotEmpty).join(', '),
  );
  line(
    'Checked by',
    [
      plan.checkedBy,
      plan.checkedByRole,
    ].where((value) => value.trim().isNotEmpty).join(', '),
  );
  line('AI use declaration', plan.aiUseDeclaration);
  return blocks;
}
