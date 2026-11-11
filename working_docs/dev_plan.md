# Dev Plan: AI Lesson Planner (Android, offline, agent-built)

Replaces `solo_dev_plan.md`. Phase files `phase0_tasks.md` and `phase1_tasks.md` are history. `phase2_tasks.md` stays the reference for Phase 2 cards already done.

**Product (from `specifications.md`):** an Android app for Last Mile School teachers. A teacher fills a form, or chats, and a model running fully on the phone drafts a DepEd ILAW lesson plan for 2 to 6 grades at once. Plans export to DOCX/PDF and move between devices by USB or file bundle. Target hardware is a 4 GB RAM phone.

**How to read this plan:** this file is for you. The coding agent reads only `AGENTS.md` plus the one card (or phase file) it is working on.

---

## 0. Where the repo really is

| Area | State (from `current_state.md`, `PROGRESS.md`) |
|---|---|
| Platform | Flutter **desktop only**. No `android/` directory. |
| Phase 0, 1 | Done. 108 tests. Drift/SQLite, schema v3, Riverpod. |
| Form mode | Done against the mock generator. |
| ILAW view and editing | Done: header table, I/L/A/W banners, editable cells, validation panel, undo, save/update/save-as-copy, per-section and per-grade regenerate (mock). |
| Not started | Android, any real model, chat mode, downloader, DOCX/PDF export, import/export, voice, IPEd toggle, sync. |
| Unclear | `PROGRESS.md` lists "Next: T2.15 migration test harness". `phase2_tasks.md` numbers it T2.16. Groups D and E of Phase 2 (migrations, competency bank, persisted settings, references and notes) look unfinished. Card **R0** settles this. |

---

## 1. Decisions

Decisions marked **CHANGED** replace the old solo plan.

| # | Decision |
|---|---|
| D1 | **Android is the product. Linux desktop is the dev harness.** UI, prompts and tests iterate on Linux. Android is where memory, speed and packaging get proven. |
| D2 **CHANGED** | **No `llama-server` sidecar.** Android cannot reliably launch a bundled server executable. The model runs **in-process through an FFI binding**, inside a background isolate. |
| D3 | The model outputs **JSON**. The app draws the ILAW layout. |
| D4 | **One section at a time**, with the anti-hallucination measures H1 to H10 from the old plan (still valid, see section 5). |
| D5 **CHANGED** | **Model tiers by device RAM**, not one default (section 4). The default is **chosen by Spike M on a real 4 GB phone**, not by the spec. |
| D6 | The model is not in the APK. The app downloads it on first run from your website, then runs offline. The model lives in **app-private storage**. |
| D7 | DOCX via `docs_gee` (pure Dart, works on Android). PDF via the `pdf` package with a bundled font. |
| D8 **CHANGED** | **One `LlmEngine` interface, three implementations:** `LocalLlamaEngine` (FFI, production), `HttpLlmEngine` (OpenAI-compatible, dev only: your desktop Qwen server or the same SEA-LION GGUF served by `llama-server`), `FakeEngine` (tests). |
| D9 **CHANGED** | **Chat mode = guided slot-filling.** The chat collects the form fields in conversation and feeds the same generation pipeline. It is not free-form lesson writing (section 7, Phase 6). |
| D10 | No CI. Manual test at the end of each phase. `dev1` branch, merge to `main` per phase. The agent never commits. |
| D11 **CHANGED** | **Windows is demoted to optional.** It was Phase 6 of the old plan. The target is Android now. Confirm this (section 11). |
| D12 | Validation never blocks saving. It only blocks export, with an override. |
| D13 | Competency references are zero-based indexes into that grade's `competencies` list. |

---

## 2. Problems found in `ai_implementation_spec.md`

The spec says "definitive" and "do not change the runtime package". Most of it is usable, but these points do not hold up. They are fixed in this plan. Please read them before you approve Phase 4.

| # | Issue | What the plan does |
|---|---|---|
| S1 | `llama_cpp_dart: ^0.9.x` is not a valid constraint. On pub.dev the 0.9 line is **prerelease only** (`0.9.0-dev.N`). | Phase 4 starts with an engine spike instead of fixing the package in advance. |
| S2 | `llama_cpp_dart` describes itself as targeting iOS, Android and macOS. **Not Linux or Windows.** You develop on Linux. | Engine must build on Android **and** Linux. Candidates: `llamadart` (lists Android, Linux, Windows, macOS, iOS), `lib_llama_cpp` (same platforms), `llama_cpp_dart`. |
| S3 | The memory table adds up to about 4.5 GB. The spec's own target is 4 GB. | Treated as a **failing budget**, not a proven fit. Spike M measures real numbers. |
| S4 | "1.8 GB peak RAM (measured)" for a 2.5 GB file. Weights can be memory-mapped, but a 4B Q4 model touches most of its weights while generating. No measurement is on file. | Treated as unverified. |
| S5 | Android reserves a large share of a 4 GB phone for the system. A 2.5 GB model plus KV cache plus Flutter can get the app killed by the low-memory killer. | Tiers plus unload-on-idle plus a RAM check before loading (Phase 4). |
| S6 | `context.applicationInfo.dataDir` is Kotlin/Java, not Dart. | Use `path_provider` (`getApplicationSupportDirectory()`), or a small platform channel if needed. |
| S7 | The spec asks for `INTERNET` permission and also says "no external storage". Both are fine, but the sentence about a Kotlin `dataDir` hints at old storage code. | Keep `INTERNET` only. Use the system file picker (SAF) for import/export. No storage permissions. |
| S8 | Response time "< 5 seconds". A full lesson plan is thousands of output tokens. On a budget CPU that will take minutes. | New target: **time to first token** under 15 s, **full plan** under 10 min on the reference phone. Spike M sets the real numbers. |
| S9 | The primary model is `Qwen-SEA-LION-v4-4B-VL` through a community quantizer's repo. The official `aisingapore` GGUF collection I could see lists `Gemma-SEA-LION-v4-4B-VL-GGUF` (Q4_K_M and Q6_K) and the 8B Apertus GGUF. I could not confirm an official Qwen 4B GGUF. | Check the hosting and licence before shipping. The model manifest allows swapping later. |
| S10 | `Gemma-SEA-LION-v4.5-E2B` is not something I could verify. | Test only if the file exists. |
| S11 | "Grammar-constrained output via GBNF" depends on the chosen binding exposing grammar or JSON-schema sampling. | An engine selection criterion. If missing, rely on parse, validate, retry (H6). |
| S12 | The spec's `LlamaCppParams(n_CTX, n_THREADS...)` names are guesses. | Use the real API of the engine picked in T4.1. |
| S13 | Both models in the spec are 4B vision-language models. Vision is unused. | Prefer a **text-only GGUF** or skip the vision projector file so it is never loaded. |
| S14 | Spec feature 7 says "daily lesson logs (DLLs) and **worksheets**". The app only models ILAW DLPs. Worksheets are not in the data model. | Open question Q3 (section 11). A worksheet card is parked in Phase 9. |
| S15 | Feature 6 says "IMS packages". Unclear whether that means IMS Common Cartridge. | Open question Q2. Plan builds a `.lms` bundle first. |

---

## 3. Architecture

```
UI (Riverpod)
  └─ LessonGenerator (interface, exists)
       ├─ MockLessonGenerator                 exists
       └─ LlmLessonGenerator                  Phase 5
            ├─ prompt builders (from ilaw_ai_scaffold.md)
            ├─ section JSON schemas
            ├─ tolerant JSON parser, PlanValidator (exists), one retry
            └─ LlmEngine (interface)           Phase 4
                 ├─ LocalLlamaEngine  (FFI, isolate)   production on Android
                 ├─ HttpLlmEngine     (OpenAI-compatible, debug builds)   desktop dev
                 └─ FakeEngine        (tests)

Chat mode: ChatSession → slot filling → GenerationRequest → same pipeline  (Phase 6)
Storage:   Drift/SQLite (plans, notes, bibliography, competency bank, settings, chat sessions)
Models:    ModelManifest → ModelDownloader → app-private dir → DeviceCapability check
Export:    DOCX (docs_gee) | PDF (pdf) | .lms bundle (zip)  via system file picker or share sheet
```

Caveats of D8:
- A prompt that works on a desktop 9B model may fail on the phone's 4B model. **The evaluation set always runs against the production GGUF.** The same GGUF file can be served by `llama-server` on your desktop for fast prompt iteration. Speed and memory are only proven on the phone.
- Hosted free models (OpenRouter, NVIDIA) are for plumbing tests only. Never send real teacher or learner names to them.
- `HttpLlmEngine` and dev endpoints are compiled out of release builds. API keys never go in git.

---

## 4. Model tiers (4 GB constraint)

RAM numbers below are **estimates to be replaced by Spike M**. A "4 GB" phone usually leaves well under 4 GB for your app once Android and its services are running.

| Tier | Device RAM | Model class | Notes |
|---|---|---|---|
| A | 3 to 4 GB | Smallest usable model (about 1 to 2B class, or a 4B at an aggressive quant if quality holds) | **Not selected yet.** Spike M must find one that writes acceptable Filipino. If none does, say so plainly: the 4 GB MVP goal is at risk. |
| B | 6 GB | 4B Q4_K_M. Candidates: `Gemma-SEA-LION-v4-4B-VL` (official GGUF, Gemma licence), `Qwen-SEA-LION-v4-4B-VL`. | Context 3072 to 4096. |
| C | 8 GB and up | `Apertus-SEA-LION-v4-8B-IT` Q4_K_M (about 5 GB). | Better quality. Needs a flagship phone. |

Runtime settings to tune in Spike M (names depend on the engine): context size (start 2048, test 3072 and 4096), threads (physical performance cores, usually 4), KV cache type (q8_0 if the engine allows), memory-mapped weights, batch size, **no GPU/Vulkan** by default (the `llamadart` docs mark Android Vulkan as experimental and exclude a known bad Adreno 750 driver).

Prompt token budget at n_ctx 4096: system block plus section prompt plus earlier sections plus output reserve must fit. Card T5.1 builds a token estimator and tests it.

---

## 5. Reducing hallucination (kept, trimmed)

H1 Grounded fields (header, standards, competencies) are copied, never generated; the model never writes competency codes.
H2 Schema-constrained output per section, plus app-side parse and validate on every backend.
H3 Low temperature (0.2 to 0.4), fixed seed in evaluation.
H4 Section chaining: finished sections go into later prompts as fixed context.
H5 Every activity and assessment carries a competency index; the validator checks it.
H6 Validators with **one** targeted retry whose prompt includes the exact failure.
H7 No invented references; the app prints the bibliography from teacher entries.
H8 Cleaned few-shot examples with fictional names.
H9 Teacher review declaration; any section or cell can be edited or regenerated.
H10 10-request evaluation set to measure validator pass rate.

---

## 6. Rules for the coding agent

Put these in `AGENTS.md` (keep it short). They reflect your Cline setup with Qwen 3.5 9B, currently at a 16k to 48k context.

1. One card per Cline task. Start a **fresh task for every card**.
2. **Max 3 files touched per card**, not counting generated files (`*.g.dart`, Drift schema dumps, generated migrations). Android Gradle, manifest and Kotlin files **do count**.
3. Files stay under about 250 lines. If a card would push a file over, stop and say so.
4. **Never commit.** Print the commit message and add 2 to 5 lines to `PROGRESS.md` (under 30 lines total).
5. No new dependency unless the card lists it under **Deps**.
6. Never write curriculum text (standards, competencies, references) or cultural/indigenous content. Those come from the human. Fixtures use fictional names.
7. Never guess a file path or a package API. Read the file, or read the package's docs/source in the pub cache, first. Print the exact version you read.
8. A card that says **(strong)** is for the stronger hosted model. A card that says **(human)** is not for the agent.
9. Paths only through `package:path` and `path_provider`. No hard-coded separators.
10. `flutter analyze` clean and `flutter test` passing before the card is declared done.

Card tags: **[9B]** suits the local Qwen 3.5 9B. **(strong)** needs a stronger model. **(human)** is done by you.

---

# PHASES

## Phase 2 (finish): Solid plan model

Goal: the plan can be created, edited, validated, saved, reopened, migrated and referenced, still with the mock. Most of Groups A to C and the T2.14.x cards are done.

### R0 Reconcile state (human, with agent help) [9B]
**Files:** `working_docs/PROGRESS.md`, `working_docs/old_docs/initial_implementation/phase2_tasks.md`.
**Do:**
1. For every card T2.0 to T2.23 mark done or not done in `phase2_tasks.md`, by checking the code, not the notes. Report: the schema version in `app_database.dart`, whether `CompetencyBank`, `PlanNoteLinks`, `AppSettings` tables exist, whether `settings_repository.dart`, `competency_repository.dart` and `plan_references_repository.dart` exist.
2. Run `flutter analyze` and `flutter test`. Record the test count.
3. List Dart files over 250 lines.
4. Rewrite `PROGRESS.md` (under 30 lines).
**Verify:** `PROGRESS.md` states which Phase 2 cards remain.
**Commit:** `docs: reconcile phase 2 status`

### Remaining Phase 2 cards
Do whichever of these R0 shows as not done, in this order, using the full card text already in `phase2_tasks.md`:
**T2.16** migration test harness (strong) → **T2.17** schema v2 (strong) → **T2.18** persist settings → **T2.19** competency repository and seed → **T2.20** competency picker → **T2.21** references repository → **T2.22** references panel → **T2.23** hardening.

**Pre-flight (human):** back up your current database file. Prepare `assets/seed/competencies.json` by hand.

**Acceptance:** the Phase 2 acceptance list in `phase2_tasks.md`, minus the Spike S items (replaced by Spike M). Then merge `dev1` to `main`.

---

## Phase 3: Android foundation (mock AI)

Goal: a debug APK installs on a real Android phone and does everything the desktop app does today with the mock generator: form, generate, edit, validate, save, reopen. No model yet.

### T3.0 Toolchain and device (human)
- Install the Android SDK and NDK on your Debian laptop. Get `flutter doctor` green for Android.
- Get a **real 4 GB RAM Android phone** and enable USB debugging. Note its exact model, RAM, Android version, chipset and whether it is 32-bit or 64-bit.
- Optionally get a second, 6 GB or more phone for tier B/C testing.
- Emulators are fine for UI. They are **not** valid for memory or speed numbers, and an x86 emulator cannot load an arm64-only native library.
- Record the device facts in `PROGRESS.md`.

### T3.1 Add the Android platform [9B]
**Files:** `android/app/build.gradle(.kts)`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml` (only if needed).
**Do:**
1. Run `flutter create --platforms=android .` (do not overwrite existing `lib/`).
2. Set `applicationId` (ask the human; suggest `ph.lms.lessonplanner`), app label, `minSdk` (use the engine's requirement from T4.1; use 24 until then), `abiFilters` = `arm64-v8a` only.
3. Manifest: only `INTERNET`. No storage permissions. Set `android:largeHeap` **off**.
**Verify:** `flutter build apk --debug` succeeds. `flutter analyze` clean.
**Commit:** `feat(android): add android platform`

### T3.2 Adaptive shell [9B]
**Files:** `lib/features/shell/app_shell.dart`, `lib/core/theme.dart`, `test/app_shell_test.dart`.
**Do:** below 600 dp wide use a bottom `NavigationBar`, above that the `NavigationRail`. Minimum supported size 360×640. Touch targets at least 48 dp. Respect system font scale up to 1.3.
**Verify:** widget test at 360×640 and 1024×600 finds the right nav widget and no overflow.
**Commit:** `feat(ui): adaptive navigation for phones`

### T3.3 Generator form on phones [9B]
**Files:** `lib/features/generator/generator_screen.dart`, `lib/features/generator/grade_input_card.dart`, `test/generator_form_layout_test.dart`.
**Do:** single-column layout under 600 dp, scroll when the keyboard opens (`resizeToAvoidBottomInset`), the Generate button always reachable, grade cards collapse to a summary.
**Verify:** widget test at 360×640 with 2 and 6 grades: no overflow; submit button reachable.
**Commit:** `feat(ui): phone-friendly generator form`

### T3.4 Plan view on narrow screens (strong) 
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`, `lib/features/plan_view/flow_table.dart`, `lib/features/plan_view/assessment_tables.dart`.
**Do:** under 600 dp the grade-column tables scroll horizontally inside their own container, with a minimum column width of about 220 dp. Header table stacks to two columns. Banners stay full width. Do not change the document structure.
**Verify:** widget test: 2, 4 and 6 grades at 360×640, no overflow error; the page body never scrolls sideways.
**Commit:** `feat(ui): responsive plan view`

### T3.5 One-grade-at-a-time view on phones [9B]
**Files:** `lib/features/plan_view/ilaw_plan_view.dart`, `lib/features/plan_view/grade_selector.dart` (new), `test/grade_selector_test.dart`.
**Do:** an optional chip row "All grades / Grade 3 / Grade 4 …" above the plan on narrow screens. Selecting one grade shows only that grade's columns. Editing and regenerate behave the same.
**Verify:** selecting Grade 4 hides Grade 3 columns; "All" restores them.
**Commit:** `feat(ui): per-grade focus on narrow screens`

### T3.6 Android storage and lifecycle [9B]
**Files:** `lib/core/utils.dart`, `lib/services/database/app_database.dart`, `lib/core/providers.dart`.
**Do:** database and data folder under `getApplicationSupportDirectory()` on Android; the "data folder" line in Settings shows the app-private path. Editor state survives a configuration change and returning from the background. `PlanEditorNotifier` autosaves a draft (debounced) so an Android process kill does not lose edits.
**Verify:** by hand: edit, press Home, kill the app from recents, reopen, the draft restore prompt appears.
**Commit:** `feat(android): app-private storage and draft recovery`

### T3.7 Phase 3 device test (human)
**Acceptance:**
- [x] Debug APK installs on the 4 GB phone via `flutter run` or `adb install`.
- [x] Fill the form with 2 and 4 grades, generate (mock), edit, undo, save, close, reopen.
- [x] Rotate, use light/dark, change font scale: no overflow.
- [x] Airplane mode on: everything above still works.
- [x] Desktop Linux build still passes `flutter test`.
Then merge `dev1` to `main`.

---

## Phase 4: On-device engine, model manager (the core risk)

Goal: the phone loads a real GGUF and streams tokens through `LlmEngine`. No lesson-plan prompts yet. **This phase decides whether the 4 GB goal is realistic.**

### T4.1 Engine selection spike (human with agent) (strong)
**Files:** `working_docs/engine_spike.md` (new).
**Do:** compare these packages **by reading their current README and API, not from memory**:
- `llamadart` (current line `^0.16.x`)
- `lib_llama_cpp` (`^0.7.x`) with its Android and Linux federated packages
- `llama_cpp_dart` (`0.9.0-dev.N` prerelease)

Score each on: builds for Android arm64 **and** Linux; streaming tokens; cancel mid-generation; runs off the UI thread (isolate); grammar or JSON-schema constrained sampling; chat template handling; context, thread and KV-cache controls; memory-mapped loading; minimum Android SDK; licence; last release date; maintenance activity; prerelease risk. Build a 30-line sample app with the front-runner and load a tiny GGUF on Linux and on the phone.
**Verify:** `engine_spike.md` names one engine and one fallback with reasons, plus the pinned version and `minSdk`.
**Deps:** none yet.
**Commit:** `docs: engine selection spike`

### T4.2 Spike M: model, memory and speed on the phone (human)
Use the chosen engine's sample app or a throwaway test screen. For each candidate model file, at context 2048, 3072 and 4096:
- load time, time to first token, tokens per second, 500-token generation time
- peak memory: `adb shell dumpsys meminfo <package>` (total PSS) while generating; `adb logcat` for low-memory-killer kills
- thermal throttling after 3 runs in a row
- quality: the Filipino test prompt from the old plan ("Gumawa ng detalyadong daloy ng aralin para sa Grade 3 at 4, 90 minuto, paksa: ulat-panahon") and one English prompt

Candidates: Gemma-SEA-LION-v4-4B-VL Q4_K_M (official), Qwen-SEA-LION-v4-4B-VL Q4_K_M (check source), one 1 to 2B model for tier A, the E2B model only if the file exists. Record all numbers in `PROGRESS.md`.
**Gate (decide before T4.4):**
- Pass: a model with peak PSS comfortably under what the 4 GB phone can give and acceptable Filipino → tier A is real.
- Fail: tell the user plainly that 4 GB devices need a smaller, weaker model or a lower-quality plan, or that the MVP's minimum should be 6 GB. Update `specifications.md` accordingly.

### T4.3 `LlmEngine` interface and `FakeEngine` [9B]
**Files:** `lib/core/llm/llm_engine.dart`, `lib/core/llm/fake_engine.dart`, `test/fake_engine_test.dart`.
**Interface (pure Dart, no Flutter imports):**
```dart
class GenParams { double temperature; int maxTokens; int? seed; String? jsonSchema; String? grammar; List<String> stop; }
class ChatMsg { String role; String content; }          // 'system' | 'user' | 'assistant'

enum EngineState { unloaded, loading, ready, generating, error }

abstract class LlmEngine {
  Stream<EngineState> get state;
  Future<void> load(ModelSpec spec);           // spec: path, contextSize, threads
  Stream<String> complete(List<ChatMsg> messages, GenParams params);   // token deltas
  Future<void> cancel();
  Future<void> unload();
}
```
`FakeEngine` replays scripted token lists with small delays and supports cancel and failure injection.
**Verify test:** tokens arrive in order; `cancel()` stops the stream; `load` on a bad spec fails with a typed error.
**Commit:** `feat(core): LlmEngine interface and fake engine`

### T4.4 `HttpLlmEngine` (dev only) (strong)
**Files:** `lib/core/llm/http_llm_engine.dart`, `lib/core/llm/sse_parser.dart`, `test/http_llm_engine_test.dart`.
**Do:** speak the OpenAI-compatible `/v1/chat/completions` stream protocol (base URL, optional key, model name). Parse server-sent events. Pass `temperature`, `seed`, `max_tokens`, `response_format` or `grammar` when set. Guard with `kDebugMode` and an `assert` so release builds cannot select it. Test against a local `HttpServer` in the test.
**Deps:** none (`http` is already present).
**Verify test:** deltas stream; `cancel()` closes the connection; a malformed event does not crash the stream.
**Commit:** `feat(core): OpenAI-compatible dev engine`

### T4.5 `LocalLlamaEngine` (strong)
**Files:** `lib/core/llm/local_llama_engine.dart`, `lib/core/llm/llama_isolate.dart`, `test/local_llama_engine_test.dart`.
**Deps:** the engine picked in T4.1 (human approves the exact version).
**Do:** implement `LlmEngine` over the chosen package. The model runs in a background isolate. `cancel()` must stop generation within about a second. `unload()` frees the native memory. Gate the test that needs a real model behind an env var (`LMS_TEST_GGUF=/path`) so CI-less runs stay green.
**Verify:** with `LMS_TEST_GGUF` set, load a small model on Linux and stream 50 tokens; cancel works. Then by hand on the phone.
**Commit:** `feat(core): local llama engine`

### T4.6 Model manifest [9B]
**Files:** `lib/core/models/model_manifest.dart`, `test/model_manifest_test.dart`, `assets/models.sample.json`.
**Do:** `models.json` (hosted on your website): `id`, `displayName`, `tier`, `fileName`, `url`, `sizeBytes`, `sha256`, `minRamMb`, `contextSize`, `language`, `licenseUrl`. Parse tolerantly, ignore unknown fields. Never ship real URLs or hashes in the sample.
**Verify test:** parse the sample; unknown fields ignored; missing required field throws a typed error.
**Commit:** `feat(core): model manifest`

### T4.7 Model downloader (strong)
**Files:** `lib/services/models/model_downloader.dart`, `lib/services/models/model_store.dart`, `test/model_downloader_test.dart`.
**Do:** HTTP **Range** resume with a `.part` file; streaming SHA-256 verify; free-disk check (need file size plus margin); progress and cancel; exponential backoff on network timeouts; a verified file is never re-downloaded; store in `getApplicationSupportDirectory()/models/`. `ModelStore` lists installed models and deletes one.
**Deps:** none (`http` and `crypto` are present).
**Verify test (local `HttpServer` serving a fake 5 MB file):** resume after an interrupted download; a wrong hash deletes the file and reports an error; insufficient disk space refuses before downloading; cancel leaves a resumable `.part`.
**Commit:** `feat(services): resumable model downloader with checksum`

### T4.8 Device capability check (strong)
**Files:** `android/app/src/main/kotlin/.../MainActivity.kt`, `lib/services/device/device_capability.dart`, `test/device_capability_test.dart`.
**Do:** a platform channel returns total RAM, currently available RAM, low-RAM flag and CPU ABI (`ActivityManager.MemoryInfo`, `Build.SUPPORTED_ABIS`). `DeviceCapability.recommendTier(manifest)` picks the best tier for the device and returns warnings. On Linux the channel is absent and the class uses `/proc/meminfo`.
**Verify test:** `recommendTier` with fake RAM values; a 32-bit-only device gets a clear "not supported" result.
**Commit:** `feat(android): device RAM check and model tier recommendation`

### T4.9 Setup and model screen [9B]
**Files:** `lib/features/settings/model_setup_screen.dart`, `lib/features/settings/settings_screen.dart`, `test/model_setup_screen_test.dart`.
**Do:** a first-run card "Download AI model (about N GB)" with the recommended tier, a Wi-Fi warning, progress, pause/resume, "Delete model", and **"Import model file"** (system file picker, copy into app-private storage, verify the hash). Settings AI status card shows the installed model and engine state. Keep the screen awake while downloading (needs `wakelock_plus`; the human approves that dependency). Resume automatically on relaunch.
**Verify:** widget test with a fake downloader: progress renders, cancel works. By hand on the phone: interrupt the download with airplane mode, reconnect, it resumes.
**Commit:** `feat(ui): model setup screen`

### T4.10 Memory pressure handling (strong)
**Files:** `lib/services/llm/engine_lifecycle.dart`, `lib/core/providers.dart`, `test/engine_lifecycle_test.dart`.
**Do:** a controller that loads the model only when generation starts, unloads after an idle timeout (default 60 s), refuses to load below a minimum available-RAM threshold with a friendly message, and unloads on `didHaveMemoryPressure` and `AppLifecycleState.paused`. Typed `OutOfMemoryException` → one retry with a smaller context, then a clear error.
**Verify test:** with `FakeEngine`: idle unload fires; low-RAM load is refused; pressure event unloads.
**Commit:** `feat(core): engine lifecycle and memory pressure handling`

### Phase 4 acceptance (human, on the phone)
- [ ] The chosen model downloads, survives a mid-download interruption, passes its hash check.
- [ ] A throwaway test screen streams real tokens from the model offline.
- [ ] Cancel stops generation. The UI never freezes.
- [ ] No low-memory kill in 10 generations in a row (check `logcat`).
- [ ] The model file sits in app-private storage and the app has no storage permission.
- [ ] Spike M numbers and the tier decision are in `PROGRESS.md`.

---

## Phase 5: Real plan generation (form mode)

Goal: a real plan generates from the form, on the phone, offline, and passes validation most of the time. All prompt design uses `ilaw_ai_scaffold.md` as the source.

### T5.1 Token budget estimator and prompt pieces [9B]
**Files:** `lib/core/generation/prompts/shared_prompt.dart`, `lib/core/generation/token_budget.dart`, `test/token_budget_test.dart`.
**Do:** shared system block from scaffold section 5.0 (output language rules, no invented codes, JSON only). A conservative `estimateTokens(String)` (about chars/3 for Filipino) and `fitsBudget(parts, nCtx, outputReserve)`.
**Verify test:** a worst-case 6-grade request fails `fitsBudget` at 2048 and passes at 4096 with the shortest prompts; shared block under a stated token count.
**Commit:** `feat(core): shared prompt and token budget`

### T5.2 Section prompts [9B]
**Files:** `lib/core/generation/prompts/intentions_prompt.dart`, `lib/core/generation/prompts/learning_prompt.dart`, `test/prompts_test.dart`.
**Do:** builders returning `List<ChatMsg>` for Intentions and Learning Experience, from scaffold sections 5.1 and 5.2. Earlier sections go in as fixed context. Include one cleaned few-shot example with fictional names (the human supplies the example text).
**Verify test:** the prompt contains each grade label, each competency once, the exact minute total; no prompt exceeds the budget for 2 and 4 grades.
**Commit:** `feat(core): intentions and learning experience prompts`

### T5.3 Assessment and Ways Forward prompts [9B]
**Files:** `lib/core/generation/prompts/assessment_prompt.dart`, `lib/core/generation/prompts/ways_forward_prompt.dart`, `test/prompts_test.dart`.
**Do:** scaffold sections 5.3 to 5.5, including single-grade regeneration variants.
**Verify test:** per-grade variant mentions only that grade; the other grades appear only as fixed context.
**Commit:** `feat(core): assessment and ways forward prompts`

### T5.4 Section JSON schemas [9B]
**Files:** `lib/core/generation/schemas/section_schemas.dart`, `test/section_schemas_test.dart`.
**Do:** a JSON Schema (as a Dart `Map`) for each section, taken from the scaffold's JSON skeleton. Intentions may only contain `objectives`, `bothGradesObjective`, `sharedSubTheme` text; **no** standards or competencies (H1).
**Verify test:** the mock generator's output for each section validates against the matching schema.
**Commit:** `feat(core): per-section json schemas`

### T5.5 Tolerant JSON extraction [9B]
**Files:** `lib/core/generation/json_extract.dart`, `lib/core/generation/partial_json.dart`, `test/json_extract_test.dart`.
**Do:** extract the first JSON object from model text (strip code fences, preamble, trailing text), repair trailing commas, and a best-effort partial parser for the live preview while tokens stream.
**Verify test:** fenced JSON, preamble plus JSON, truncated JSON (partial result, flagged incomplete), and garbage (typed failure).
**Commit:** `feat(core): tolerant json extraction`

### T5.6 `LlmLessonGenerator`: Intentions and Learning Experience (strong)
**Files:** `lib/core/generation/llm_lesson_generator.dart`, `lib/core/generation/section_runner.dart`, `test/llm_generator_test.dart`.
**Do:** implement `LessonGenerator.generate` for the first two sections using `LlmEngine`. For each section: build prompt, stream, extract JSON, map into `LessonPlan`, run `PlanValidator.validateSection`, retry **once** with the exact issue messages, else emit `GenerationFailed` with the issues. Grounded fields are copied from the request (H1). The Learning Experience flow may be generated **stage by stage** (a stage per call) if one call would exceed the token budget.
**Verify test (FakeEngine with scripted JSON):** a good response completes; a response with wrong minutes triggers one retry that contains the minutes message; two bad responses fail; competencies in the result equal the request.
**Commit:** `feat(core): LLM generator for intentions and learning experience`

### T5.7 `LlmLessonGenerator`: Assessment, Ways Forward, `generateSection` (strong)
**Files:** `lib/core/generation/llm_lesson_generator.dart`, `lib/core/generation/section_runner.dart`, `test/llm_generator_test.dart`.
**Do:** the last two sections, `GenerationCompleted`, and `generateSection(...)` including `gradeLabel` slices through `replaceSection`. Cancel stops the engine.
**Verify test:** full plan from scripted responses passes `PlanValidator` with zero errors; per-grade regeneration changes only that grade.
**Commit:** `feat(core): LLM generator for assessment, ways forward and section regeneration`

### T5.8 Backend selection and live preview [9B]
**Files:** `lib/core/providers.dart`, `lib/features/settings/settings_screen.dart`, `lib/features/generator/generation_controller.dart`.
**Do:** a setting "Demo / Local model / (debug only) dev endpoint". Local model is the default when a model is installed. Show streamed text and the section name during generation. Show a clear "Generating may take several minutes on this phone" estimate once the benchmark number exists. Keep the screen on during generation.
**Verify:** with `FakeEngine`, the controller emits the expected events. By hand: toggle backends.
**Commit:** `feat(ui): backend selection and live generation preview`

### T5.9 Evaluation harness (strong)
**Files:** `tool/eval.dart`, `test/eval/requests.json`, `working_docs/eval_results.md`.
**Do:** 10 fixed requests (2, 3, 4 and 6 grades; Filipino and English; 60, 90 and 120 minutes; one monograde if supported). `dart run tool/eval.dart --endpoint http://localhost:8080` runs each request through `LlmLessonGenerator` over `HttpLlmEngine` against the **production GGUF** served by `llama-server` on your desktop, with a fixed seed, and writes pass/fail per validator code.
**Verify:** the script runs against `FakeEngine` and prints a table.
**Commit:** `feat(tool): evaluation harness`

### T5.10 Prompt tuning rounds (human with agent)
Run the eval, change **one** prompt thing at a time, rerun. Keep a change log in `eval_results.md`. Target: at least 8 of 10 requests pass with zero validation errors on the production model. Then rerun the same 10 on the phone once, to confirm the device matches the desktop.
**Teacher review:** a real teacher rates three plans (usable / light edits / unusable) and notes what they change. Record it.

### Phase 5 acceptance (human, on the phone)
- [ ] A 2-grade and a 4-grade plan generate offline on the phone, in Filipino and in English.
- [ ] 8 of 10 evaluation requests pass validation (desktop run), and a phone spot check agrees.
- [ ] Regenerate a section and one grade's cell with the real model; undo works.
- [ ] No grounded field (standards, competencies, header) differs from the form.
- [ ] A teacher calls at least 2 of 3 plans usable with light edits.
- [ ] Peak memory and full-plan time are recorded.

---

## Phase 6: Chat assistant (guided slot-filling)

Spec feature 3 asks for "chat with an offline AI assistant". With a 4B model on a phone, free-form chat that writes whole plans would hallucinate and be slow. Chat mode here **collects the form fields conversationally**, shows the filled form for confirmation, then runs the same pipeline as form mode. If you want broader chat, say so before this phase (Q4).

### T6.1 Chat session model and storage [9B]
**Files:** `lib/core/chat/chat_session.dart`, `lib/services/database/chat_repository.dart`, `test/chat_repository_test.dart`.
**Do:** `ChatSession` (id, created, messages, draft `GenerationRequest` fields). A new Drift table for sessions, so this card includes a schema bump and migration (use the harness from T2.16). A conversation is capped (last 12 messages sent to the model).
**Verify test:** save and reload a session; migration from the previous schema keeps all plans.
**Commit:** `feat(db): chat session storage`

### T6.2 Slot-filling prompt and parser (strong)
**Files:** `lib/core/chat/slot_filler.dart`, `lib/core/chat/slot_schema.dart`, `test/slot_filler_test.dart`.
**Do:** each user message goes to the model with the current draft fields; the model replies with a short Filipino/English message **and** a JSON patch of the form fields it understood. The app validates the patch (required fields, grade counts 2 to 6, numeric ranges), merges it, and asks for the next missing field. The model never invents values; unknown stays empty.
**Verify test (FakeEngine):** "Grade 3 and 4, Science, 90 minutes" fills three fields; invalid values rejected; unrelated chat does not change fields.
**Commit:** `feat(core): conversational slot filling`

### T6.3 Chat UI [9B]
**Files:** `lib/features/assistant/assistant_screen.dart`, `lib/features/assistant/chat_bubble.dart`, `test/assistant_screen_test.dart`.
**Do:** message list, input box, a "form so far" summary card with edit buttons, quick-reply chips for the next missing field. Replaces the "Coming soon" placeholder.
**Verify:** widget test: sending a message shows the assistant reply from `FakeEngine` and updates the summary.
**Commit:** `feat(ui): chat assistant screen`

### T6.4 Chat to generation bridge [9B]
**Files:** `lib/features/assistant/assistant_screen.dart`, `lib/features/generator/generator_form_state.dart`, `test/chat_bridge_test.dart`.
**Do:** a "Generate" button once required fields are complete, or "Open in form" to continue by hand. Both build the same `GenerationRequest`.
**Verify test:** chat draft equals the form state; generating from chat produces the same request as the form.
**Commit:** `feat(ui): generate a plan from the chat draft`

### Phase 6 acceptance
- [ ] A teacher describes a class in chat (Filipino and English) and gets a filled form.
- [ ] Generated plan from chat passes validation like form mode.
- [ ] Chat history persists across restarts. History is capped so the prompt stays within budget.

---

## Phase 7: Export, import and sharing

### T7.0 Spike: `docs_gee` on Android (strong, 1 hour)
**Files:** `working_docs/docx_spike.md`.
**Do:** build the sample ILAW layout with `docs_gee`. Open the result in Word and LibreOffice. Check page orientation, margins, footer, repeating header rows, colSpan/rowSpan for whole-class rows, banner shading, `✓`/`✗` glyphs. If something is missing, patch the DOCX zip with the `archive` package.
**Verify:** the doc lists what works, what is patched, and one rendered screenshot per section.

### T7.1 DOCX builder: header and Intentions (strong)
**Files:** `lib/services/export/docx/docx_header.dart`, `lib/services/export/docx/docx_intentions.dart`, `test/docx_header_test.dart`.
**Do:** title, 4-column header table, I banner, standards table, competencies, objectives per scaffold section 7 (renderer parity).
**Verify test:** unzip the output, parse `document.xml`, check table shape and banner color `1F3864`.
**Commit:** `feat(export): docx header and intentions`

### T7.2 DOCX builder: Learning Experience and Flow (strong)
**Files:** `lib/services/export/docx/docx_learning.dart`, `lib/services/export/docx/docx_flow.dart`, `test/docx_flow_test.dart`.
**Do:** learner context, materials, references, flow table with merged whole-class rows.
**Verify test:** a whole-class stage has one merged cell spanning all grade columns for 2, 4 and 6 grades.
**Commit:** `feat(export): docx learning experience and flow table`

### T7.3 DOCX builder: Assessment, Ways Forward, signatures, assembly (strong)
**Files:** `lib/services/export/docx/docx_assessment.dart`, `lib/services/export/docx/docx_exporter.dart`, `test/docx_exporter_test.dart`.
**Do:** remaining sections, signature blocks, AI use declaration, and `DocxExporter.export(plan)` returning bytes.
**Verify test:** export the fixture, unzip, every banner and section title present in order.
**Commit:** `feat(export): complete docx exporter`

### T7.4 PDF exporter (strong)
**Files:** `lib/services/export/pdf/pdf_exporter.dart`, `lib/services/export/pdf/pdf_tables.dart`, `test/pdf_exporter_test.dart`.
**Do:** same layout with the `pdf` package and the bundled Noto Sans. Landscape A4 or Letter. Long tables paginate with repeated header rows. Uses the same `LessonPlan` model.
**Verify test:** PDF bytes start with `%PDF`, have at least one page, and a 6-grade plan does not throw.
**Commit:** `feat(export): pdf exporter`

### T7.5 Export flow and validation gate [9B]
**Files:** `lib/features/plan_view/export_sheet.dart`, `lib/features/plan_view/plan_workspace.dart`, `test/export_sheet_test.dart`.
**Do:** Export button → choose DOCX or PDF → if validation errors exist, show them with "Export anyway" (D12) → save through the system file picker's save dialog or the share sheet. No storage permission. Snackbar with the result.
**Deps:** `share_plus` only if `file_picker` cannot save (human approves).
**Verify test:** with errors present, the gate appears; "Export anyway" proceeds. By hand: export, open in a phone Word or PDF viewer.
**Commit:** `feat(ui): export sheet with validation gate`

### T7.6 `.lms` bundle: export (strong)
**Files:** `lib/services/sharing/lms_bundle.dart`, `lib/services/sharing/lms_manifest.dart`, `test/lms_bundle_test.dart`.
**Do:** a zip (`archive` package, already present) with `manifest.json` (`bundleVersion`, `appVersion`, `createdAt`, counts, per-file SHA-256), `plans/<uuid>.json`, `notes.json`, `bibliography.json`. Select one or many plans. Never includes the model.
**Verify test:** build, unzip, hashes match; the bundle of 3 plans lists 3 files.
**Commit:** `feat(sharing): lms bundle export`

### T7.7 `.lms` bundle: import (strong)
**Files:** `lib/services/sharing/lms_import.dart`, `lib/features/library/import_dialog.dart`, `test/lms_import_test.dart`.
**Do:** pick a `.lms` file (system file picker, so it works from a USB OTG drive or SD card), verify manifest and hashes, reject a newer `bundleVersion` with a clear message, preview contents, and import with duplicate handling (same id and same content: skip; same id, different content: import as copy). Plans load through the tolerant reader.
**Verify test:** round trip between two in-memory databases; tampered file rejected; duplicate import creates no duplicate row.
**Commit:** `feat(sharing): lms bundle import with duplicate handling`

### T7.8 Library import/export UI [9B]
**Files:** `lib/features/library/library_screen.dart`, `lib/features/library/import_dialog.dart`, `test/library_share_test.dart`.
**Do:** multi-select in the library, "Export selected as .lms", "Import .lms" in the app bar.
**Verify:** widget test with fakes; by hand: export from phone A, copy via USB drive, import on phone B (or the desktop build).
**Commit:** `feat(ui): library sharing actions`

### Phase 7 acceptance (human)
- [ ] DOCX opens in Word and LibreOffice with correct banners and merged rows (2, 4 and 6 grades).
- [ ] PDF opens on the phone and prints cleanly.
- [ ] A `.lms` bundle moves through a real USB OTG flash drive or SD card to a second device and imports.
- [ ] Exports work in airplane mode.
- [ ] The app asks for no storage permission.

---

## Phase 8: Hardening and release APK

### T8.1 Release build config (strong)
**Files:** `android/app/build.gradle(.kts)`, `android/app/proguard-rules.pro`, `android/key.properties.example`.
**Do:** release signing from a keystore **you** create (never in git), R8 keep rules for the FFI library, `abiFilters` arm64-v8a, `flutter build apk --release`. Check the APK size.
**Verify:** the release APK installs and generates a plan on the phone.
**Commit:** `build(android): release signing and shrinking`

### T8.2 Diagnostics log [9B]
**Files:** `lib/core/logging/app_log.dart`, `lib/features/settings/diagnostics_screen.dart`, `test/app_log_test.dart`.
**Do:** a rolling local log (size capped, no learner names, no plan content), and an "Export diagnostics" bundle: device RAM, model id, engine state history, last 200 log lines.
**Verify test:** the log caps at its size; the export has no plan text.
**Commit:** `feat(core): diagnostics log and export`

### T8.3 Low-memory soak test (human)
- 20 consecutive generations on the 4 GB phone with the tier-A model, then with background apps open.
- Record low-memory kills, thermal throttling, battery drop per plan.
- Decide the final minimum supported RAM. Update `specifications.md` if it changes.

### T8.4 Documentation and handover (human with agent)
**Files:** `README.md`, `docs/user_guide.md`, `working_docs/PROGRESS.md`.
**Do:** install steps (APK sideload), model download, offline use, export/import, known limits (generation time, review every plan), and a Filipino one-page quick start (the human reviews the Filipino).
**Commit:** `docs: user guide and release notes`

### Phase 8 acceptance (MVP checklist from `specifications.md`)
- [ ] Features 1 to 7 verified on the 4 GB reference phone (or the documented minimum).
- [ ] Downloadable release APK.
- [ ] Documentation updated.
Then merge `dev1` to `main` and tag the release.

---

## Phase 9: Time-permitting and cost-permitting (not part of the MVP)

Each item needs a go decision from you first.

- **Voice-to-text (feature 8).** Candidates: Android's `SpeechRecognizer` through the `speech_to_text` package (offline use depends on installed language packs and Filipino support varies by device), or a small on-device Whisper model through a separate engine (extra RAM; do not run it alongside the LLM). Needs a feasibility spike on the 4 GB phone first, and the `RECORD_AUDIO` permission.
- **IPEd/Manobo context toggle (feature 9).** A form toggle plus a free-text "local context notes" field that is inserted into prompts under H7 rules. **The cultural content comes from the teacher or community, never from the model or the agent.** Without supplied notes the toggle does nothing, because a small model will produce stereotypes. Have a community reviewer check sample output.
- **Worksheets.** Only if Q3 says yes: a new generated artifact with its own schema, prompts, validators and exporter.
- **IMS package.** Only if Q2 identifies a concrete format.
- **Offline-first sync (feature 10).** Do not build accounts. First step: the app checks a signed manifest on your website for updated competency data and models when internet is available. Needs hosting and bandwidth decisions (Q5).
- **Windows build.** Resume only if you want teachers' laptops supported (D11).

---

## 10. Risk register

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | No model fits a 4 GB phone with acceptable Filipino quality. | High | Spike M early (Phase 4, before any prompt work). Decide tiers or raise the minimum. |
| R2 | Full-plan generation takes minutes on budget CPUs. | High | Generate stage by stage, show live preview, keep screen on, set honest expectations. Measure in Spike M. |
| R3 | Chosen FFI package is a prerelease or is abandoned. | Medium | `LlmEngine` boundary keeps the choice swappable. Pin the version. Keep a fallback from T4.1. |
| R4 | Android kills the app mid-generation or mid-download. | High | Draft autosave (T3.6), resumable downloads (T4.7), unload on pressure (T4.10). |
| R5 | Desktop prompt results do not match the phone. | Medium | Same GGUF on both, same seed and params. Phone spot check at the end of Phase 5. |
| R6 | Model licence or hosting limits redistribution. | Medium | Check each licence before hosting. Manifest allows replacing the model without an app update. |
| R7 | Small agent model loses track on cards that touch Gradle or Kotlin. | Medium | Those cards are tagged (strong). Keep cards at 3 files. |
| R8 | 32-bit-only budget phones cannot run the arm64 library. | Medium | T4.8 detects it and reports clearly. |
| R9 | The model writes wrong curriculum content. | High | H1 to H10, teacher review, grounded fields never generated. |

---

## 11. Open questions (answer before the phase named)

| # | Question | Needed before |
|---|---|---|
| Q1 | Is Windows still wanted, or is Android the only target? (D11) | Phase 8 |
| Q2 | What does "IMS packages" mean: IMS Common Cartridge, or just a file bundle? | Phase 7 |
| Q3 | Are "worksheets" a required MVP output? If yes, from what input and in what format? | Phase 7 |
| Q4 | Is guided slot-filling enough for "chat", or do you want broader chat about the plan? | Phase 6 |
| Q5 | Where will `models.json` and the model file be hosted, and who pays for bandwidth? | Phase 4 (T4.6) |
| Q6 | Which exact 4 GB phone is the reference device? Is a second, larger phone available? | Phase 3 (T3.0) |
| Q7 | Who is the teacher reviewer for Phase 5? Who reviews Filipino text and IPEd content? | Phase 5 |
| Q8 | Exact wording required for the AI use declaration? | Phase 7 |
| Q9 | Minimum Android version of the teachers' phones? (sets `minSdk`) | Phase 3 (T3.1) |

---

## 12. Standing manual checks (end of every phase)

1. `flutter analyze` clean, `flutter test` passes, `flutter build apk --debug` succeeds.
2. Run on the 4 GB phone: light and dark, font scale 1.3, rotate, 2 / 4 / 6 grades.
3. Airplane mode: everything except downloading still works.
4. Fresh install and upgrade-from-previous-database both open saved plans.
5. File-size check: list Dart files over 250 lines and schedule split cards.
6. `PROGRESS.md` under 30 lines and accurate.
7. Merge `dev1` to `main` only when 1 to 6 pass.

---

## 13. Suggested Cline settings for this plan

- Context window in Cline equal to the server's `-c` value, with Cline set to trim history before the server overflows.
- Keep your first Android and FFI cards (T3.1, T4.5, T4.7, T4.8, T4.10) on the stronger hosted model; use the local 9B for tagged **[9B]** cards.
- When the 9B fails a card twice, split the card instead of retrying a third time.
- Keep `working_docs/AGENTS.md` to about 40 lines: copy section 6 and the current-phase pointer, nothing else.