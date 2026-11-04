# AGENTS.md: rules for the coding agent

Project: offline Flutter desktop app that drafts DepEd ILAW lesson plans for multigrade classes (local LLM comes in Phase 3). Work on branch `dev1`. Never commit.

**Current phase file:** `working_docs/phase2_tasks.md`

## Every session
1. Read `working_docs/PROGRESS.md`, then ONLY your task card in the current phase file. Do not read other plan files.
2. Do exactly one card. Touch only the files it lists (max 3). Generated files (`*.g.dart`, Drift schema dumps, generated migration helpers) don't count. If you need more files, stop and say so.
3. Run the card's Verify commands, then `dart format .`, `flutter analyze` (zero issues) and `flutter test`.
4. Print the card's commit message and add 2 to 5 lines to `PROGRESS.md` (keep it under 30 lines). The human commits, not you.
5. Stop after the card. If Verify still fails after 3 attempts, stop and report what you tried.

## Using tools
- Never guess a path. Use only paths from your card, `PROGRESS.md`, or a list/search result. To find where a class is defined, search the codebase for `class Name`. Don't open a file just because its name sounds right. If a read says "not found", list the folder; don't try name variations.
- Read one file per call, and only files the card needs.
- Make one tool call at a time, as the last thing in your message. Wait for the result.
- Keep each edit under about 6000 characters. Prefer a targeted edit over rewriting a file. For a new file over about 150 lines, create the first part, then add the rest in later edits.
- If a call fails or comes back garbled, retry once with a simpler call (one file, smaller edit). Never resend the same payload a third time; stop and ask the human.

## Where things live
- Plan model classes (`LessonPlan`, `PlanHeader`, `GradeBlock`, `FlowStage`, and the rest): `lib/core/models/`, entry point `lesson_plan.dart`.
- `lib/core/generation/` (generator interface and mock), `lib/core/providers.dart`.
- UI: `lib/features/<shell|generator|plan_view|library|settings|assistant>/`. Cards name any new folders.
- Database: tables in `lib/models/database/tables.dart`, repositories in `lib/services/database/`.
- `lib/services/ai/legacy/` is old unused code. Ignore it.
- Tests: `test/` (database tests in `test/database/`).
- Area-specific rules (database, models and core, UI) live in `.clinerules/` and load when you work in those folders.

## Code rules
- Keep every file under about 250 lines. Split rather than grow.
- UI depends on the `LessonGenerator` interface only, never on a concrete generator.
- Paths in app code: `package:path` and `path_provider`. No hard-coded `/` or `\`. Don't depend on file-name case. No shelling out to Linux-only tools (the app must run on Windows later).
- Fully offline at runtime. Only the Phase 3 model downloader may use the network. Bundle fonts (Noto Sans) as assets.
- Never write curriculum content (competency text or codes, standards, references, seed data). It comes from the human or the teacher's input only.
- Fixtures use fictional names. Never commit real teacher, school or learner names.
- Conventional commit messages: `feat(scope): …`, `fix`, `docs`, `refactor`, `test`, `chore`.
- No new dependencies unless the card says so. If you add one, say why in `PROGRESS.md`.
- If a requirement is ambiguous, stop and ask. Do not guess.