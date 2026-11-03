# Phase 0: Repository Reconciliation (dev1 branch)

**Goal:** Prepare the repository for solo development on `dev1` branch. Remove old multi-dev artifacts, move unverified AI code to legacy, fix dependencies, fonts, paths, and tests so the codebase is clean and buildable.

**Branch:** `dev1` (create from `main`). Merge to `main` only when Phase 0 is complete and verified.

Each card is one agent session. Do the cards in order.

---

## P0.1 Create PROGRESS.md and dev1 branch
**Files:** `working_docs/PROGRESS.md` (new), repo root.
**Do:**
1. `git checkout main`
2. `git checkout -b dev1`
3. Create `working_docs/PROGRESS.md` with initial status (2-5 lines: current state and next task)
4. Keep `PROGRESS.md` under 60 lines
**Verify:** `git branch` shows `main` and `dev1`, `PROGRESS.md` exists.
**Commit:** `chore: create dev1 branch and PROGRESS.md`

---

## P0.2 Move unverified AI code to legacy
**Files:** `lib/services/ai_service.dart`, `lib/services/downloads.dart`, `lib/services/providers/ai_providers.dart`, `lib/services/index.dart`.
**Do:**
1. Create `lib/services/ai/legacy/` directory
2. Move `ai_service.dart`, `downloads.dart`, `ai_providers.dart` to `lib/services/ai/legacy/`
3. Update `lib/services/index.dart` to NOT export the moved files (export only database services)
4. Ensure no imports of the moved files remain in the codebase
**Verify:** `grep -r "ai_service\|downloads\|ai_providers" lib/ --include="*.dart" | grep -v legacy` returns nothing.
**Commit:** `refactor: move unverified AI engine code to legacy`

---

## P0.3 Fix dependencies
**Files:** `pubspec.yaml`, `pubspec.lock`.
**Do:**
1. Remove `llama_cpp_dart: ^0.2.2`
2. Confirm `docs_gee: ^1.5.0`, `pdf: ^3.13.1`, `archive: ^4.0.2` are present
3. Add `file_picker: ^8.0.0` (or latest compatible)
4. Confirm `flutter_riverpod`, `drift`, `drift_dev` (dev), `build_runner` (dev), `sqlite3_flutter_libs`, `path`, `path_provider`, `http`, `crypto`, `uuid` are present
5. Run `dart run build_runner build --delete-conflicting-outputs`
6. Run `flutter pub get`
**Verify:** `flutter analyze` has zero issues, `flutter test` passes (after P0.6), `flutter build linux` produces a binary, `pubspec.lock` is committed.
**Commit:** `fix: repair dependencies and get a clean build`

---

## P0.4 Add Noto Sans fonts
**Files:** `pubspec.yaml`, `assets/fonts/` (new directory with font files).
**Do:**
1. Download Noto Sans (Regular, Bold) to `assets/fonts/`
2. Update `pubspec.yaml` fonts section from Roboto to Noto Sans
3. Update `pubspec.yaml` assets section to include `assets/fonts/`
**Verify:** `flutter analyze` passes, app builds without font errors.
**Commit:** `feat: add Noto Sans fonts as assets`

---

## P0.5 Fix hardcoded path in utils.dart
**Files:** `lib/core/utils.dart`.
**Do:**
1. Replace hardcoded `/LMS_Data/Exports/` with `path_provider` + `package:path` resolution
2. Use `getApplicationDocumentsDirectory()` or `getApplicationSupportDirectory()` + `Documents/LMS_Data/Exports/`
3. Ensure cross-platform compatibility (no hardcoded forward slashes)
**Verify:** `flutter analyze` passes, path resolution works on Linux.
**Commit:** `fix: resolve export directory via path_provider`

---

## P0.6 Fix widget test
**Files:** `test/widget_test.dart` (replace), optionally add `test/fixtures/`.
**Do:**
1. Delete the default counter widget test
2. Add a minimal smoke test that verifies the app builds and shows the title
3. Or delete the file entirely if no meaningful test exists yet
**Verify:** `flutter test` passes.
**Commit:** `test: replace default widget test with smoke test`

---

## P0.7 Run full verification
**Files:** (none — verification only)
**Do:**
1. Run `dart format .`
2. Run `flutter analyze` — must have zero issues
3. Run `flutter test` — must pass
4. Run `flutter build linux` — must produce binary
**Verify:** All three commands succeed.
**Commit:** `chore: verify clean build and tests`

---

## P0.8 Update PROGRESS.md and finish Phase 0
**Files:** `working_docs/PROGRESS.md`.
**Do:**
1. Add 2-5 lines to `PROGRESS.md` summarizing Phase 0 completion
2. Note next task: Phase 1 T1.1 (Domain model)
**Verify:** `PROGRESS.md` updated, under 60 lines.
**Commit:** `docs: update PROGRESS.md after Phase 0 completion`

---

## Phase 0 Acceptance
- [ ] `dev1` branch exists and is checked out
- [ ] `PROGRESS.md` exists with current status
- [ ] Unverified AI code moved to `lib/services/ai/legacy/` with no imports
- [ ] `llama_cpp_dart` removed from dependencies
- [ ] `file_picker` added to dependencies
- [ ] Noto Sans fonts bundled in `assets/fonts/`
- [ ] No hardcoded paths in `utils.dart`
- [ ] `flutter analyze` has zero issues
- [ ] `flutter test` passes
- [ ] `flutter build linux` produces a binary
- [ ] `PROGRESS.md` updated and under 60 lines

Then merge `dev1` into `main`.