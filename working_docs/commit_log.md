# Project Commit Log

This document tracks all commits made across feature branches and developers in the project.

---

## Phase 0: Scaffolding & Setup

- `fa9a3bc` - `feat: Initial project setup with all dependencies and documentation`
- `7c1069a` - `docs: added readme.md file for phase 0 scaffolding`
- `b34cc8a` - `docs: create phase1 commit plan`
- `8604200` - `fix(core): repair unterminated ILAW string literal in app_config and add missing AppConfig import in utils`

---

## Phase 1: Local Data Layer & First-Run Seeding (Dev 2 - Database)

**Branch:** `dev2` / `feature/database`

- `36d1267` - `feat(database): scaffold Drift/SQLite layer with schemas, CRUD operations and first-run seeding hook`
  - Created Drift database class `AppDatabase` and companion helpers.
  - Defined database tables: `LessonPlans`, `ReferenceNotes`, and `Bibliography`.
  - Implemented CRUD operations for lesson plans, notes, and bibliography.
  - Implemented first-run seeding hook in `onCreate` and `beforeOpen`.
- `b2104f9` - `chore: remove duplicate drift_dev from dependencies, add assets dir, track generated Drift code`
  - Cleaned up duplicate dependencies and tracked generated Drift code.
- `227a399` - `test(database): add unit tests for CRUD and seeding`
  - Created `test/database/database_test.dart` testing database creation, full CRUD, and seeding scenarios.
- `docs: update verification checklist and commit log for Phase 1 Dev 2`
  - Updated `verification_checklist.md`, `phase1_dev2_commitplan.md`, and created `commit_log.md`.
