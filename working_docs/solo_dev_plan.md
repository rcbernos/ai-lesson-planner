# Solo Development Plan v2: Offline AI Lesson Plan Assistant

Replaces `phase0_complete_dev_plan.md`, all per-dev commit plans, and the merge rules in `branch_strategy.md`.

**Product:** an offline desktop app (Flutter, Linux first, Windows later). A last-mile multigrade teacher fills in a short form and a locally run LLM on a 16 GB laptop drafts a DepEd ILAW Daily Lesson Plan for 2+ grades at once.

**Status going in:** Phase 0 done. Database layer done. The AI-engine code is written but untested, so treat it as unverified.

**How to read this plan:** this file is for you. The coding agent should read only `AGENTS.md` plus the one phase file it is working on (`phase1_tasks.md` now; later phase files are written when you get there, because earlier results change them).

---

## 1. Final decisions

| # | Decision |
|---|----------|
| D1 | **Stub the AI first.** Phase 1 ships a working UI with a mock generator. |
| D2 | **`llama-server` sidecar** (prebuilt llama.cpp binary, started and stopped by the app, listening on `127.0.0.1` only). Everything stays on the teacher's laptop. No cloud. |
| D3 | **The LLM outputs JSON. The app draws the ILAW layout.** |
| D4 | **One section at a time** (Intentions → Learning Experiences → Assessment → Ways Forward), with the anti-hallucination measures in section 3. |
| D5 | **Default model:** `Apertus-SEA-LION-v4-8B-IT`, Q4_K_M GGUF (about 5.1 GB). Fallback: `Gemma-SEA-LION-v4-4B-VL` Q4_K_M. Both are confirmed by your own speed and quality test (Spike S) before Phase 3. |
| D6 | **Model is not in the installer.** The app downloads it from your website on first run (section 5). |
| D7 | **DOCX via `docs_gee`** (verdict in section 4). **PDF via the `pdf` package**, not `docs_gee`. |
| D8 | **No CI.** You test manually after each phase. |
| D9 | **Git:** commit on a `dev1` branch, merge to `main` at the end of each phase. |
| D10 | **One OpenAI-compatible client class** talks to every backend: the local sidecar (production), your desktop's Qwen 3.5 9B server, and OpenRouter or NVIDIA (dev only). |
| D11 | **Plan for small coding models.** The coding agent is Qwen 3.5 9B (now configured for 48k context, not yet stress-tested on real agentic coding) plus free hosted models, so tasks stay small and self-contained (section 6). |
| D12 | **Windows check comes late.** Everything is built and tested on Debian until Phase 6. Windows-specific risks are managed by coding rules instead (section 8). |

---

## 2. Architecture in one picture

```
UI (Riverpod)  →  LessonGenerator (interface)
                    ├─ MockLessonGenerator           (Phase 1)
                    └─ LlmLessonGenerator            (Phase 3)
                          └─ OpenAiCompatibleClient  (base URL, optional key, model name)
                                ├─ http://127.0.0.1:<port>   ← llama-server sidecar (production)
                                ├─ desktop llama-server       ← Qwen 3.5 9B (dev)
                                └─ OpenRouter / NVIDIA        ← free hosted models (dev only)
Storage: Drift/SQLite (plans as JSON, notes, bibliography, competency bank)
Export:  DOCX (docs_gee)  |  PDF (pdf package + bundled font)  |  .lms bundle (archive)
```

Caveats of D10:
- **Free hosted models are not the production model.** Prompts tuned on them may not transfer to an 8B model on a CPU. The evaluation set (Phase 4) must always be run against the real SEA-LION model before a phase counts as done.
- **JSON-schema enforcement differs by backend.** `llama-server` can enforce it, hosted free models may ignore it. The app must always parse and validate the JSON itself.
- **Dev-only backends must be hidden in release builds**, and API keys must stay out of git.
- **Don't send real teacher or learner names** to hosted models. The sample DLPs contain real names, so anonymize first.

---

## 3. Reducing hallucination (D4)

This reduces hallucination. It does not remove it, so the teacher stays the final reviewer.

| # | Measure |
|---|---------|
| H1 | **Grounded fields are copied, never generated:** header data, content and performance standards, and learning competencies come only from the teacher's input or the competency bank. The model never writes competency codes. |
| H2 | **Schema-constrained output** per section, plus app-side parsing and validation on every backend. |
| H3 | **Low temperature** (about 0.2 to 0.4) in production, and a fixed seed in evaluation runs. |
| H4 | **Section chaining:** each section receives the inputs it needs plus the already-finished earlier sections as fixed context. Each call stays short. |
| H5 | **Traceability:** every activity and assessment item carries a `competency_ref`, and the validator checks it matches a competency the teacher entered for that grade. |
| H6 | **Validators with one targeted retry:** durations sum to the session length, every grade has an activity in every non-whole-class stage, no codes, URLs or citations that weren't supplied, and the language matches the chosen output language. On failure the retry prompt includes the exact failure. |
| H7 | **No invented references:** the bibliography is printed by the app from teacher entries. The prompt forbids names, books, laws and statistics that weren't provided. |
| H8 | **Cleaned few-shot examples** from the sample DLPs (typos and Cebuano words removed, names replaced). |
| H9 | **Human in the loop:** every plan carries the "AI-generated draft, teacher review required" declaration, and any section or grade cell can be edited or regenerated. |
| H10 | **Evaluation set** of 10 fixed requests (Phase 4) to measure validator pass rate when prompts or models change. |

---

## 4. docs_gee verdict (D7)

Checked against the package's published docs. `docs_gee` is at v1.5.0, so the existing `^1.5.0` constraint is right.

**Good for DOCX:**
- Tables with `colSpan` and `rowSpan` (this is what the whole-class merged rows need), column widths, cell shading, per-cell borders and vertical alignment.
- Bold, italic and underlined runs, headings, soft line breaks, page breaks, global font name and size.
- Pure Dart, MIT, no native dependencies, so it behaves the same on Debian and Windows.

**Not documented in what I read, so verify in a spike (Phase 5, T5.0):**
- Page orientation and margins for DOCX, headers and footers, page numbers, repeating table header rows, per-run font size.
- If something is missing, patch the generated DOCX zip with the `archive` package (`docs_gee` already depends on it), for example to set landscape orientation or add a footer.

**Not good for PDF here:** `docs_gee`'s PDF output uses only the standard base-14 fonts. Its docs state that extended Latin characters fall back to ASCII, and symbols such as the check and cross marks used in the sample DLPs would not render. Use the `pdf` package with a bundled font that has those glyphs, rendering from the same `LessonPlan` model.

**Decision:** `docs_gee` for DOCX, `pdf` for PDF, both fed from `LessonPlan`.

---

## 5. Model download (D6)

- **The installer installs the app only.** On first launch a setup screen offers "Download AI model (about 5 GB)". The same code runs on Linux and Windows, it can be retried, and it can later switch to another model.
- **Manifest on your website** (`models.json`): model id, file name, URL, size in bytes, SHA-256, minimum RAM. Models can then be swapped or added without releasing a new app version.
- **Downloader requirements:** HTTP Range resume using a `.part` file, streaming SHA-256 check, free-disk-space check, progress and cancel, clear errors, and never re-download a verified file.
- **Hosting:** a 5 GB file per teacher means real bandwidth. Hugging Face can act as a mirror, and the licence is Apache-2.0 according to the model card I saw, but confirm the licence text before you redistribute.
- **Kept small:** an "Import model file" button using the same verify code. It helps you in development and lets a teacher copy the file from a colleague.
- **Optional later:** having the installer itself do the download.

---

## 6. Working with small coding models (D11)

You use Cline with Qwen 3.5 9B, plus free hosted models. Your server now runs a 48k context window, but it has only been tried on summarizing a repository's architecture, not on a full edit, run and fix loop. So the plan keeps its small-task shape and treats the extra context as headroom for the agent, not as permission for bigger cards:

- **One task = one card**, with exact file paths, interface signatures, steps, a verify command and a commit message. The agent never has to design.
- **At most 3 files touched per task.** Keep files under about 250 lines. Split instead of growing.
- **Short `AGENTS.md`** (about 40 lines) and **one phase file** per session. Don't make the agent read this master plan.
- **Interfaces first:** a task that creates a model or interface runs and passes its tests before any UI uses it.
- **Use the stronger hosted model** for the hardest cards: sidecar process management (T3.2), the downloader (T3.1) and the DOCX layout (Phase 5). Routine UI cards suit the local 9B.
- **Start a fresh Cline task per card.** Don't let context pile up. Small models degrade well before the window is full.
- **Keep Cline's context setting equal to the server's `-c` value** (48k), so Cline trims history before the server overflows.
- **Stress-test before trusting 48k.** Use card T1.5 or T1.7 as the test: run it end to end with the local 9B, then note in `PROGRESS.md` how far the context filled, whether it lost track of the interface, and its speed late in the session. If it holds up, you may allow up to 5 files per card. If not, keep 3 and shorten cards further.

---

## 7. Findings kept from the review

1. `compute()` can't keep a model loaded or stream, so the sidecar replaces it.
2. Native binaries must be bundled. Confirm your llama.cpp build supports the `apertus` architecture, since it is recent.
3. `pubspec.yaml` was probably incomplete (`http`, `crypto`, `drift_dev`, `build_runner`, an SQLite runtime package, and `flutter_riverpod` rather than `riverpod`). Commit `pubspec.lock`.
4. `/LMS_Data/Exports/` is not a valid path. Use `Documents/LMS_Data/` via `path_provider` and `package:path`.
5. Branch names were inconsistent and one plan file had pasted chat text. Consolidate into one `PROGRESS.md`.
6. The sample DLPs have no actual competency codes. Teachers type competencies, so the app must never generate codes.
7. Multigrade means N grades (2 to 6), not just A and B.
8. The samples contain typos, one has Cebuano words, and all have real names. Clean and anonymize before use.
9. The chatbot is a small search feature on the non-critical path.

**Structure of the sample DLPs (drives the data model):** header table → I Intentions (shared sub-theme; per-grade standards, competencies, objectives; a "both grades" objective) → L Learning Experience (learner context, materials, Flow of the Lesson table where whole-class stages are one merged row and the middle follows teacher-led vs independent → switch → cross-grade collaboration → application) → A Assessment (per grade formative, exit task, success criteria) → W Ways Forward (reflection, per-grade remediation and enrichment, notes) → Prepared by / Checked by. Stage minutes add up to the session length.

---

## 8. Phases

You test manually at the end of every phase on Debian. **The first Windows build and run happens in Phase 6.** Flutter's Windows build needs a Windows machine with the Visual Studio C++ workload.

Deferring Windows means problems pile up for one big fix session. To keep that session small, the code follows these rules from day one (they are also in `AGENTS.md`):
- Paths only through `package:path` and `path_provider`. No hard-coded separators, and don't rely on file-name case (Windows ignores case, Linux doesn't).
- The sidecar launcher (T3.2) resolves the executable name per platform (`llama-server` vs `llama-server.exe`), launches it with `Process.start` and an argument list (no shell strings), and keeps the process handle so it can be killed on exit. Process cleanup differs on Windows, so expect to retest it in Phase 6.
- No Linux-only packages, no shelling out to Linux tools from app code.
- Fonts come from bundled assets only.

### Phase 1: Visible app (stubbed AI)
Details in `phase1_tasks.md`. **Done when** you can fill the form, press Generate, watch a plan stream in, see it laid out like the sample DLPs, save it, and reopen it from the library after a restart.

### Phase 2: Solid plan model (still stubbed)
- Validators (durations, every grade in every stage, required fields, learner counts).
- Inline editing, and regenerate one section or one grade's cell (mock).
- Competency bank in Drift, seeded from anonymized sample DLPs. The form picks from it or accepts new entries.
- Reference notes and bibliography attached to plans.
- Drift schema migrations with a test.
- **Done when** a plan can be created, edited, validated, saved and reopened, with references.

### Phase 3: Real local LLM (the core risk)
**Gate:** Spike S shows the 8B model at an acceptable speed and quality on your Surface Pro 9. If not, switch the default to the 4B model before building.
- **T3.1** Model manager and downloader (section 5), plus "Import model file".
- **T3.2** `LlamaServerRunner`: find the bundled binary, pick a free port bound to `127.0.0.1`, start with a fixed context (begin at 8192), health check, "model loading" state, stop on app exit, restart on crash, RAM warning.
- **T3.3** `OpenAiCompatibleClient` plus `LlmLessonGenerator`: four sequential streamed calls, schema per section, partial-JSON live preview, cancel, one validator-driven retry.
- **T3.4** Settings: backend picker (Demo / Local model / dev endpoints in debug builds only) and a "Test model" button reporting load time, tokens per second and peak RAM.
- **Done when** a real plan generates end to end, offline, on the Surface Pro 9 without freezing the UI.

### Phase 4: Quality and multigrade pedagogy
- Prompt design with cleaned few-shot examples and the multigrade rules.
- The 10-request evaluation script run against the production model.
- A real teacher rates three plans and you record what they change.
- Filipino / English output setting (small to build, quality measured by the evaluation set).
- Teacher notes injected into the prompt within a token budget.
- Minimal assistant: SQLite FTS5 search over saved plans and notes, answering only from retrieved snippets.
- **Done when** at least 8 of 10 evaluation requests pass validation and the teacher calls the plans usable with light edits.

### Phase 5: Exports and sharing
- **T5.0 Spike (1 hour):** build the sample layout with `docs_gee` and check orientation, margins, footer and repeated header rows in Word and LibreOffice. If something is missing, patch the zip as described in section 4.
- DOCX export (`docs_gee`), PDF export (`pdf` with a bundled font that has the check and cross glyphs), `.lms` bundle with a versioned manifest, export folder `Documents/LMS_Data/Exports/` with a snackbar.
- **Done when** a plan exports to DOCX and PDF, opens correctly, and a `.lms` round-trips between two installs.

### Phase 6: Windows port, packaging, field readiness
- First Windows build and run. Install the Visual Studio C++ workload and get `flutter doctor` green on the Windows laptop. Then fix paths, fonts and process launching, and retest the sidecar start, stop and crash restart. Bundle the Windows `llama-server`. Budget a full phase for this, since nothing has been run on Windows before it.
- Linux AppImage or `.deb`. Windows installer (Inno Setup, or a portable zip). Installers contain the app and the sidecar binary, not the model.
- Diagnostics log and an "export diagnostics" bundle.
- Test on an 8 GB laptop and decide whether to auto-select the 4B model for low-RAM machines.
- **Done when** a clean Windows laptop installs the app, downloads the model, then generates and exports a plan offline.

---

## 9. Spike S: do it yourself during Phase 1 (about an hour)

1. Get a recent `llama-server` build for Linux (prebuilt release or build from source).
2. Download the Q4_K_M GGUF from the official `aisingapore/Apertus-SEA-LION-v4-8B-IT-GGUF` repo.
3. Start the server with a context of 8192 and your thread count, then open its built-in web UI.
4. Paste a realistic prompt, for example: "Gumawa ng detalyadong daloy ng aralin para sa Grade 3 at 4, 90 minuto, paksa: ulat-panahon".
5. Record load time, tokens per second, RAM used and whether the Filipino is good. Confirm the build loads this model at all.
6. Repeat with `Gemma-SEA-LION-v4-4B-VL` Q4_K_M and compare.

Write the numbers into `PROGRESS.md`. They set the Phase 3 gate.

---

## 10. Open questions

- Where will real DepEd curriculum guides (MATATAG) come from, and may you bundle them? A searchable competency bank would help quality more than prompt tuning.
- What is the real minimum spec of teachers' laptops (RAM, CPU, Windows version)? This plan assumes 16 GB.
- Who is the teacher reviewer for Phase 4?
- What exact wording does the AI Use Declaration require?
- Where will `models.json` and the model file be hosted, and what happens to bandwidth costs if many teachers download at once?
