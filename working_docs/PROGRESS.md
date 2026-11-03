# Progress

## Phase 0 - Repository Reconciliation (dev1 branch)
**Status:** COMPLETED
- AI engine code moved to `lib/services/ai/legacy/`
- Dependencies fixed: `llama_cpp_dart` removed, `file_picker` added
- Noto Sans fonts added to `assets/fonts/` (Regular, Bold)
- Path resolution fixed in `utils.dart` using `path_provider`
- Drift/SQLite layer complete with tables, CRUD, first-run seeding

## Phase 1 - Visible App (dev1 branch)
**Status:** T1.9 COMPLETE

**T1.2 - Clean build verified:**
- `flutter analyze`: zero issues (pre-existing info-level style suggestions only)
- `flutter test`: 49 tests pass (new library tests added)

**T1.3 - Domain model complete:**
- Created `lib/core/models/lesson_plan.dart` with 7 classes
- Tests for JSON round-trip pass

**T1.4 - App shell and theme complete:**
- Created `lib/core/theme.dart` with light/dark Material 3 themes
- Created `lib/features/shell/app_shell.dart` with NavigationRail

**T1.5 - Generator interface and mock complete:**
- Created `lib/core/generation/lesson_generator.dart` with event hierarchy
- Created `lib/core/generation/mock_lesson_generator.dart` with streaming

**T1.7 - Plan renderer complete:**
- Updated `IlawPlanView` with complete header and all sections

**T1.8 - Wire generator to renderer complete:**
- Created providers.dart and generation_controller.dart
- Full generation flow implemented with cancel support

**Bug fixes applied:**
- Hybrid Controller Pattern for form state sync
- Table column widths for Assessment, Ways Forward, FlowTable

**T1.9 - Library backed by Drift:**
- Created `plan_repository.dart` with save/load/delete operations
- Created `library_screen.dart` with ListView of saved plans
- Added Save button to generator_screen AppBar
- Updated NavigationRail to show LibraryScreen
