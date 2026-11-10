# Progress

## Phase 0 - Repository Reconciliation (dev1)
- Dependencies fixed, fonts, path resolution, Drift/SQLite layer complete.
- Domain model, app shell/theme, generator mock, library, settings done. Tests: 108 pass.
- Header fields, objectives, materials, assessment fields, ways forward, reflection questions, notes editable.
- `plan_workspace.dart` with Save, Undo buttons and "Unsaved changes" chip.
- `validation_panel.dart` with summary and expandable issue list.
- `regenerateSection` in GenerationController, `currentLanguageProvider`, refresh icons on SectionBanners.
- `gradeLabel` param in `regenerateSection()`, refresh buttons in FlowTable, `onRegenerate` callback in Assessment/WaysForward sections.
- `ilaw_ai_scaffold.md` reference document with JSON skeleton, prompt scaffolds, validation rules, renderer spec.
- `PlanRepository.update()`, library opens in PlanWorkspace with savedId, Save/Update as Copy logic.
- Schema v3: added `gradeLevels` to PlanHeader, `language`/`preparedByRole`/`checkedByRole` to LessonPlan, `materials` as object with items/references.
- Updated SectionBanner to full-width filled bars with reference colors (navy #1F3864, green #2E6B2E, etc.), uppercase labels.
- Created `header_table.dart` with 4-column layout, title "DAILY LESSON PLAN FOR GRADE {gradeLevels}", tap-to-edit.
- Fixes: Riverpod load error, reflection questions interpolation, monograde support, validation messages, FlowTable column rendering.

## Next
- T2.15 - Migration test harness
- refactor(shell): remove Generator from nav rail, library is main entry point
- Library "New Plan" button resets generator state before navigate

---
Commit: Consolidate all progress under Phase 0 for clean dev plan redo
