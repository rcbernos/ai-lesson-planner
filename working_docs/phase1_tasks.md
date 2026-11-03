# Phase 1: Visible App (stubbed AI)

**Goal:** `flutter run -d linux` opens a real-looking app. (Linux only in this phase. The first Windows build is in Phase 6.) The user fills the generator form, presses Generate, watches a plan stream in, sees it laid out like the sample ILAW DLPs, saves it, and reopens it from the library after a restart. No LLM in this phase.

**Branch:** `dev1`. Merge to `main` only when the human has tested the whole phase.

Each card is one agent session. Do the cards in order.

---

## Pre-flight (human, not the agent)
- Install Flutter and the Linux desktop toolchain on Debian 13 (clang, cmake, ninja-build, pkg-config, GTK 3 dev headers). Run `flutter doctor` until the Linux toolchain line is green.
- In parallel, run Spike S from the master plan (about 1 hour) and record the numbers in `PROGRESS.md`.

---

## T1.1 Reconcile the repo (human with agent help)
**Files:** `working_docs/PROGRESS.md` (new), `AGENTS.md` (copy in), repo root.
**Do:**
1. `git branch -a` and `git log --oneline --graph --all`. Find where the database work (old Dev 2) and the AI-engine work (old Dev 1) live.
2. Create branch `dev1` from `main`. Merge the database work into `dev1`.
3. Move the unverified AI code to `lib/services/ai/legacy/` and make sure nothing imports it. Don't delete it.
4. Delete the old per-dev plan files in `working_docs/`. Keep one `PROGRESS.md` (under 30 lines: current state and next task).
**Verify:** `git status` clean, `git branch` shows `main` and `dev1`, `PROGRESS.md` exists.
**Commit:** `chore: consolidate branches and docs for solo workflow`

## T1.2 Fix the build
**Files:** `pubspec.yaml`, `pubspec.lock`, one smoke test.
**Do:** repair dependencies. Remove `llama_cpp_dart`. Keep `docs_gee: ^1.5.0`, `pdf`, `archive`. Add or confirm `flutter_riverpod`, `drift`, `drift_dev` (dev), `build_runner` (dev), `sqlite3_flutter_libs`, `path`, `path_provider`, `http`, `crypto`, `uuid`, `file_picker`. Then `dart run build_runner build --delete-conflicting-outputs` and `flutter pub get`.
**Verify:** `flutter analyze` has zero issues, `flutter test` passes, `flutter build linux` produces a binary, `pubspec.lock` is committed.
**Commit:** `fix: repair dependencies and get a clean build`

## T1.3 Domain model
**Files:** `lib/core/models/lesson_plan.dart`, `test/lesson_plan_test.dart`, `test/fixtures/sample_plan.dart`.
**Interface (use these names, plain Dart, hand-written `toJson` and `fromJson`, no codegen):**
```dart
class PlanHeader { String school, teacher, learningArea, date, term; int sessionMinutes;
  String multigradeModel; }               // e.g. "STDT"
class GradeBlock { String gradeLabel; int learnersMale, learnersFemale;
  String subTheme, contentStandard, performanceStandard;
  List<String> competencies, objectives; }
class FlowStage { int minutes; String stage; bool wholeClass;
  Map<String,String> activityByGrade; String wholeClassActivity; }
class GradeAssessment { String gradeLabel, formative, exitTask, successCriteria; }
class GradeWaysForward { String gradeLabel, remediation, enrichment; }
class LessonPlan { PlanHeader header; List<GradeBlock> grades; String sharedSubTheme,
  bothGradesObjective, learnerContext; List<String> materials; List<FlowStage> flow;
  List<GradeAssessment> assessments; List<String> reflectionQuestions;
  List<GradeWaysForward> waysForward; String notesNextSession; String preparedBy,
  checkedBy, aiUseDeclaration; }
```
The fixture is one Grade 3 and 4 plan based on a sample DLP with **fictional** names.
**Verify test:** JSON round-trip equals the original, and the flow minutes sum to `sessionMinutes`.
**Commit:** `feat(core): add lesson plan domain model with fixture`

## T1.4 App shell and theme
**Files:** `lib/main.dart`, `lib/features/shell/app_shell.dart`, `lib/core/theme.dart`, `assets/fonts/` (Noto Sans).
**Do:** `NavigationRail` with four destinations: Generator, Library, Assistant, Settings. Material 3, large readable text, light and dark. Works down to a 1024×600 window. Each destination is a placeholder `Scaffold` for now.
**Verify:** `flutter run -d linux` launches and all four tabs switch with no console errors.
**Commit:** `feat(ui): navigation shell and theme`

## T1.5 Generator interface and mock
**Files:** `lib/core/generation/lesson_generator.dart`, `lib/core/generation/mock_lesson_generator.dart`, `test/mock_generator_test.dart`.
**Interface:**
```dart
enum OutputLanguage { filipino, english }
class GradeInput { String gradeLabel; int male, female; String subTheme, competency; }
class GenerationRequest { PlanHeader header; List<GradeInput> grades;
  String sharedSubTheme; OutputLanguage language; }
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
`MockLessonGenerator` builds a plan from the request (using the form's grades, subject and sub-theme) and emits events with short delays. Section order: Intentions, Learning Experiences, Assessment, Ways Forward. Stage minutes must sum to the requested session length.
**Verify test:** all four sections arrive in order, the final plan has one `GradeBlock` per requested grade, and `cancel()` stops the stream.
**Commit:** `feat(core): LessonGenerator interface and mock implementation`

## T1.6 Generator form
**Files:** `lib/features/generator/generator_form_state.dart` (Riverpod notifier), `lib/features/generator/generator_screen.dart`, `lib/features/generator/grade_input_card.dart`.
**Do:** form fields: school, teacher, learning area, date, term, session minutes, shared sub-theme, multigrade model dropdown (STDT, peer leader, buddy reading), output language (Filipino or English). **Grades list:** add and remove grades (2 to 6), each with male and female counts and a free-text competency. No generation yet; the Generate button builds a `GenerationRequest` and the notifier exposes it.
**Verify:** adding a third grade shows a third card, removing down to 1 grade is blocked, and an empty required field blocks Generate (widget test for these two rules).
**Commit:** `feat(ui): generator form with multi-grade support`

## T1.7 Plan renderer
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`, `lib/features/plan_view/flow_table.dart`, `test/ilaw_plan_view_test.dart`.
**Do:** a read-only widget that takes a `LessonPlan` and reproduces the sample layout: header table; I, L, A and W banner rows; per-grade columns for standards, competencies and objectives; flow table where `wholeClass` stages span all grade columns; assessment and ways-forward tables; Prepared by / Checked by footer; AI Use Declaration. Works for any grade count from 2 to 6.
**Verify:** widget test renders the fixture and a 3-grade plan without overflow errors, and finds each section banner. The human compares it against a sample DLP. Save a screenshot to `working_docs/screens/`.
**Commit:** `feat(ui): ILAW plan renderer`

## T1.8 Wire generator to renderer
**Files:** `lib/features/generator/generator_screen.dart`, `lib/features/generator/generation_controller.dart`, `lib/core/providers.dart`.
**Do:** a Riverpod provider returns `MockLessonGenerator` as the `LessonGenerator`. Pressing Generate streams the events into a progress area (current section name, spinner, Cancel button) and finally shows `IlawPlanView`. Failure shows a message.
**Verify:** full flow works in the running app, Cancel stops generation, and a 3-grade request gives a 3-column plan.
**Commit:** `feat(ui): wire generator form to mock generation and plan view`

## T1.9 Library backed by Drift
**Files:** `lib/features/library/library_screen.dart`, `lib/services/database/plan_repository.dart`, existing Drift table file (only if a column is needed).
**Do:** a "Save" button on the generated plan stores the JSON in the existing plans table. The library lists saved plans (title from header, date), opens one in `IlawPlanView`, and deletes with a confirmation.
**Verify:** save, close the app, reopen, and the plan is still there. Delete the database file, relaunch, and the first-run seeding still works without a crash.
**Commit:** `feat(ui): library screen backed by drift`

## T1.10 Settings and Assistant placeholders
**Files:** `lib/features/settings/settings_screen.dart`, `lib/features/assistant/assistant_screen.dart`.
**Do:** Settings shows a default output language selector, the data folder path (read-only, under `Documents/LMS_Data/` via `path_provider`), and an AI status card reading "Demo mode: no model installed". Assistant shows "Coming soon" with a disabled input.
**Verify:** both screens open without errors and the language selector changes the generator form default.
**Commit:** `feat(ui): settings and assistant placeholders`

---

## Phase 1 acceptance (human manual test)
- [ ] `flutter run -d linux` launches from a clean checkout of `dev1`.
- [ ] Fill the form with two grades, generate, and watch the sections stream in.
- [ ] Repeat with four grades. The plan shows four columns.
- [ ] The rendered plan matches the structure of a sample ILAW DLP.
- [ ] Save, quit, relaunch, and open the plan from the library.
- [ ] Delete the database file and relaunch without a crash.
- [ ] `flutter analyze` and `flutter test` are clean.

Then merge `dev1` into `main`.
