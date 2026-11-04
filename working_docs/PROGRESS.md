# Progress

## Phase 0 - Repository Reconciliation (dev1)
- Dependencies fixed, Noto Sans fonts, path resolution, Drift/SQLite layer complete.

## Phase 1 - Visible App (dev1)
- Domain model, app shell/theme, generator mock, library, settings done. 49 tests pass.

## Phase 2 - starting at T2.0

### T2.0 Complete
- AGENTS.md updated with Phase 2 file reference.
- Flutter hooks: no matches found in lib/test code.
- File sizes: largest file under 250 lines (ilaw_plan_view.dart: 343 lines - UI).

### T2.1 Complete
- Fixed `part of` directive in 5 part files (plan_header.dart, grade_block.dart, flow_stage.dart, assessment.dart, ways_forward.dart)
- Fixed `toJson` to include `aiUseDeclaration`
- Fixed `fromJson` to treat missing optional lists as empty
- All 53 tests pass; `flutter analyze` shows only info-level issues
- Commit: feat(core): copyWith, plan sections and schema versioning

Next: T2.2 Model: competency references (D13)

### T2.2 Complete
- Added `competencyIndexByGrade` to FlowStage, `competencyIndex` to GradeAssessment
- Bumped `currentSchemaVersion` to 2; v1 JSON loads with empty/null defaults
- Mock populates comp indices: empty for whole-class stages, index 0 for each grade
- 58 tests pass; no issues in modified files
