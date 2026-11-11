# Progress

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
- Debug APK builds successfully (~88 MB).

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
- file_picker temporarily removed due to Flutter 3.47.6 / AGP 9.x compatibility issue (plugin AAR built against SDK 34).
- Will be reintroduced before T7.1 export implementation.

### T3.4 (Complete)
- Flow table grade columns use minimum 220dp width on narrow screens.
- Assessment and ways-forward tables use 220dp minimum column width on narrow screens.
- Header table stacks to two columns on screens < 600dp.
- Banners stay full width.
- Tests: no overflow at 360×640 with 2, 4, and 6 grades.
- Header table stacks to two columns on narrow screens.

---
