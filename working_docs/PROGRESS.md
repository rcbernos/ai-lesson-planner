# Progress

## Phase 0 - Repository Reconciliation (dev1 branch)
**Status:** COMPLETED

**Accomplishments:**
- AI engine code moved to `lib/services/ai/legacy/`
- Dependencies fixed: `llama_cpp_dart` removed, `file_picker` added
- Noto Sans fonts added to `assets/fonts/` (Regular, Bold)
- Path resolution fixed in `utils.dart` using `path_provider`
- Drift/SQLite layer complete with tables, CRUD, first-run seeding

## Phase 1 - Visible App (dev1 branch)
**Status:** T1.8 COMPLETE

**T1.2 - Clean build verified:**
- `flutter analyze`: zero issues
- `flutter test`: 48 tests pass

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
- Updated `IlawPlanView` with complete header (School, Teacher, Learning Area, Date, Term, Sessions, Minutes, Multigrade Model)
- Added Intentions section showing shared sub-theme and objective
- Added Assessment table per grade
- Added Ways Forward table per grade
- Added Reflection Questions section

**T1.8 - Wire generator to renderer complete (enhanced):**
- Created `lib/core/providers.dart` with Riverpod providers
- Created `lib/features/generator/generation_controller.dart` with StateNotifier
- Updated `generator_screen.dart` to wire Generate to mock generation
- Enhanced FlowTable to show per-grade activity columns
- Full flow: form → GenerationRequest → stream events → IlawPlanView displays multi-column plan
- Cancel button stops generation, error handling implemented