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

### T2.7 Complete
- Added PlanChange typedef in plan_sections.dart; onChange param on IlawPlanView.
- Added SectionBanner widget in ilaw_plan_view.dart for I/L/A/W banners.
- Created plan_sections.dart (stub implementations) and assessment_tables.dart (working implementations).
- Updated IlawPlanView build to use SectionBanner with PlanSection enum.
- Removed unused _section helper method.
- New files: plan_sections.dart (33 lines), assessment_tables.dart (163 lines) - both under 250.
- Note: ilaw_plan_view.dart is 382 lines - needs split card to move private widget methods to section files.
- 81 tests pass.

### T2.8 Complete
- Created cell_edit_dialog.dart with showCellEditDialog function for text/numeric input.
- Modified FlowTable to accept onChange callback for cell editing.
- Added _buildCell and _editField helpers for interactive cells.
- Taps on minutes, stage name, whole-class activity, and grade activities open editable dialogs.
- Numeric input validation rejects non-integers with error message.
- 85 tests pass.
