# Phase 1: Dev 2 Commit Plan

**Branch:** `feature/database`

---

## Overview

This document outlines the step-by-step plan for Dev 2 to build the **local data layer and first-run seeding** functionality for the Offline AI Lesson Plan Assistant. The goal is to set up Drift/SQLite using `path_provider`, define the database schemas for lesson plans, reference notes, and bibliography, implement CRUD operations, and add an auto-seeding hook that runs on first launch.

---

## 📋 Tasks to Execute

### Task 1: Set up Drift / SQLite using `path_provider`

1. **Create the directory structure:**
   - `/lib/services/database/` — Drift database class and companion helpers.
   - `/lib/models/database/` — `@driftTable` table definitions.

2. **Create the Drift database class** (`/lib/services/database/app_database.dart`):
   - Annotate with `@DriftDatabase(tables: [LessonPlans, ReferenceNotes, Bibliography])`.
   - Set `schemaVersion` and `migration` (createAll on first run, version bumps on upgrades).
   - Initialize the database file in the **application support directory** resolved via `AppUtils.getAppSupportDir()` (which wraps `path_provider`'s `getApplicationSupportDirectory()`).

3. **Generate the Drift code** via `build_runner`:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   This produces `app_database.g.dart`.

4. **Create a database singleton/access helper** (`/lib/services/database/database_helper.dart`)
   - Lazily-initialized singleton (`DatabaseHelper.instance`) so Riverpod (Dev 3) and the generator (Dev 1) can retrieve the same `AppDatabase` instance.
   - Exposes `AppDatabase get db` and a `close()` for teardown/testing.

**Commit Message:** `feat(database): scaffold Drift/SQLite layer with path_provider integration`

---
### Task 2: Define database schemas

Define three Drift tables with proper types, foreign keys, and indexes:

1. **`lesson_plans`** — core lesson plan records:
   - `id` — `IntColumn` (auto-increment PK)
   - `title` — `TextColumn`
   - `gradeLevel` — `IntColumn` (nullable, integer e.g. 7–12)
   - `subject` — `TextColumn` (nullable)
   - `ilawContent` — `TextColumn` (nullable — ILAW JSON or rendered content)
   - `status` — `TextColumn` with default `'draft'` (e.g. `draft`, `generated`, `exported`)
   - `createdAt` — `DateTimeColumn` with `withDefault(currentDateAndTime)`
   - `updatedAt` — `DateTimeColumn` (nullable)

2. **`reference_notes`** — manual teacher reference notes attached to a lesson plan:
   - `id` — `IntColumn` (auto-increment PK)
   - `lessonPlanId` — `IntColumn` — references `lesson_plans.id` → `onDelete(DeleteType.SET_NULL)`, `@indexed`
   - `title` — `TextColumn`
   - `content` — `TextColumn` (nullable)
   - `createdAt` — `DateTimeColumn` with `withDefault(currentDateAndTime)`

3. **`bibliography`** — structured bibliography metadata (Author, Title, Year) per ILAW spec:
   - `id` — `IntColumn` (auto-increment PK)
   - `lessonPlanId` — `IntColumn` — references `lesson_plans.id` → `onDelete(DeleteType.SET_NULL)`, `@indexed`
   - `author` — `TextColumn`
   - `title` — `TextColumn`
   - `year` — `IntColumn`
   - `url` — `TextColumn` (nullable)
   - `createdAt` — `DateTimeColumn` with `withDefault(currentDateAndTime)`

Use `@DataClassName` if custom class names are desired. Tables use companion objects (e.g. `LessonPlansCompanion.insert(...)`) for type-safe writes.

**Commit Message:** `feat(database): define lesson plans, reference notes, and bibliography table schemas`

---

### Task 3: CRUD operations

Implement full CRUD for all three tables in the `AppDatabase` class (or a dedicated DAO):

- **Lesson Plans:**
  - `Future<int> insertLessonPlan(LessonPlansCompanion entry)`
  - `Future<List<LessonPlan>> getAllLessonPlans()`
  - `Future<LessonPlan?> getLessonPlanById(int id)`
  - `Future<bool> updateLessonPlan(LessonPlan entry)` / `updateLessonPlans(LessonPlansCompanion entry)`
  - `Future<int> deleteLessonPlan(int id)`

- **Reference Notes:**
  - `Future<int> insertReferenceNote(ReferenceNotesCompanion note)`
  - `Future<List<ReferenceNote>> getReferenceNotesForLessonPlan(int lessonPlanId)`
  - `Future<bool> updateReferenceNote(ReferenceNote note)`
  - `Future<int> deleteReferenceNote(int id)`

- **Bibliography:**
  - `Future<int> insertBibliographyEntry(BibliographyCompanion entry)`
  - `Future<List<Bibliography>> getBibliographyForLessonPlan(int lessonPlanId)`
  - `Future<bool> updateBibliographyEntry(Bibliography entry)`
  - `Future<int> deleteBibliographyEntry(int id)`

Use transactions for atomic multi-table writes (e.g. inserting a lesson plan with its notes and citations in one batch).

**Commit Message:** `feat(database): implement CRUD operations for all data tables`

---
### Task 4: First-Run Seeding Hook

1. **Implement `seed()` method** in `AppDatabase`:
   - Inserts sample/default **Reference Notes** (e.g., "DepEd K-12 Curriculum Guide" overview note).
   - Inserts sample/default **Bibliography** entries (e.g., Department of Education, K to 12 Curriculum Guide).
   - Optionally inserts a sample **Lesson Plan** placeholder so the Library tab has visible content on first launch.

2. **Trigger in `onCreate`**:
   ```dart
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (migrator) async {
       await migrator.createAll();
       await seed();  // auto-populate defaults
     },
   );
   ```

3. **Safety check in `onOpen`**:
   - If tables exist but are empty (e.g., db file existed but migration did not run seed), seed once.
   - Guard against duplicate seeding by checking whether any default rows already exist before inserting.

4. **Verification of delete/restart scenario**:
   - Deleting the SQLite file and relaunching triggers `onCreate` again → re-creates tables + re-seeds.
   - The hook does **not** crash if the db file is missing or partially written.

**Commit Message:** `feat(database): implement first-run seeding hook with safety checks`

---

### Task 5: Unit tests

Create `/test/database/database_test.dart`:

1. **Database creation test** — open database in a tmp dir, verify the `.db` file is created in the expected path.
2. **CRUD tests** — insert → fetch → update → delete a lesson plan (and reference notes + bibliography entries).
3. **Seeding tests** —
   - Fresh database: `seed()` populates default rows; counts > 0.
   - Existing database with data: `seed()` is a no-op / does not duplicate.
   - Delete db file + recreate: `onCreate` fires and seeding populates defaults.

Run tests with `flutter test`.

**Commit Message:** `test(database): add unit tests for CRUD and seeding`

---

### Task 6: Documentation updates

1. Update `/working_docs/verification_checklist.md` — add Phase 1 Dev 2 checklist items.
2. Append entries to `/working_docs/commit_log.md` (create if absent).

**Commit Message:** `docs: update verification checklist and commit log for Phase 1 Dev 2`

---

## ✅ Human Verification Checklist

Based on `phase0_complete_dev_plan.md` → Phase 1 Dev 2 requirements and `verification_checklist.md`:

- [ ] The local SQLite database file is successfully created in the application support directory upon first launch.
- [ ] Tables for lesson plans, reference notes, and bibliography metadata read and write correctly.
- [ ] Deleting the local database file and restarting the app successfully triggers the auto-seeding hook without crashing.
- [ ] Unit tests pass (`flutter test`).
- [ ] Code compiles without analyzer warnings (`flutter analyze`).

---

## Expected Outcome / Final Directory Structure

After Phase 1 Dev 2 (`feature/database` branch):

```
lib/
  core/
    app_config.dart        (existing — unchanged)
    utils.dart             (existing — unchanged, used by db path resolver)
  services/
    database/
      app_database.dart     # Drift @DriftDatabase class w/ migrations + seed
      app_database.g.dart   # Generated Drift code
      database_helper.dart  # Singleton access helper
  models/
    database/
      tables.dart           # @driftTable defs: LessonPlans, ReferenceNotes, Bibliography
  test/
    database/
      database_test.dart    # Unit tests for CRUD + seeding
```

- The app opens successfully with the database initialized in the application support directory.
- Dev 3 (UI Shell) and Dev 1 (AI Engine) can consume the database via `DatabaseHelper.instance.db`.

---

## 🔄 Phase 1 Merge Milestone

Dev 1 pulls `feature/ai-engine`, `feature/database`, and `feature/ui-shell` into `main`, resolves any conflicts (Riverpod providers, shared `AppUtils`, path conventions), and pushes a unified stable build.

---

## 📊 Expected Outcome (Summary)

After Phase 1 Dev 2 is complete:
- ✅ Drift/SQLite database layer operational using `path_provider`.
- ✅ Three schemas defined: `lesson_plans`, `reference_notes`, `bibliography`.
- ✅ Full CRUD implemented and tested for all tables.
- ✅ First-run seeding hook populates default structures on initial launch.
- ✅ Delete + restart scenario verified — no crashes, data re-seeded.

---

## Notes

- Aligns with the **ILAW Format** (`app_config.dart`) in how lesson plan + bibliography data will be stored for AI prompt construction (Phase 2).
- `schemaVersion` starts on **1**; future migrations (e.g., adding columns for Phase 2 references UI) will bump it.
- Seeded default data is intentionally minimal and DepEd-aligned; teachers can expand via the Phase 2 reference-notes UI built by Dev 2 in `feature/references`.
- The `path_provider` plugin (already in `pubspec.yaml`) is used — no new dependencies required.

---

## ✅ Phase 1 Dev 2 Completion Status

- [ ] Phase 1 Dev 2 commit plan written (`working_docs/phase1_dev2_commitplan.md`)
- [ ] Database scaffolding (Task 1) — committed
- [ ] Schema definitions (Task 2) — committed
- [ ] CRUD operations (Task 3) — committed
- [ ] First-run seeding hook (Task 4) — committed
- [ ] Unit tests (Task 5) — committed
- [ ] Documentation updates (Task 6) — committed
- [ ] Verification checklist fully passed

