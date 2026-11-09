# Progress

## Phase 0 - Repository Reconciliation (dev1)
- Dependencies fixed, fonts, path resolution, Drift/SQLite layer complete.

## Phase 1 - Visible App (dev1)
- Domain model, app shell/theme, generator mock, library, settings done. Tests: 93 pass.

## Phase 2 - starting at T2.0
- T2.9 Complete: header fields, objectives, materials, assessment fields, ways forward, reflection questions, notes editable. Tests: 97 pass.
- T2.10 Complete: `plan_workspace.dart` with Save, Undo buttons and "Unsaved changes" chip. Tests: 98 pass.
- T2.11 Complete: `validation_panel.dart` with summary and expandable issue list. Tests: 100 pass.
- T2.12 Complete: `regenerateSection` in GenerationController, `currentLanguageProvider`, refresh icons on SectionBanners. Tests: 103 pass.
- T2.13 Complete: `gradeLabel` param in `regenerateSection()`, refresh buttons in FlowTable (header + cells), `onRegenerate` callback in AssessmentSection/WaysForwardSection. Tests: 107 pass.
- T2.14.1 Complete: `ilaw_ai_scaffold.md` reference document created with full structure, JSON skeleton, prompt scaffolds, validation rules, and renderer spec.
- T2.14 Complete: `PlanRepository.update()`, library opens in PlanWorkspace with savedId, Save/ Update as Copy logic. Tests: 107 pass.
- T2.14.2 Complete: Added `gradeLevels` to PlanHeader, `language` and `preparedByRole`/`checkedByRole` to LessonPlan, restructured `materials` from List to Materials object with items/references. Schema version bumped to 3 with backward compatibility. Tests: 107 pass.
- T2.14.3 Complete: Updated SectionBanner to full-width filled bars with reference colors (navy #1F3864, green #2E6B2E, brown #8C5A1E, maroon #7A2048), labels changed to uppercase format ("I  INTENTIONS", "L  LEARNING EXPERIENCE", "A  ASSESSMENT", "W  WAYS FORWARD"). Added tests for banner colors and label format. Tests: 108 pass.
- T2.14.4 Complete: Created header_table.dart with 4-column table layout (School, Teacher; Grade Levels, Learning Area; Teaching Date, Term; Time/Sessions, No. of Learners; Multigrade Model spanning right columns). Added title "DAILY LESSON PLAN FOR GRADE {gradeLevels}". Labels use navy #1F3864 with white bold text. Tap-to-edit via showCellEditDialog. Tests: 108 pass.
- Fix: Riverpod error when loading generated plan - changed `build()` to use `ref.listen()` instead of modifying provider state during widget tree building.
- Fix: Reflection questions showing closure syntax - fixed string interpolation in mock generator `${_firstWord(sharedSubTheme)}`.
- Fix: Allow monograde plans (minimum 1 grade instead of 2), corrected grade removal validation.
- Fix: Corrected error message in plan_section_patch.dart validation for grade label not found.
- Fix: FlowTable L section had 2 extra columns for 2-grade plans - refresh icon columns now only render when `onRegenerate` is provided.

## Next: T2.15 - Migration test harness

- refactor(shell): remove Generator from nav rail, library is main entry point
- Library "New Plan" button (FloatingActionButton) now resets generator state before navigate
- All 107 tests pass, updated widget_test for new nav rail structure
