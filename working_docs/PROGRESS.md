# Progress

## Phase 0 - Repository Reconciliation (dev1)
- Dependencies fixed, Noto Sans fonts, path resolution, Drift/SQLite layer complete.

## Phase 1 - Visible App (dev1)
- Domain model, app shell/theme, generator mock, library, settings done. 49 tests pass.

## Phase 2 - starting at T2.0

### T2.0 Complete
- AGENTS.md updated with Phase 2 file reference; no flutter_hooks found.

### T2.1 Complete
- Fixed `part of` directives; `toJson`/`fromJson`; 53 tests pass.

### T2.2 Complete
- Added `competencyIndexByGrade`/`competencyIndex`; v1 JSON loads; 58 tests pass.

### T2.3 Complete
- Validation framework with stable codes; split into 7 files under 250 lines each.

### T2.4 Complete
- `replaceSection` extension for regeneration; supports full sections and grade slices.
- 72 tests pass; files: plan_section_patch.dart, plan_section_patch_test.dart.

### T2.5 Complete
- Added `generateSection` to LessonGenerator interface and MockLessonGenerator.
- Added `GenerationRequest.fromPlan` factory to build requests from existing plans.
- Mock appends "(variant N)" markers for visibility during regeneration.
- 73 tests pass.

### T2.6 Complete
- Added PlanEditorState with plan, issues, dirty, savedId, canUndo.
- PlanEditorNotifier with load, update, applyRegenerated, undo, markSaved, clear.
- History capped at 20 steps; provider uses keepAlive() to survive tab switches.
- 81 tests pass.
