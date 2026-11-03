# Progress

## Phase 0 - Repository Reconciliation (dev1 branch)

**Status:** COMPLETED

**Completed Tasks:**
- AI code moved to `lib/services/ai/legacy/` with no imports
- Dependencies fixed: `llama_cpp_dart` removed, `file_picker` added
- Noto Sans fonts added to `assets/fonts/`
- Path resolution fixed in `utils.dart` using `path_provider`
- Database work from `dev2` merged into `dev1`
- Drift/SQLite layer complete with tables, CRUD, first-run seeding
- All tests pass (20 tests), `flutter analyze` passes
- `flutter build linux` produces binary

**Next task:** Phase 1 T1.1 - Update PROGRESS.md