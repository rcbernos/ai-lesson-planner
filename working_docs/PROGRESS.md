# Progress

## Phase 4 - On-device Engine (T4.1-4.3 Complete)
### T4.1 Engine selection (Complete)
- Added `llamadart: 0.21.0` with pinned exact version to `pubspec.yaml`.
- Updated SDK constraint from `>=3.0.0 <4.0.0` to `>=3.10.0 <4.0.0` to match llamadart requirements.
- `flutter pub get` succeeded.
- `flutter build apk --debug` succeeded (~167 MB).
- Commit: `feat(core): add llamadart engine dependency`

### T4.3 LlmEngine interface and FakeEngine (Complete)
- Created `lib/core/llm/llm_engine.dart` with ChatMsg, GenParams, ModelSpec, EngineState, EngineException, and LlmEngine interface.
- Created `lib/core/llm/fake_engine.dart` with FakeEngine implementation for testing.
- Created `test/fake_engine_test.dart` with 13 tests covering lifecycle, load failure, token streaming, cancel, and serialization.
- All tests pass.
- Commit: `feat(core): LlmEngine interface and fake engine`

## Phase 0 - Repository Reconciliation (dev1)
- Dependencies fixed, fonts, path resolution, Drift/SQLite layer complete.
- Domain model, app shell/theme, generator mock, library, settings done. Tests: 117 pass (was 108).

## Phase 3 - Android Foundation
### T3.0 (Complete)
- Android SDK 36.0.0, NDK needed for Phase 4, adb v1.0.41 installed.
- Test device: V2246, ~12 GB RAM, Android 15, arm64-v8a.

### T3.1 (Complete)
- Added Android platform with applicationId: `ph.lms.lessonplanner`.
- minSdk 24, targetSdk 36, compileSdk 36, arm64-v8a only.
- INTERNET permission only, largeHeap disabled, no storage permissions.
- Debug APK builds successfully (~167 MB).

### T3.2 (Complete)
- Adaptive shell: NavigationBar (bottom) for screens < 600dp, NavigationRail (side) for ≥ 600dp.
- Tests added for both modes at 360×640 and 1024×600.
- Navigation works correctly between Library, Assistant, Settings screens.

### T3.3 (Complete)
- GeneratorScreen: responsive layout, resizeToAvoidBottomInset, no fixed width.
- GradeInputCard: supports collapsed/expanded mode via isExpanded parameter.
- Added copyWith to GradeInput for partial updates.
- Widget tests verify no overflow at 360×640; Generate button reachable.
### Notes
- file_picker resolution: Updated to ^12.0.0. Debug APK builds successfully (~167 MB). Android compatibility issue resolved.

### T3.4 (Complete)
- Flow table grade columns use minimum 220dp width on narrow screens.
- Assessment and ways-forward tables use 220dp minimum column width on narrow screens.
- Header table stacks to two columns on screens < 600dp.
- Banners stay full width.
- Tests: no overflow at 360×640 with 2, 4, and 6 grades.
- Header table stacks to two columns on narrow screens.

### T3.5 (Complete)
- Created `GradeSelectorNotifier` (Riverpod StateNotifier) with `gradeSelectorProvider`.
- `GradeSelectorChip` widget: "All Grades" + individual grade chips in Wrap layout.
- `effectiveGrade()` normalizes selections to valid plan grades.
- `ilaw_plan_view.dart` uses chip, filters `visibleGrades`, assessments, ways forward.
- Tests: 5 widget tests (selection, deselect, invalid grade, 6 grades at 360dp).
- All tests passing.

### T3.6 (Complete)
- Fixed form validation block on Android: all Grade Input fields (Label, Male/Female counts, Sub-theme, Competency) are now always visible regardless of isExpanded state.
- Removed conditional rendering of Grade Label, Male, Female, and Competency fields that were hidden when isExpanded=false.
- Layout handles increased horizontal space with Expanded widgets and horizontal scrolling.
- Validation now works correctly - Generate button enables when required fields are populated.
- Commit: `fix(generator): make all grade input fields always visible`

### T3.7 (Complete)
- Fixed horizontal text alignment in Assessment and Ways Forward tables.
- Removed `Center` widget wrapper from `AssessmentTables` and `WaysForwardTables` that was causing text to be left-aligned within the horizontal scroll container.
- Both widgets now return `SingleChildScrollView` with `table` directly as child, matching the behavior of `FlowTable` for the Learning Experience section.
- All `Text` widgets in both tables already have `textAlign: TextAlign.center` explicitly set.
- Commit: `fix(plan_view): center text in Assessment and Ways Forward tables`

### T3.9 (Complete)
- Fixed horizontal centering of Assessment and Ways Forward tables in landscape mode (1280x720, 1024x600).
- Root cause: On landscape screens, the widgets returned `Column` directly without wrapping in `Center`, causing the table to be left-aligned within the parent scroll view.
- **Resolution**: On wide screens (`!isNarrow`), both widgets now wrap the `Column` in a `Center` widget to horizontally center the table within the parent scroll view.
- On narrow screens, both widgets wrap in `SingleChildScrollView` → `Column(crossAxisAlignment.center)` → `table`.
- All text cells in tables have `textAlign: TextAlign.center` for consistency.
- Commit: `fix(plan_view): center Assessment and Ways Forward tables in landscape mode`

### T3.8 (Complete)
- Fixed horizontal centering for all ILAW table sections (Learning Experience, Assessment, Ways Forward) in landscape mode.
- Root cause: Double-wrapping content in nested `SingleChildScrollView` widgets prevented the parent's horizontal scroll view from centering the table.
- **Resolution**: Removed the inner `SingleChildScrollView` wrapper when `!isNarrow` (landscape/wide screens). On wide screens, only the `Column(crossAxisAlignment: CrossAxisAlignment.center)` wrapper remains, allowing the parent scroll view in `IlawPlanView` to naturally center the content.
- Both `AssessmentTables` and `WaysForwardTables` now:
  - On narrow screens (`width < 600dp`): Wrap in `SingleChildScrollView` → `Column(crossAxisAlignment.center)` → `table`
  - On wide screens: Return `Column(crossAxisAlignment.center)` → `table` directly
- Commit: `fix(plan_view): center tables in landscape by removing redundant inner scroll view`

### T4.5 LocalLlamaEngine (Complete)
- Fixed `GenerationParams`: changed `temperature` to `temp`, added `stopSequences` and `seed` parameters for llamadart 0.21.0 API compatibility.
- Fixed cancellation handling: replaced invalid `controller.onCancel()` with proper subscription tracking via `_currentSubscription` field.
- Fixed `dispose()` method: unload before closing state controller to avoid "Cannot add new events after calling close" error.
- All tests pass: 4 local_llama_engine tests pass (2 skipped for integration tests gated by LMS_TEST_GGUF).
- Commit: `feat(core): implement LocalLlamaEngine with llamadart 0.21.0 API`

### T4.5b Throwaway LLM Debug Screen (Complete)
- Created `lib/features/debug/llm_debug_screen.dart` - debug screen with model load/generate/cancel UI
- Created `lib/core/llm/model_paths.dart` - utility class for checking model file existence and size
- Created `test/llm_debug_screen_test.dart` - widget tests for responsive layout (360x640, 1024x600)
- Added debug link in Settings screen (only visible in kDebugMode) via bolt icon
- All tests pass, flutter analyze clean
- Commit: `feat(prototype): throwaway LLM debug screen`

### T4.5c Model installed check (Complete)
- Updated `model_paths.dart` to use `getExternalStorageDirectory()` on Android (matches `getExternalFilesDir(null)`)
- Added fallback to `getApplicationSupportDirectory()` on non-Android platforms (Linux tests)
- Updated debug screen to show "No model found. Import via file_picker." when model is missing
- Widget tests updated and passing

### T4.6 Model manifest (Complete)
- Created `lib/services/llm/model_manifest.dart` with ModelManifest class
- Added `assets/models.json` with default model info: `{ "version": "1", "model": "qwen4b-sea-lion-q4_k_m.gguf" }`
- Implemented `load()`, `loadFromFile()`, `save()`, `isCurrentModelAvailable()` methods
- Added `getExternalFilesDir()` helper for Android file access
- Created `test/model_manifest_test.dart` with 11 tests for serialization, equality, and defaults
- All tests pass, flutter analyze clean
- Debug APK builds successfully (~167 MB)

### T4.7 Model downloader (Complete)
- Created `lib/services/llm/model_downloader.dart` with ModelDownloader class
- Created `lib/features/debug/download_dialog.dart` with DownloadProgressDialog widget
- Created `test/model_downloader_test.dart` with 9 tests for DownloadProgress, SHA-256, percentage, URL generation
- Implements streaming download with progress tracking via DownloadProgress class
- SHA-256 checksum verification support (placeholder checksum for prototype)
- Saves model to app-private storage via getExternalStorageDirectory()
- Updates models.json manifest after successful download
- Added "Download Model" button to llm_debug_screen.dart
- All tests pass, flutter analyze clean
- Debug APK builds successfully (~167 MB)

### T4.9 Import model file (Complete)
- Added `_importModel()` method to llm_debug_screen.dart using file_picker (v12.0.0)
- Added "Import Model File" button to debug screen UI
- Validates .gguf extension and file size (> 100 MB)
- Copies selected file to app-private storage
- Shows progress dialog during import
- Widget tests updated to verify button presence
- All tests pass, flutter analyze clean
- Commit: `feat(prototype): model import button`

## Phase 5 - AI Generation

### T5.6 LlmLessonGenerator: Intentions and Learning Experience (Complete)
- Fixed `replaceSection` calls to use positional arguments instead of named `section` parameter.
- Fixed `buildSystemBlock` and prompt functions to accept `OutputLanguage` enum and `List<String>` grade labels.
- Fixed `_streamTokens` to use local subscription variable for proper cancellation.
- Removed unused `_tokenSub` field and `_emitSectionPlan` method.
- Added missing import for `dart:async` in `llm_lesson_generator.dart`.
- Fixed `section_runner.dart`: corrected type mismatch in `gradeLabels` parameter (String vs List<String>).
- Created `test/llm_generator_test.dart` with basic tests for cancel and header section generation.
- All tests pass, flutter analyze clean.
- Commit: `feat(core): LLM generator for intentions and learning experience`

### T5.7 LlmLessonGenerator: Assessment, Ways Forward, generateSection (Complete)
- Added `replaceSection` method to LessonPlan for per-section replacement with gradeLabel support.
- Fixed `_buildCompletePlan` to merge with existing `_lastPlan` instead of rebuilding intentions.
- Added `_mergeLearningExperience` method to properly merge flow, assessments, ways forward onto existing plan.
- Removed premature `GenerationCompleted` yields after each section in `generate()`.
- Added `GenerationCompleted` to `_regenerateAssessment` and `_regenerateWaysForward` methods.
- Fixed cancel test to use controlled token delays instead of racey sleep.
- All 6 tests in test/llm_generator_test.dart pass: cancel(), per-grade regeneration, full plan generation, validation retry.

## Phase 6 - Chat Session Management (T6.1 Complete)

### T6.2 Conversational Slot Filling (Complete)
- Created `lib/core/chat/slot_filler.dart`: extracts fields from chat using LlmEngine
  - `SlotFiller.processMessage()`: sends user message to LLM for slot extraction
  - `applyPatchToSession()`: merges extracted fields into chat session
  - `getNextMissingField()`: identifies next required field for conversation flow
  - `_validatePatch()`: validates extracted values against SlotSchema
- Created `lib/core/chat/slot_schema.dart`: defines extractable fields and validation rules
  - `SlotSchema.isValidGradeLabel()`: validates formats like "Grade 3"
  - `SlotSchema.isValidSessionMinutes()`: validates 60/90/120 minute sessions
  - `SlotSchema.isValidGradeCount()`: validates 2-6 grades
- Created `test/slot_filler_test.dart` with 18 tests covering extraction, validation, and edge cases
- All tests pass, flutter analyze clean
- Commit: `feat(core): conversational slot filling for chat assistant`

### T6.1 Chat session model and storage layer (Complete)
- Created `lib/core/chat/chat_session.dart` with ChatMessage and ChatSession classes.
- ChatSession includes: id, created, messages, header, grades, sharedSubTheme, multigradeModel, outputLanguage.
- Added canGenerate getter to check if session has all required fields.
- Added toGenerationRequest() to build GenerationRequest from session.
- Added addMessage() with 12-message cap for prompt budget.
- Added toJson()/fromJson() for JSON serialization.
- Updated `lib/models/database/tables.dart`: added ChatSessions table with all draft fields.
- Updated `lib/services/database/app_database.dart`: bumped schemaVersion to 2, added onUpgrade migration.
- Created `lib/services/database/chat_repository.dart` with CRUD operations: save, getAll, getById, delete, clearAll.
- Created `test/chat_repository_test.dart` with 6 tests covering model validation, JSON round-trip, and repository CRUD.
- All tests pass, flutter analyze clean (only pre-existing deprecation warnings).
- Commit: `feat(chat): chat session model and storage for slot-filling assistant`
