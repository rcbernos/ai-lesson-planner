import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models/database/tables.dart';

part 'app_database.g.dart';

/// The main Drift database for the AI Lesson Plan Assistant.
@DriftDatabase(tables: [LessonPlans, ReferenceNotes, Bibliography])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor that opens the database at an explicit file path.
  AppDatabase.forTesting(File file)
      : super(_openConnectionForFile(file));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await seed();
      },
      beforeOpen: (details) async {
        // Safety check: if tables exist but are empty (e.g., the db file
        // existed but seeding never ran), seed once.
        final existingNotes = await referenceNotes.select().get();
        if (existingNotes.isEmpty) {
          await seed();
        }
      },
    );
  }

  // ── Lesson Plans ──────────────────────────────────────────────────────────

  Future<int> insertLessonPlan(LessonPlansCompanion entry) =>
      into(lessonPlans).insert(entry);

  Future<List<LessonPlan>> getAllLessonPlans() => select(lessonPlans).get();

  Future<LessonPlan?> getLessonPlanById(int id) =>
      (select(lessonPlans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> updateLessonPlan(LessonPlan entry) =>
      update(lessonPlans).replace(entry);

  Future<int> deleteLessonPlan(int id) =>
      (delete(lessonPlans)..where((t) => t.id.equals(id))).go();

  // ── Reference Notes ───────────────────────────────────────────────────────

  Future<int> insertReferenceNote(ReferenceNotesCompanion entry) =>
      into(referenceNotes).insert(entry);

  Future<List<ReferenceNote>> getReferenceNotesForLessonPlan(int lessonPlanId) =>
      (select(referenceNotes)
            ..where((t) => t.lessonPlanId.equals(lessonPlanId)))
          .get();

  Future<bool> updateReferenceNote(ReferenceNote entry) =>
      update(referenceNotes).replace(entry);

  Future<int> deleteReferenceNote(int id) =>
      (delete(referenceNotes)..where((t) => t.id.equals(id))).go();

  // ── Bibliography ──────────────────────────────────────────────────────────

  Future<int> insertBibliographyEntry(BibliographyCompanion entry) =>
      into(bibliography).insert(entry);

  Future<List<BibliographyData>> getBibliographyForLessonPlan(int lessonPlanId) =>
      (select(bibliography)
            ..where((t) => t.lessonPlanId.equals(lessonPlanId)))
          .get();

  Future<bool> updateBibliographyEntry(BibliographyData entry) =>
      update(bibliography).replace(entry);

  Future<int> deleteBibliographyEntry(int id) =>
      (delete(bibliography)..where((t) => t.id.equals(id))).go();

  // ── First-Run Seeding Hook ────────────────────────────────────────────────

  Future<void> seed() async {
    // Guard against duplicate seeding
    final existing = await select(referenceNotes).get().then((r) => r.isNotEmpty);
    if (existing) return;

    await transaction(() async {
      // Sample reference note
      await into(referenceNotes).insert(ReferenceNotesCompanion.insert(
        title: 'DepEd K-12 Curriculum Guide',
        content: const Value(
            'Reference for curriculum standards and learning competencies across grade levels.'),
      ));

      // Sample bibliography entry
      await into(bibliography).insert(BibliographyCompanion.insert(
        author: 'Department of Education',
        title: 'K to 12 Basic Education Curriculum Guide',
        year: 2023,
      ));
    });
  }
}

/// Opens the SQLite database in the application support directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'ai_lesson_planner.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Opens the SQLite database at an explicit file path (used for testing).
LazyDatabase _openConnectionForFile(File file) {
  return LazyDatabase(() async {
    return NativeDatabase.createInBackground(file);
  });
}
