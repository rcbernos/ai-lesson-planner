# Phase 1: Visible App (stubbed AI)

**Goal:** `flutter run -d linux` opens a real-looking app. (Linux only in this phase. The first Windows build is in Phase 6.) The user fills the generator form, presses Generate, watches a plan stream in, sees it laid out like the sample ILAW DLPs, saves it, and reopens it from the library after a restart. No LLM in this phase.

**Branch:** `dev1`. Merge to `main` only when the human has tested the whole phase.

Each card is one agent session. Do the cards in order.

---

## Current Status

**Phase 0 - Repository Reconciliation: COMPLETED**
- Branch `dev1` exists and is checked out
- AI engine code moved to `lib/services/ai/legacy/` with no imports elsewhere
- Dependencies fixed: `llama_cpp_dart` removed, `file_picker` added
- Noto Sans fonts added to `assets/fonts/` (Regular, Bold)
- Path resolution fixed in `utils.dart` using `path_provider`
- Database work from `dev2` merged into `dev1`
- Drift/SQLite layer complete with tables, CRUD, and first-run seeding
- All tests pass (20 tests), `flutter analyze` passes with zero issues
- `flutter build linux` produces a working binary

**Next task:** T1.1 - Update PROGRESS.md & verify build state

---

## Pre-flight (human, not the agent)
- Install Flutter and the Linux desktop toolchain on Debian 13 (clang, cmake, ninja-build, pkg-config, GTK 3 dev headers). Run `flutter doctor` until the Linux toolchain line is green.
- In parallel, run Spike S from the master plan (about 1 hour) and record the numbers in `PROGRESS.md`.

---

## T1.1 Update PROGRESS.md (human with agent help)
**Files:** `working_docs/PROGRESS.md`, `working_docs/phase1_tasks.md`, repo root.
**Do:**
1. Update `PROGRESS.md` to be under 30 lines reflecting current state (Phase 0 complete).
2. Verify `git status` shows no uncommitted changes.
3. Verify `git branch` shows `dev1` as current.
**Verify:** `PROGRESS.md` exists and is under 30 lines, `git status` clean.
**Commit:** `docs: update PROGRESS.md for Phase 1`

**Next task:** T1.2 - Verify clean build

## T1.2 Verify clean build
**Files:** `pubspec.yaml`, `pubspec.lock`.
**Do:** This was completed in Phase 0. Verify by running `flutter build linux` and ensure `pubspec.lock` is committed.
**Verify:** `flutter analyze` has zero issues, `flutter test` passes, `flutter build linux` produces a binary.
**Commit:** `verify: confirm clean build for Phase 1`

## T1.3 Domain model
**Files:** `lib/core/models/lesson_plan.dart`, `test/lesson_plan_test.dart`, `test/fixtures/sample_plan.dart`.
**Interface (use these names, plain Dart, hand-written `toJson` and `fromJson`, no codegen):**
```dart
class PlanHeader {
  String school, teacher, learningArea, date, term;
  int sessions, sessionMinutes;
  String multigradeModel; // e.g. "STDT"
}
class GradeBlock {
  String gradeLabel;
  int learnersMale, learnersFemale;
  String subTheme, contentStandard, performanceStandard;
  List<String> competencies, objectives;
}
class FlowStage {
  int minutes;
  String stage;
  bool wholeClass;
  Map<String,String> activityByGrade;
  String wholeClassActivity;
}
class GradeAssessment {
  String gradeLabel, formative, exitTask, successCriteria;
}
class GradeWaysForward {
  String gradeLabel, remediation, enrichment;
}
class ReflectionQuestion {
  String? gradeLabel; // null means whole-class
  String text;
}
class LessonPlan {
  PlanHeader header;
  List<GradeBlock> grades;
  String sharedSubTheme, bothGradesObjective, learnerContext;
  List<String> materials, references;
  List<FlowStage> flow;
  List<GradeAssessment> assessments;
  List<ReflectionQuestion> reflectionQuestions;
  List<GradeWaysForward> waysForward;
  String notesNextSession, preparedBy, checkedBy, aiUseDeclaration;
}
```
**Verify test:** JSON round-trip equals the original, and the flow minutes sum to `sessionMinutes`.
**Commit:** `feat(core): add lesson plan domain model with fixture`

The fixture (test/fixtures/sample_plan.dart) is one Grade 3 and 4 plan based on a sample DLP with **fictional** names. It uses the existing `defaultAiUseDeclaration` constant.

## T1.4 App shell and theme
**Files:** `lib/main.dart`, `lib/features/shell/app_shell.dart`, `lib/core/theme.dart`, `assets/fonts/` (Noto Sans).
**Do:** `NavigationRail` with four destinations: Generator, Library, Assistant, Settings. Material 3, large readable text, light and dark. Works down to a 1024×600 window. Only the NavigationRail shell is implemented. The Generator destination shows placeholders; Library, Assistant, Settings show simple text placeholders.
**Verify:** `flutter run -d linux` launches and all four tabs switch with no console errors.
**Commit:** `feat(ui): navigation shell and theme`

## T1.5 Generator interface and mock
**Files:** `lib/core/generation/lesson_generator.dart`, `lib/core/generation/mock_lesson_generator.dart`, `test/mock_generator_test.dart`.
**Interface:**
```dart
enum OutputLanguage { filipino, english }

class GradeInput {
  String gradeLabel;
  int male, female;
  String subTheme;
  String competency;
}

class GenerationRequest {
  PlanHeader header;  // includes sessions field (number of sessions in plan)
  List<GradeInput> grades;
  String sharedSubTheme;
  OutputLanguage language;
}

sealed class GenerationEvent {}

class SectionStarted extends GenerationEvent { String name; }
class TokenDelta extends GenerationEvent { String text; }
class SectionCompleted extends GenerationEvent { String name; }
class GenerationCompleted extends GenerationEvent { LessonPlan plan; }
class GenerationFailed extends GenerationEvent { String message; }

abstract class LessonGenerator {
  Stream<GenerationEvent> generate(GenerationRequest request);
  void cancel();
}
```

`MockLessonGenerator` builds a complete `LessonPlan` from the request using the form's grades, subject and sub-theme. It emits `GenerationEvent` objects with short delays simulating streaming. Section order: Intentions, Learning Experiences, Assessment, Ways Forward. Stage minutes must sum to the requested `sessionMinutes`. The `LessonPlan` includes `materials` (empty list for mock) and `references` (empty list for mock). `reflectionQuestions` and `assessments` are generated per grade.

**Verify test:** all four sections arrive in order, the final plan has one `GradeBlock` per requested grade, `cancel()` stops the stream, and flow minutes sum to `sessionMinutes`.
**Commit:** `feat(core): LessonGenerator interface and mock implementation`

## T1.6 Generator form
**Files:** `lib/features/generator/generator_form_state.dart` (Riverpod notifier), `lib/features/generator/generator_screen.dart`, `lib/features/generator/grade_input_card.dart`.
**Do:** form fields: school, teacher, learning area, date, term, `sessions` (number of sessions, defaults to 1), session minutes, shared sub-theme, multigrade model dropdown (STDT, peer leader, buddy reading), output language (Filipino or English). **Grades list:** add and remove grades (2 to 6), each with male and female counts and a free-text competency. The `GenerationRequest` is built from the form (including the new `sessions` field in `PlanHeader`).
**Verify:** adding a third grade shows a third card, removing down to 1 grade is blocked, and an empty required field blocks Generate (widget test for these two rules).
**Commit:** `feat(ui): generator form with multi-grade support`

## T1.7 Plan renderer
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`, `lib/features/plan_view/flow_table.dart`, `test/ilaw_plan_view_test.dart`.
**Do:** a read-only widget that takes a `LessonPlan` and reproduces the sample layout: header table; I, L, A and W banner rows; per-grade columns for standards, competencies and objectives; flow table where `wholeClass` stages span all grade columns; assessment and ways-forward tables; Prepared by / Checked by footer; AI Use Declaration. Works for any grade count from 2 to 6.
**Verify:** widget test renders the fixture and a 3-grade plan without overflow errors, and finds each section banner. The human compares it against a sample DLP. Save a screenshot to `working_docs/screens/`.
**Commit:** `feat(ui): ILAW plan renderer`

## T1.8 Wire generator to renderer
**Files:** `lib/features/generator/generator_screen.dart`, `lib/features/generator/generation_controller.dart`, `lib/core/providers.dart` (create new).
**Do:** a Riverpod provider (in `lib/core/providers.dart`) returns `MockLessonGenerator` as the `LessonGenerator`. Pressing Generate streams the events into a progress area (current section name, spinner, Cancel button) and finally shows `IlawPlanView`. Failure shows a message.
**Verify:** full flow works in the running app, Cancel stops generation, and a 3-grade request gives a 3-column plan.
**Commit:** `feat(ui): wire generator form to mock generation and plan view`

## T1.9 Library backed by Drift
**Files:** `lib/features/library/library_screen.dart`, `lib/services/database/plan_repository.dart`, `lib/models/database/tables.dart` (existing table with `ilawContent` field).
**Do:** a "Save" button on the generated plan stores the full JSON (using `LessonPlan.toJson()`) in the existing `LessonPlans` table's `ilawContent` field. The library lists saved plans (extracting title and date from the JSON), opens one in `IlawPlanView`, and deletes with a confirmation. The existing table has: `id`, `title`, `gradeLevel`, `subject`, `ilawContent`, `status`, `createdAt`, `updatedAt`.
**Verify:** save, close the app, reopen, and the plan is still there. Delete the database file, relaunch, and the first-run seeding still works without a crash.
**Commit:** `feat(ui): library screen backed by drift`

## T1.10 Settings and Assistant placeholders
**Files:** `lib/features/settings/settings_screen.dart`, `lib/features/assistant/assistant_screen.dart`.
**Do:** Settings shows a default output language selector, the data folder path (read-only, under `Documents/LMS_Data/` via `path_provider`), and an AI status card reading "Demo mode: no model installed". Assistant shows "Coming soon" with a disabled input.
**Verify:** both screens open without errors and the language selector changes the generator form default.
**Commit:** `feat(ui): settings and assistant placeholders`

---

## Phase 1 acceptance (human manual test)
- [x] `flutter run -d linux` launches from a clean checkout of `dev1`.
- [x] Fill the form with two grades, generate, and watch the sections stream in.
- [x] Repeat with four grades. The plan shows four columns.
- [x] The rendered plan matches the structure of a sample ILAW DLP.
- [x] Save, quit, relaunch, and open the plan from the library.
- [x] Delete the database file and relaunch without a crash.
- [x] `flutter analyze` and `flutter test` are clean.

Then merge `dev1` into `main`.

---

## Files to Create (Tasks T1.5-T1.10)

The following files need to be created for tasks 5 onwards:

### Generation Layer (T1.5)
- `lib/core/generation/lesson_generator.dart` - Abstract interface
- `lib/core/generation/mock_lesson_generator.dart` - Mock implementation
- `test/mock_generator_test.dart` - Tests for mock generator

### Generator UI (T1.6)
- `lib/features/generator/generator_form_state.dart` - Riverpod StateNotifier
- `lib/features/generator/generator_screen.dart` - Main generator page
- `lib/features/generator/grade_input_card.dart` - Individual grade input card

### Plan View (T1.7)
- `lib/features/plan_view/ilaw_plan_view.dart` - Main plan renderer
- `lib/features/plan_view/flow_table.dart` - Flow stage table widget
- `test/ilaw_plan_view_test.dart` - Widget tests

### Providers (T1.8)
- `lib/core/providers.dart` - Riverpod providers (LessonGenerator, etc.)

### Generation Controller (T1.8)
- `lib/features/generator/generation_controller.dart` - Generation state management

### Library (T1.9)
- `lib/features/library/library_screen.dart` - Library page
- `lib/services/database/plan_repository.dart` - PlanRepository class (wrapper around database)

### Settings (T1.10)
- `lib/features/settings/settings_screen.dart` - Settings page

### Assistant (T1.10)
- `lib/features/assistant/assistant_screen.dart` - Assistant placeholder page
