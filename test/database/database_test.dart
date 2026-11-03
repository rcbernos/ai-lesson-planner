import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lesson_planner/services/database/app_database.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ai_lesson_planner_test');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}test.db');
    db = AppDatabase.forTesting(dbFile);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('Database creation', () {
    test('creates the .db file at the expected path', () async {
      // Trigger opening of the lazy database connection.
      await db.getAllLessonPlans();
      expect(dbFile.existsSync(), isTrue);
    });
  });

  group('Lesson Plans CRUD', () {
    test('insert -> fetch -> update -> delete a lesson plan', () async {
      final id = await db.insertLessonPlan(LessonPlansCompanion.insert(
        title: 'Photosynthesis',
        gradeLevel: const Value(7),
        subject: const Value('Science'),
        status: const Value('draft'),
      ));
      expect(id, greaterThan(0));

      var plan = await db.getLessonPlanById(id);
      expect(plan, isNotNull);
      expect(plan!.title, 'Photosynthesis');
      expect(plan.status, 'draft');

      final updated = plan.copyWith(status: 'generated');
      final ok = await db.updateLessonPlan(updated);
      expect(ok, isTrue);
      plan = await db.getLessonPlanById(id);
      expect(plan!.status, 'generated');

      final rows = await db.deleteLessonPlan(id);
      expect(rows, 1);
      expect(await db.getLessonPlanById(id), isNull);
    });

    test('getAllLessonPlans returns all inserted rows', () async {
      await db.insertLessonPlan(LessonPlansCompanion.insert(title: 'A'));
      await db.insertLessonPlan(LessonPlansCompanion.insert(title: 'B'));
      final plans = await db.getAllLessonPlans();
      expect(plans.length, 2);
    });
  });

  group('Reference Notes CRUD', () {
    test('insert -> fetch -> update -> delete a reference note', () async {
      final lessonId = await db.insertLessonPlan(LessonPlansCompanion.insert(title: 'L'));

      final noteId = await db.insertReferenceNote(ReferenceNotesCompanion.insert(
        lessonPlanId: Value(lessonId),
        title: 'DepEd K-12 Curriculum Guide',
        content: const Value('Curriculum standards reference.'),
      ));
      expect(noteId, greaterThan(0));

      var notes = await db.getReferenceNotesForLessonPlan(lessonId);
      expect(notes.length, 1);
      expect(notes.first.title, 'DepEd K-12 Curriculum Guide');

      final updated = notes.first.copyWith(title: 'Updated note');
      expect(await db.updateReferenceNote(updated), isTrue);
      notes = await db.getReferenceNotesForLessonPlan(lessonId);
      expect(notes.first.title, 'Updated note');

      expect(await db.deleteReferenceNote(noteId), 1);
      expect(await db.getReferenceNotesForLessonPlan(lessonId), isEmpty);
    });
  });

  group('Bibliography CRUD', () {
    test('insert -> fetch -> update -> delete a bibliography entry', () async {
      final lessonId = await db.insertLessonPlan(LessonPlansCompanion.insert(title: 'L'));

      final entryId = await db.insertBibliographyEntry(BibliographyCompanion.insert(
        lessonPlanId: Value(lessonId),
        author: 'Department of Education',
        title: 'K to 12 Basic Education Curriculum Guide',
        year: 2023,
        url: const Value('https://www.deped.gov.ph'),
      ));
      expect(entryId, greaterThan(0));

      var entries = await db.getBibliographyForLessonPlan(lessonId);
      expect(entries.length, 1);
      expect(entries.first.author, 'Department of Education');
      expect(entries.first.year, 2023);

      final updated = entries.first.copyWith(year: 2024);
      expect(await db.updateBibliographyEntry(updated), isTrue);
      entries = await db.getBibliographyForLessonPlan(lessonId);
      expect(entries.first.year, 2024);

      expect(await db.deleteBibliographyEntry(entryId), 1);
      expect(await db.getBibliographyForLessonPlan(lessonId), isEmpty);
    });
  });



  group('First-run seeding', () {
    test('fresh database is seeded with default rows', () async {
      // Opening the fresh db triggers onCreate -> seed().
      final plans = await db.getAllLessonPlans();
      final notes = await db.select(db.referenceNotes).get();
      final bib = await db.select(db.bibliography).get();
      expect(notes, isNotEmpty);
      expect(bib, isNotEmpty);
      expect(plans, isEmpty); // seed intentionally does not insert lesson plans
    });

    test('seed() is a no-op when defaults already exist', () async {
      final notesBefore = await db.select(db.referenceNotes).get();
      expect(notesBefore, isNotEmpty);

      await db.seed();

      final notesAfter = await db.select(db.referenceNotes).get();
      expect(notesAfter.length, notesBefore.length);
    });

    test('delete + recreate triggers re-seeding without crashing', () async {
      await db.select(db.referenceNotes).get(); // force open + onCreate
      await db.close();

      // Simulate deleting the database file and restarting.
      if (dbFile.existsSync()) dbFile.deleteSync();

      final freshDb = AppDatabase.forTesting(dbFile);
      final notes = await freshDb.select(freshDb.referenceNotes).get();
      expect(notes, isNotEmpty);
      await freshDb.close();
    });

    test('onOpen re-seeds an existing but empty database', () async {
      await db.select(db.referenceNotes).get(); // ensure seeded/open
      // Wipe data without deleting the file (simulates a db file that predates seeding).
      await db.delete(db.referenceNotes).go();
      await db.delete(db.bibliography).go();
      await db.close();

      final reopened = AppDatabase.forTesting(dbFile);
      final notes = await reopened.select(reopened.referenceNotes).get();
      expect(notes, isNotEmpty);
      await reopened.close();
    });
  });
}
