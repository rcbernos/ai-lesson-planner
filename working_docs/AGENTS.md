# AGENTS.md: rules for the coding agent

Project: offline Flutter desktop app that drafts DepEd ILAW lesson plans for multigrade classes using a local LLM.

## Every session
1. Read `working_docs/PROGRESS.md`, then ONLY the task card you were given from the current phase file. Do not read other plan files.
2. Do exactly one task card. Touch only the files it lists (max 3). If you think more files are needed, stop and say so.
3. Run its Verify commands. Do not commit until they pass.
4. Commit with the card's commit message, then add 2 to 5 lines to `PROGRESS.md` (what changed, what is next). Keep that file under 60 lines; summarize old entries.

**Current Phase File:** `working_docs/phase0_tasks.md` (Phase 0: Repository Reconciliation for dev1 branch)

## Code rules
- Branch: work on `dev1`. Never commit to `main`.
- Before every commit: `dart format .`, `flutter analyze` (zero issues), `flutter test`.
- Conventional commits: `feat(scope): …`, `fix`, `docs`, `refactor`, `test`, `chore`.
- Never commit automatically. The human will commit manually after each task.
- Keep every file under about 250 lines. Split rather than grow.
- UI code depends on the `LessonGenerator` interface only, never on a concrete generator.
- Paths: use `package:path` and `path_provider`. Never hard-code `/` or `\`. Don't depend on file-name case. No shelling out to Linux-only tools from app code. (The app is tested on Linux now but must run on Windows later.)
- Fully offline at runtime. The only allowed network use is the model downloader (Phase 3).
- Bundle fonts (Noto Sans) as assets. Don't rely on system fonts.
- Never invent curriculum content: competency codes, standards, references. Those come from teacher input only.
- Samples and fixtures use fictional names. Never commit real teacher, school or learner names.
- No new dependencies unless the card says so. If you add one, write why in `PROGRESS.md`.
- If a requirement is ambiguous, stop and ask. Do not guess.
