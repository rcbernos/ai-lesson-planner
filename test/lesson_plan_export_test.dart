import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/services/export/lesson_plan_export.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/sample_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'exports an edited plan in PDF, Word, and portable bundle formats',
    () async {
      final plan = createSamplePlan().copyWith(
        sharedSubTheme: 'Updated & reviewed',
      );
      final pdf = await exportLessonPlan(plan, PlanExportFormat.pdf);
      expect(ascii.decode(pdf.take(5).toList()), '%PDF-');

      final docx = await exportLessonPlan(plan, PlanExportFormat.docx);
      final document = ZipDecoder()
          .decodeBytes(docx)
          .findFile('word/document.xml');
      final xml = utf8.decode(document!.content);
      expect(xml, contains('Updated &amp; reviewed'));
      expect(xml, contains('Learning Experience'));
      expect(xml, contains('Ways Forward'));

      final lms = await exportLessonPlan(plan, PlanExportFormat.lms);
      final payload = ZipDecoder().decodeBytes(lms).findFile('plan.json');
      final restored = LessonPlan.fromJson(
        jsonDecode(utf8.decode(payload!.content)) as Map<String, dynamic>,
      );
      expect(restored.toJson(), plan.toJson());
    },
  );
}
