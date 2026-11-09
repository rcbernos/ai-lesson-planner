# Phase 2: Solid Plan Model (still stubbed AI)

**Goal:** a plan can be created, edited, validated, saved, reopened and re-saved, with references. Sections and single grade cells can be regenerated (by the mock). Old Phase 1 saves still open after the database migration. No LLM in this phase.

**Branch:** `dev1`

Each card is one agent session. Do the cards in order. Cards marked **(strong model)** are better done with the stronger hosted model than the local 9B.

**Rules that apply to every card** (also in `AGENTS.md`):
- Max 3 files per card, not counting generated files (`*.g.dart`, Drift schema dumps and generated migration helpers). If more are needed, stop and say so.
- Keep files under about 250 lines. If a card would push a file over, stop and say so. The human will insert a split card.
- Never commit. Print the card's commit message at the end; the human commits.
- Never write curriculum content (competency text, standards, references). Fixtures use fictional names.
- No new dependencies.

**Decisions this phase relies on:**
- **D13** Competency references are zero-based indexes into that grade's `competencies` list.
- **D14** Validation never blocks saving. It only blocks export (Phase 5), with an override.
- **D15** Generated files don't count toward the 3-file limit. The agent never commits.
- **D16** Settings persist in Drift.

---

## Pre-flight (human, not the agent)
- Make sure Phase 1 is merged into `main` and `dev1` is checked out.
- **Back up your Phase 1 database file** (copy it somewhere outside the repo). You will use it to test the migration in T2.16 and in the acceptance test.
- Prepare `assets/seed/competencies.json` by hand from the anonymized sample DLPs, before T2.18. Format: `[{"grade": "Grade 3", "learningArea": "Science", "text": "..."}]`. Add `"code"` only when a source document actually has one. The agent must not write these.
- Do Spike S from the master plan (about 1 hour) at any point in this phase. Record the numbers in `PROGRESS.md`. It gates Phase 3.
- Pick one card (T2.3 or T2.8 suit it) to run end to end with the local Qwen 9B, then note in `PROGRESS.md` how far the 48k context filled and whether it lost track of the interface.

---

## Group A: Housekeeping

## T2.0 Close out Phase 1, refresh the agent files
**Files:** `AGENTS.md`, `working_docs/PROGRESS.md`, `pubspec.yaml`.
**Do:**
1. In `AGENTS.md`: set **Current Phase File** to `working_docs/phase2_tasks.md`. Fix the commit contradiction: replace step 4 with "Print the card's commit message and add 2 to 5 lines to `PROGRESS.md`. Do not commit; the human commits." Add the line "Generated files (`*.g.dart`, Drift schema dumps) don't count toward the 3-file limit." Add the line "Seed data and curriculum text come from the human only."
2. Rewrite `PROGRESS.md` to under 30 lines: Phase 0 and Phase 1 collapsed to about 3 lines each (what exists, 49 tests, branch `dev1`), then "Phase 2: starting at T2.0". Keep the `Next:` line.
3. Run `grep -rn "flutter_hooks" lib test`. If nothing matches, remove `flutter_hooks` from `pubspec.yaml` and run `flutter pub get`. If something matches, leave it and say so in `PROGRESS.md`.
4. Report (do not fix) every Dart file over 250 lines: `find lib test -name '*.dart' ! -name '*.g.dart' | xargs wc -l | sort -n | tail -15`. Paste the output into the reply so the human can add split cards.
**Verify:** `AGENTS.md` names the phase 2 file, `PROGRESS.md` is under 30 lines, `flutter analyze` clean, `flutter test` passes.
**Commit:** `chore: close out phase 1 and refresh agent files for phase 2`

---

## Group B: Model and rules (pure Dart, no UI)

## T2.1 Model: copyWith, schema version, tolerant reading
**Files:** `lib/core/models/lesson_plan.dart`, `test/lesson_plan_test.dart`, `test/fixtures/sample_plan.dart` (only if needed).
**First:** if `lesson_plan.dart` is over 230 lines, stop and say so (the human will add a split card).
**Do:**
1. Add `copyWith` to all 7 classes (named, all optional). For `ReflectionQuestion`, add a `bool clearGradeLabel = false` parameter so the nullable `gradeLabel` can be set back to null.
2. Add `enum PlanSection { header, intentions, learningExperiences, assessment, waysForward }` with a getter `eventName` that returns exactly the section names `MockLessonGenerator` already emits in `SectionStarted` (check the mock; `header` returns `''`).
3. Add `static const int currentSchemaVersion = 1;` to `LessonPlan`. `toJson` writes `"schemaVersion"`. `fromJson` treats a missing `schemaVersion` as 1, treats missing optional lists as empty, and throws `PlanVersionException` (new small class in the same file) if the version is greater than `currentSchemaVersion`.
**Verify test:** round-trip still equals the original; `copyWith` changes only the named field; a JSON string saved by Phase 1 (no `schemaVersion`) still loads; a JSON with `schemaVersion: 99` throws `PlanVersionException`.
**Commit:** `feat(core): copyWith, plan sections and schema versioning`

## T2.2 Model: competency references (D13)
**Files:** `lib/core/models/lesson_plan.dart`, `lib/core/generation/mock_lesson_generator.dart`, `test/mock_generator_test.dart`.
**Interface changes (both optional so old saves load):**
```dart
class FlowStage {
  // existing fields...
  Map<String,int> competencyIndexByGrade; // grade label -> index into that grade's competencies. Empty for whole-class stages.
}
class GradeAssessment {
  // existing fields...
  int? competencyIndex; // index into this grade's competencies, or null
}
```
**Do:**
1. Add the fields, `toJson` / `fromJson` (missing means empty map / null) and `copyWith`.
2. Set `currentSchemaVersion = 2`. Version 1 JSON must still load.
3. `MockLessonGenerator` fills `competencyIndexByGrade` for every non-whole-class stage (index 0 for each grade) and `competencyIndex = 0` for each assessment.
**Verify test:** a mock plan has every index within range for its grade; a version 1 JSON loads with empty maps and null indexes; the JSON round-trip still equals the original.
**Commit:** `feat(core): competency references on flow stages and assessments`

## T2.3 PlanValidator **(good local-9B stress test)**
**Files:** `lib/core/validation/validation_issue.dart`, `lib/core/validation/plan_validator.dart`, `test/plan_validator_test.dart`.
**Interface (pure Dart, no Flutter imports):**
```dart
enum IssueSeverity { error, warning }

class ValidationIssue {
  final String code;          // stable id, e.g. 'flow.minutes_sum'
  final IssueSeverity severity;
  final PlanSection section;
  final String path;          // e.g. 'flow[2].activityByGrade[Grade 3]'
  final String message;       // plain English, safe to paste into an LLM retry prompt
}

class PlanValidator {
  List<ValidationIssue> validate(LessonPlan plan);
  List<ValidationIssue> validateSection(LessonPlan plan, PlanSection section);
}
```
Define `const minGrades = 2; const maxGrades = 6;` at the top of `plan_validator.dart`.
**Rules (code → severity):**
- `header.required` (error): `school`, `teacher`, `learningArea`, `date`, `term` blank; `sessions < 1`; `sessionMinutes <= 0`.
- `grades.count` (error): fewer than `minGrades` or more than `maxGrades`.
- `grades.duplicate_label` (error).
- `grades.learners` (error if a count is negative, warning if male + female is 0).
- `intentions.no_competency` (error): a grade has no competencies.
- `intentions.no_objective` (warning): a grade has no objectives.
- `flow.empty` (error), `flow.stage_minutes` (error: a stage has minutes ≤ 0).
- `flow.minutes_sum` (error): stage minutes don't add up to `sessionMinutes`. Message includes both numbers, e.g. "The lesson flow adds up to 85 minutes but the session is 90 minutes."
- `flow.missing_grade_activity` (error): a non-whole-class stage lacks a non-blank activity for some grade. One issue per stage and grade.
- `flow.missing_whole_class` (error): a whole-class stage has a blank `wholeClassActivity`.
- `competency.index_out_of_range` (error) for flow stages and assessments; `competency.missing_ref` (warning) when a non-whole-class stage has no reference for a grade.
- `assessment.missing_grade` (error): a grade has no `GradeAssessment` or a blank `formative`; blank `exitTask` is a warning.
- `ways_forward.missing_grade` (error): a grade has no entry; blank remediation or enrichment is a warning.
- `reflection.empty` (warning), `declaration.missing` (warning: blank `aiUseDeclaration`).
`validateSection` returns only the issues whose `section` matches. Map: header and grade rules → `header`; competency and objective rules → `intentions`; flow and competency refs on stages → `learningExperiences`; assessment rules → `assessment`; ways forward and reflection rules → `waysForward`.
**Verify test:** the fixture and a mock plan both give zero errors. For each rule code, one test mutates a valid plan with `copyWith` and expects exactly that code at the expected path. `validateSection` filters correctly.
**Commit:** `feat(core): plan validator with stable issue codes`

## T2.4 Section patching
**Files:** `lib/core/models/plan_section_patch.dart` (new), `test/plan_section_patch_test.dart`.
**Interface:**
```dart
extension PlanSectionPatch on LessonPlan {
  /// Returns a copy of this plan with the given section (or one grade's slice of it) taken from [source].
  /// Throws ArgumentError if [gradeLabel] is not a grade in this plan, or if a cell-level patch
  /// finds a different number of flow stages in [source].
  LessonPlan replaceSection(PlanSection section, LessonPlan source, {String? gradeLabel});
}
```
**What each section replaces (everything else is kept from `this`):**
- `header`: nothing (returns `this`). Header is teacher input.
- `intentions`: each grade's `objectives`, and `bothGradesObjective`. **Never** standards, competencies, `sharedSubTheme` or learner counts (H1). With `gradeLabel`: only that grade's `objectives`.
- `learningExperiences`: `learnerContext`, `materials`, `flow`. With `gradeLabel`: for each stage (matched by position), only that grade's entries in `activityByGrade` and `competencyIndexByGrade`; stage minutes and whole-class text stay.
- `assessment`: `assessments`. With `gradeLabel`: that grade's `GradeAssessment`.
- `waysForward`: `waysForward`, `reflectionQuestions`, `notesNextSession`. With `gradeLabel`: that grade's `GradeWaysForward` and that grade's reflection questions.
**Verify test:** after every call, header, standards, competencies, sub-theme and learner counts are unchanged. A cell-level patch leaves the other grades and the flow minutes untouched. Patching with an unknown grade label throws.
**Commit:** `feat(core): replace one plan section or grade slice from another plan`

## T2.5 generateSection on the generator interface
**Files:** `lib/core/generation/lesson_generator.dart`, `lib/core/generation/mock_lesson_generator.dart`, `test/mock_generator_test.dart`.
**Interface additions:**
```dart
abstract class LessonGenerator {
  // existing generate(...) and cancel() stay as they are
  Stream<GenerationEvent> generateSection(
    GenerationRequest request,
    PlanSection section,
    LessonPlan current, {
    String? gradeLabel,
  });
}

// on GenerationRequest:
factory GenerationRequest.fromPlan(LessonPlan plan, OutputLanguage language);
// builds the request from plan.header and plan.grades; GradeInput.competency = competencies joined with '; '.
```
**Do:** `generateSection` emits `SectionStarted`, a few `TokenDelta`, `SectionCompleted`, then `GenerationCompleted(plan)` where `plan = current.replaceSection(section, freshPlan, gradeLabel: gradeLabel)` and `freshPlan` is what the mock would generate for the request. So Phase 3 can implement the same method with the real model. `cancel()` stops it. The mock appends a visible marker such as "(variant 2)" to generated activity text, using a per-instance counter, so regeneration is visible when testing by hand.
**Verify test:** events arrive in order; the result keeps the plan's standards and competencies; with `gradeLabel`, only that grade's slice differs; `cancel()` stops the stream; the existing `generate` tests still pass.
**Commit:** `feat(core): generateSection on LessonGenerator with mock implementation`

---

## Group C: Editing (UI)

## T2.6 Plan editor state
**Files:** `lib/features/plan_editor/plan_editor_state.dart` (new), `lib/core/providers.dart`, `test/plan_editor_state_test.dart`.
**Interface:**
```dart
class PlanEditorState {
  final LessonPlan plan;
  final List<ValidationIssue> issues;
  final bool dirty;
  final int? savedId;     // Drift row id once saved
  final bool canUndo;
}

class PlanEditorNotifier extends StateNotifier<PlanEditorState?> {
  void load(LessonPlan plan, {int? savedId});               // dirty = false, clears history
  void update(LessonPlan Function(LessonPlan) change);      // push history, run validator, dirty = true
  void applyRegenerated(LessonPlan plan);                   // same as update, one undo step
  void undo();                                              // history keeps the last 20 steps
  void markSaved(int id);                                   // dirty = false, sets savedId
  void clear();
}
```
Add `planEditorProvider` to `providers.dart`. The provider must **not** auto-dispose, so edits survive tab switches.
**Verify test:** `update` runs the validator and sets `dirty`; `undo` restores the previous plan; history is capped at 20; `markSaved` clears `dirty`; `load` resets history.
**Commit:** `feat(ui): plan editor state with undo and live validation`

## T2.7 Split the plan view and add an edit hook (refactor, no behavior change)
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`, `lib/features/plan_view/plan_sections.dart` (new), `lib/features/plan_view/assessment_tables.dart` (new).
**Do:**
1. Move the header table, Intentions content, learner context and materials widgets to `plan_sections.dart`. Move the Assessment table, Ways Forward table, reflection questions and footer to `assessment_tables.dart`. `flow_table.dart` stays where it is.
2. `IlawPlanView` composes them. **The I / L / A / W banner rows are built only in `IlawPlanView`**, through a small `SectionBanner(PlanSection section, {List<Widget> actions = const []})` widget in the same file (later cards add buttons through `actions`).
3. Add `typedef PlanChange = void Function(LessonPlan Function(LessonPlan));` and an optional `PlanChange? onChange` parameter on `IlawPlanView`. Pass it down to the section widgets, but nothing uses it yet. `null` means read-only.
**Verify:** all existing plan view tests pass unchanged; each new file is under 250 lines.
**Commit:** `refactor(ui): split plan view into section widgets`

## T2.8 Edit flow table cells
**Files:** `lib/features/plan_view/cell_edit_dialog.dart` (new), `lib/features/plan_view/flow_table.dart`, `test/flow_table_edit_test.dart`.
**Interface:**
```dart
Future<String?> showCellEditDialog(
  BuildContext context, {
  required String title,
  required String initial,
  int maxLines = 6,
  bool numeric = false,
}); // returns null if cancelled
```
**Do:** when `onChange != null`, tapping a flow cell opens the dialog: stage name, minutes (numeric; reject non-integers), whole-class activity, and each grade's activity. A confirmed edit calls `onChange` with a `copyWith` of the plan. Editable cells show a subtle hover or pencil hint. Read-only mode behaves exactly as before. Out of scope: adding or removing stages.
**Verify test:** tapping a grade cell, entering text and confirming calls `onChange` and the new text appears; cancelling changes nothing; entering `abc` in the minutes dialog is rejected.
**Commit:** `feat(ui): edit flow table cells`

## T2.9 Edit the other sections
**Files:** `lib/features/plan_view/plan_sections.dart`, `lib/features/plan_view/assessment_tables.dart`, `test/plan_sections_edit_test.dart`.
**Do:** reuse `showCellEditDialog`. Make these editable when `onChange != null`: header fields, each grade's objectives, `bothGradesObjective`, `learnerContext`, `materials`, each grade's assessment fields, each grade's ways forward, reflection questions, `notesNextSession`, `preparedBy`, `checkedBy`. **Lists (objectives, materials, reflection questions) are edited as multi-line text, one item per line**; blank lines are dropped on save. Standards and competencies are shown read-only (they come from the form).
**Verify test:** editing an objective list with three lines gives three items; editing one grade's formative assessment leaves the other grade untouched; read-only mode shows no edit hints.
**Commit:** `feat(ui): edit intentions, assessment and ways forward`

## T2.10 Wire the editor to the generator screen
**Files:** `lib/features/generator/generator_screen.dart`, `lib/features/plan_view/plan_workspace.dart` (new), `test/plan_workspace_test.dart`.
**Do:**
1. Create `PlanWorkspace` (reads `planEditorProvider`): a Save button, an "Unsaved changes" chip when `dirty`, an Undo button (enabled by `canUndo`), and the `IlawPlanView` with `onChange` bound to the notifier's `update`.
2. In `generator_screen.dart`, when generation completes, call `load(plan)` and show `PlanWorkspace` instead of the bare view. Keep the existing Save behavior working (it will be reworked in T2.14).
**Verify test:** editing a cell sets the dirty chip; Undo restores the text. By hand: edit, switch to Settings and back, edits are still there.
**Commit:** `feat(ui): plan workspace with editable plan view`

## T2.11 Validation panel
**Files:** `lib/features/plan_view/validation_panel.dart` (new), `lib/features/plan_view/plan_workspace.dart`, `test/validation_panel_test.dart`.
**Do:** a collapsible card at the top of `PlanWorkspace`: a summary such as "2 errors, 3 warnings" (green "No problems found" when empty), expandable to a list of issue messages grouped by section. Turn each `path` into a readable label (for example `flow[2].activityByGrade[Grade 3]` becomes "Flow of the lesson, stage 3, Grade 3"). The panel updates live from `planEditorProvider`. Saving is never blocked (D14); when errors exist, the save confirmation says "Saved with 2 errors".
**Verify test:** changing a stage's minutes so the total is wrong shows the `flow.minutes_sum` message; fixing it clears the message.
**Commit:** `feat(ui): live validation panel`

## T2.12 Regenerate a section
**Files:** `lib/features/generator/generation_controller.dart`, `lib/features/plan_view/ilaw_plan_view.dart`, `test/regenerate_section_test.dart`.
**Do:** add `regenerateSection(PlanSection section)` to the controller. It builds `GenerationRequest.fromPlan(editor.plan, currentLanguage)`, calls `generator.generateSection`, shows progress, and on `GenerationCompleted` calls `applyRegenerated` (one undo step). Add a refresh icon through `SectionBanner.actions` for I, L, A and W (not the header). A confirmation dialog says "This replaces your edits in this section." Only enabled when `onChange != null`. Failure shows a snackbar and leaves the plan unchanged.
**Verify test:** pressing regenerate on Assessment changes the assessments, leaves the flow untouched, and Undo restores the old assessments.
**Commit:** `feat(ui): regenerate a plan section`

## T2.13 Regenerate one grade's cell
**Files:** `lib/features/plan_view/flow_table.dart`, `lib/features/plan_view/assessment_tables.dart`, `test/regenerate_cell_test.dart`.
**Do:** add a small "regenerate" icon button on each grade's cell group: that grade's column in the flow table, and that grade's row in the Assessment and Ways Forward tables. It calls the controller's `regenerateSection(section, gradeLabel: ...)` (extend the controller method with the optional parameter; if this needs a third controller edit and a fourth file, stop and say so). Same confirmation as T2.12.
**Verify test:** regenerating Grade 4's flow column changes only Grade 4's activities; Grade 3's text and the stage minutes are unchanged.
**Commit:** `feat(ui): regenerate a single grade's cells`

## T2.14 Open, edit and re-save library plans
**Files:** `lib/features/library/library_screen.dart`, `lib/services/database/plan_repository.dart`, `lib/features/plan_view/plan_workspace.dart`.
**Do:**
1. `PlanRepository.update(int id, LessonPlan plan)` rewrites `ilawContent` and keeps `title`, `gradeLevel`, `subject` and `updatedAt` in step with the plan (use the same title rule T1.9 used). Keep `save` for new plans. Add a test in the existing database test file only if it stays within 3 files; otherwise note it for T2.22.
2. Library "Open" loads the plan into `planEditorProvider` with its `savedId` and pushes a full-screen route that hosts `PlanWorkspace`.
3. `PlanWorkspace` Save: `update` when `savedId != null`, else insert and `markSaved(id)`. Add "Save as copy" (always inserts a new row and switches to it).
**Verify:** by hand: open a saved plan, edit a cell, Save, quit, relaunch, the edit is there; "Save as copy" gives two library rows; the library list shows the updated title or date.
**Commit:** `feat(ui): edit and re-save plans from the library`

## T2.14.1 Create reference scaffold document
**Files:** `working_docs/ilaw_ai_scaffold.md` (new)
**Do:** Create the scaffold file as a reference document for future agents. Include:
- Document anatomy (title, header table, banners I/L/A/W, sections)
- JSON skeleton with all required fields matching reference format
- Prompt scaffolds for LLM generation (shared system block, per-section prompts)
- Validation rules (V1-V13 for flow, grades, assessments, etc.)
- Renderer spec with colors (#1F3864 navy, #2E6B2E green, #8C5A1E brown, #7A2048 maroon) and layout specs
The scaffold captures the expected ILAW DLP structure so UI/LLM work stays aligned.
**Verify:** File exists with complete structure documentation matching reference format.
**Commit:** `docs: add ilaw_ai_scaffold.md reference document`

## T2.14.2 Update model with missing ILAW fields
**Files:** `lib/core/models/lesson_plan.dart`, `lib/core/models/plan_header.dart`, `test/fixtures/sample_plan.dart`
**Do:** Add fields to match reference JSON skeleton:
- Add `gradeLevels` field to `PlanHeader` (e.g., "III & IV", roman numerals)
- Add `language` field to `LessonPlan` ("fil", "en", or "mixed")
- Restructure `materials` from `List<String>` to object with `items` and `references`
- Add `preparedByRole` and `checkedByRole` fields to `LessonPlan`
- Bump `currentSchemaVersion` to 3; update `fromJson` with defaults for older saves
**Verify:** model compiles, all tests pass, schema version incremented.
**Commit:** `feat(model): add missing ILAW fields for reference alignment`

## T2.14.3 Fix banner layout and colors
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`
**Do:** Update `SectionBanner` widget to match reference:
- Change from colored dot to full-width filled bar background
- Colors: I=navy #1F3864, L=green #2E6B2E, A=brown #8C5A1E, W=maroon #7A2048
- Banner text: "I  INTENTIONS", "L  LEARNING EXPERIENCE" (singular, two spaces)
**Verify:** banners render as filled bars with correct reference colors.
**Commit:** `feat(ui): fix section banners to match reference format`

## T2.14.4 Redesign header and add title
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`
**Do:**
- Add title "DAILY LESSON PLAN FOR GRADE {gradeLevels}" centered above all
- Reorganize header to 4-column label/value table matching reference
- Include all 9 fields: School, Teacher, Learning Area, Date, Term, Sessions, Session Minutes, Multigrade Model, Grade Levels, No. of Learners
- Format learner count as: "Gr.3: 6  │  Gr.4: 1 (M-3, F-3) (M-1, F-0)"
**Verify:** header matches reference 4-column table with title line above.
**Commit:** `feat(ui): redesign header as 4-column table with title`

## T2.14.5 Restructure Intentions section
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`
**Do:** Redesign `_intentionsSection` to match reference:
- Per-grade subTheme line (bold, tagged "(Grade N)")
- Standards table with blank corner, grades as columns, rows for Content/Performance Standard
- Competencies as bullet list, tagged [Grade N]
- Objectives as bullet list, tagged [Grade N] then [Both Grades]
**Verify:** intentions section matches reference layout with per-grade breakdown.
**Commit:** `feat(ui): restructure intentions section for reference alignment`

## T2.14.6 Add Learning Experience materials
**Files:** `lib/features/plan_view/illaw_plan_view.dart`, `lib/core/models/lesson_plan.dart`
**Do:** Add to Learning Experience section (L banner):
- Learner Context paragraph (1-2 paragraphs)
- Materials (Mga Kagamitan) list from `materials.items`
- References (Mga Sanggunian) list from `materials.references`
- Keep Flow Table (but fix whole-class rendering in T2.14.7)
**Verify:** learning experience shows all three components: context, materials/references, flow.
**Commit:** `feat(ui): add learner context and materials to learning experience`

## T2.14.7 Fix Flow Table, Assessment and Ways Forward tables
**Files:** `lib/features/plan_view/flow_table.dart`, `lib/features/plan_view/ilaw_plan_view.dart`
**Do:** 
- FlowTable: Remove extra "Whole Class" icon column; time display format "5 min"; merge whole-class cells across grades
- Assessment: Transpose table (grades as columns, rows Formative/Exit Task/Success Criteria)
- Ways Forward: Move Reflection Questions before table; transpose (grades as columns, rows Remediation/Enrichment)
**Verify:** tables match reference orientation with grades in columns
**Commit:** `feat(ui): transpose assessment and ways forward tables, fix flow table`

## T2.14.8 Add Notes rendering and fix Signatures
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`
**Do:**
- Add NotesSection to IlawPlanView (was existing widget but not rendered)
- Fix Signatures: two side-by-side blocks, name in caps, role displayed beneath, Remove aiUseDeclaration from view
**Verify:** notes section visible, signatures match reference layout
**Commit:** `feat(ui): render notes section, fix signature layout`

## T2.14.9 Code cleanup and consolidation
**Files:** `lib/features/plan_view/flow_table.dart`, `lib/features/plan_view/plan_sections.dart`, `lib/features/plan_view/cell_edit_dialog.dart`
**Do:**
- Remove duplicate `RegenCallback` typedef (keep in plan_sections.dart, export from there)
- Fix `cell_edit_dialog.dart` numeric error not showing: wrap in `StatefulBuilder`
- Consolidate IlawPlanView to use plan_sections.dart widgets (HeaderSection, IntentionsSection, AssessmentsSection, WaysForwardSection, FooterSection) where onChange is null (read-only rendering)
**Verify:** no compilation errors, duplicate typedef removed, dialog error displays correctly
**Commit:** `refactor(ui): consolidate widgets and fix cell edit dialog`

### Checkpoint: stop here and test by hand
Generate a 2-grade plan, break the minutes, see the error, fix it, regenerate a section and a cell, undo, save, reopen from the library, edit and save again. Fix any bugs as separate `fix:` commits before starting Group D.

---

## Group D: Database and migrations

## T2.16 Migration test harness **(strong model)**
**Files:** `test/database/migration_test.dart` (new). Generated and exempt: `drift_schemas/drift_schema_v1.json`, `test/generated_migrations/`.
**Do:**
1. Check the current `schemaVersion` in `app_database.dart` (expected 1). Do not change the schema in this card.
2. Dump the current schema: `dart run drift_dev schema dump lib/services/database/app_database.dart drift_schemas/`.
3. Generate the test helpers: `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`.
4. Write a test following Drift's "Testing migrations" guide, using the `SchemaVerifier` API that matches the installed `drift_dev` version (check the installed version's docs; the import path has changed between versions). Test: create a v1 database, insert a `LessonPlans` row with raw SQL, open it with the current `AppDatabase`, and check the row is still there and seeding doesn't duplicate or crash.
**Verify:** `flutter test test/database/migration_test.dart` passes; `drift_schemas/` is committed.
**Commit:** `test(db): migration test harness with v1 schema snapshot`

## T2.17 Schema v2: competency bank, plan-note links, settings **(strong model)**
**Files:** `lib/models/database/tables.dart`, `lib/services/database/app_database.dart`, `test/database/migration_test.dart`. Generated and exempt: `app_database.g.dart`, `drift_schemas/drift_schema_v2.json`, `test/generated_migrations/`.
**Do:** add three tables and bump `schemaVersion` to 2. **Do not change** `LessonPlans`, `ReferenceNotes` or `Bibliography` columns.
```
CompetencyBank: id (auto), gradeLabel (text), learningArea (text), code (text, nullable, only if a source has one),
                text (text), source (text: 'seed' or 'user'), createdAt (datetime); unique (gradeLabel, learningArea, text)
PlanNoteLinks:  planId (int, references LessonPlans.id), noteId (int, references ReferenceNotes.id); primary key (planId, noteId)
AppSettings:    key (text, primary key), value (text)
```
In `onUpgrade`, `if (from < 2)` create the three tables. Fresh installs create everything and first-run seeding still works. Regenerate `app_database.g.dart`, dump the v2 schema, regenerate the migration helpers.
**Verify test:** v1 → v2 keeps existing `LessonPlans`, `ReferenceNotes` and `Bibliography` rows and the new tables exist and are empty; a fresh v2 database passes the same checks. Then by hand: copy your backed-up Phase 1 database into place, launch, and open a saved plan.
**Commit:** `feat(db): schema v2 with competency bank, plan-note links and settings`

## T2.18 Persist settings
**Files:** `lib/services/database/settings_repository.dart` (new), `lib/features/settings/settings_screen.dart`, `test/database/settings_repository_test.dart`.
**Interface:**
```dart
class SettingsRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}
```
**Do:** add a provider (in `providers.dart` only if that doesn't make it a 4th file; otherwise put the provider in `settings_repository.dart`). The default output language selector saves under key `default_language` (`filipino` or `english`) and the generator form reads it on startup.
**Verify test:** set then get returns the value; unknown key returns null; setting twice overwrites. By hand: change the language, restart, the form default is still the new language.
**Commit:** `feat(settings): persist default output language in the database`

## T2.19 Competency bank repository and seed
**Files:** `lib/services/database/competency_repository.dart` (new), `test/database/competency_repository_test.dart`, `pubspec.yaml` (add `assets/seed/` to assets).
**Prerequisite (human):** `assets/seed/competencies.json` exists (see Pre-flight). If it doesn't, create it containing only `[]` and say so. **Never write competency text yourself.**
**Interface:**
```dart
class CompetencyEntry { int id; String gradeLabel, learningArea, text; String? code; String source; }

class CompetencyRepository {
  Future<List<CompetencyEntry>> search({String? gradeLabel, String? learningArea, String query = '', int limit = 20});
  Future<void> add({required String gradeLabel, required String learningArea, required String text, String? code}); // source 'user', ignores duplicates
  Future<void> deleteUserEntry(int id);  // refuses source 'seed'
  Future<void> seedIfNeeded(String seedJson); // inserts seed rows once; records settings key 'competency_seeded'
}
```
`search` matches `query` as a case-insensitive substring. The caller loads the asset and passes the JSON string, so the repository is testable without Flutter bindings. Call `seedIfNeeded` from wherever first-run seeding already runs, or lazily at the first `search` if that is simpler.
**Verify test (in-memory database, fake JSON):** seeding twice inserts rows once; `search` filters by grade, area and text; adding a duplicate adds nothing; deleting a seed row is refused.
**Commit:** `feat(db): competency bank repository with seed loading`

---

## Group E: Form and references

## T2.20 Competency picker in the form
**Files:** `lib/features/generator/grade_input_card.dart`, `lib/features/generator/generator_form_state.dart`, `lib/core/providers.dart`.
**Do:** replace the competency text field with a Flutter `Autocomplete<String>` backed by `CompetencyRepository.search` (filtered by the form's learning area and this card's grade label; empty results are fine). **Free text always works.** When the typed text isn't in the bank, show a checkbox "Add to my competency bank"; when ticked, add it when the user presses Generate (not while typing). Keep the hybrid controller pattern so typing never loses focus or text.
**Verify:** widget test: typing part of a seeded competency shows a suggestion, picking it fills the field; typing a new text with the box ticked stores it after Generate (use a fake repository). By hand with 2 and 4 grades.
**Commit:** `feat(ui): competency picker backed by the bank`

## T2.21 References and plan-note links (repository)
**Files:** `lib/services/database/plan_references_repository.dart` (new), `lib/services/database/plan_repository.dart`, `test/database/plan_references_test.dart`.
**First:** read `lib/models/database/tables.dart` to see the real columns of `Bibliography` and `ReferenceNotes`. Use them as they are.
**Interface:**
```dart
class PlanReferencesRepository {
  Future<List<BibliographyEntry>> searchBibliography(String query);   // use the generated Drift row class
  Future<void> addBibliography(/* the existing columns */);
  String formatCitation(BibliographyEntry entry);   // uses only fields that are present; never fills in missing parts (H7)
  Future<List<ReferenceNote>> searchNotes(String query);
  Future<void> linkNote(int planId, int noteId);
  Future<void> unlinkNote(int planId, int noteId);
  Future<List<ReferenceNote>> notesForPlan(int planId);
}
```
Update `PlanRepository.delete` to remove that plan's `PlanNoteLinks` rows in the same transaction (SQLite foreign keys are off by default, so don't rely on cascade).
**Verify test:** linking twice stores one link; `notesForPlan` returns the linked notes; deleting a plan removes its links but not the notes; `formatCitation` of an entry with a missing field has no placeholder text.
**Commit:** `feat(db): bibliography search, citations and plan-note links`

## T2.22 References and notes panel
**Files:** `lib/features/plan_view/references_panel.dart` (new), `lib/features/plan_view/plan_workspace.dart`, `lib/core/providers.dart`.
**Do:** a card below the plan in `PlanWorkspace`, titled "References and notes":
- Lists `plan.references` with edit (reuse `showCellEditDialog`) and remove.
- "Add from bibliography": a search dialog; picking an entry appends `formatCitation(entry)` to `plan.references` through `update`.
- "Add custom reference": free text.
- "Linked notes": list, "Link a note" (search dialog), "Unlink". Disabled with the hint "Save the plan first" while `savedId == null`.
The panel only prints what the teacher chose; nothing here goes to a model (H7).
**Verify:** widget test: adding from the bibliography appends one line to `plan.references` and sets `dirty`; the notes controls are disabled for an unsaved plan. By hand: link a note, reopen the plan from the library, the link is still there.
**Commit:** `feat(ui): references and notes panel`

---

## T2.22 Hardening and close-out
**Files:** `working_docs/PROGRESS.md` (the rest are bug fixes the human finds, each as its own `fix:` commit).
**Do (human leads, agent helps):**
1. Run the **standing manual checks** from section 10 of the master plan.
2. Run the acceptance list below.
3. Record in `PROGRESS.md` (under 30 lines): Phase 2 done, Spike S numbers, and the 48k stress-test notes.
4. Run the file-size check and list anything over 250 lines for a split card at the start of Phase 3.
**Verify:** all of the below.
**Commit:** `docs: phase 2 complete`

---

## Phase 2 acceptance (human manual test)
- [ ] Fill the form with two grades, generate, then edit a flow cell, an objective list and an assessment cell. Undo works.
- [ ] Break the stage minutes: the validation panel shows an error naming the numbers. Fix them: the error disappears. Saving with an error still works.
- [ ] Regenerate one section: only that section changes. Regenerate one grade's cell: only that grade changes. Undo restores both.
- [ ] Repeat with four grades.
- [ ] Save, quit, relaunch, open the plan from the library, edit, Save, relaunch: the edit persisted. "Save as copy" creates a second plan.
- [ ] Put your backed-up Phase 1 database in place and launch: old plans open, nothing is lost, the new tables exist.
- [ ] Delete the database file and relaunch: first-run seeding works, including the competency bank.
- [ ] The competency picker suggests seeded entries, accepts free text, and a ticked new entry is in the bank next time.
- [ ] Add a reference from the bibliography and link a note: both survive a relaunch. Deleting the plan removes the link but keeps the note.
- [ ] The default language setting survives a restart.
- [ ] Standing manual checks 1 to 8 pass (light/dark, 1024×600, 2/3/4/6 grades, tab switching, fresh and migrated database, analyze/test/build, file sizes, PROGRESS.md).
- [ ] Spike S numbers and the stress-test notes are in `PROGRESS.md`.

Then merge `dev1` into `main`.
