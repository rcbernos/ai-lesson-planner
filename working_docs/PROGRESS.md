# Progress

## Phase 0 - Repository Reconciliation (dev1 branch)
**Status:** COMPLETED

**Accomplishments:**
- AI engine code moved to `lib/services/ai/legacy/`
- Dependencies fixed: `llama_cpp_dart` removed, `file_picker` added
- Noto Sans fonts added to `assets/fonts/` (Regular, Bold)
- Path resolution fixed in `utils.dart` using `path_provider`
- Drift/SQLite layer complete with tables, CRUD, first-run seeding
- All tests pass (20 tests), `flutter analyze` passes with zero issues
- `flutter build linux` produces a working binary

## Phase 1 - Visible App (dev1 branch)
**Status:** T1.4 COMPLETE

**T1.2 - Clean build verified:**
- `flutter analyze`: zero issues
- `flutter test`: 35 tests pass
- `flutter build linux`: binary produced successfully

**T1.3 - Domain model complete:**
- Created `lib/core/models/lesson_plan.dart` with 7 classes
- Created fixture and tests for JSON round-trip
- All 35 tests pass

**T1.4 - App shell and theme complete:**
- Created `lib/core/theme.dart` with light/dark Material 3 themes
- Created `lib/features/shell/app_shell.dart` with NavigationRail
- Updated `lib/main.dart` to use AppShell
- Updated widget tests for new app structure
- All 35 tests pass

**T1.5 - Generator interface and mock complete:**
- Created `lib/core/generation/lesson_generator.dart` with OutputLanguage, GradeInput, GenerationRequest, GenerationEvent hierarchy, and LessonGenerator abstract class
- Created `lib/core/generation/mock_lesson_generator.dart` with streaming simulation
- Created `test/mock_generator_test.dart` with 4 tests verifying section order, grade count, flow minutes, and cancel behavior
- `flutter analyze`: zero issues, `flutter test`: all 35 tests pass

**Next task:** T1.6 - Generator form