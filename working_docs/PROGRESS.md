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

---
