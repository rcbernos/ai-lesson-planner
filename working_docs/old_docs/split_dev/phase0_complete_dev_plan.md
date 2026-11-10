# Finalized Phase-Based Development Plan (Offline AI Lesson Plan Assistant)

## Phase 0: Repository Scaffolding & Documentation Framework

*Goal: Dev 1 establishes the base repository, folder structures, the `/working_docs/` tracking framework, and foundational configuration so the team can clone and branch.*

### 🛠️️ Dev 1: Repository Initialization & Documentation Scaffolding (`feature/scaffolding`)

* **Tasks:**
* Initialize the Git repository, establish the root `/lib` architecture (`/core`, `/features`, `/services`), and create the `/working_docs/` directory.
* Add the foundational markdown tracking templates inside `/working_docs/`.
* Add required dependencies to `pubspec.yaml` (Drift, Riverpod, `llama_cpp_dart` ^0.2.2, `archive` ^4.0.2, `pdf` ^3.13.1, `docs_gee` ^1.5.0, `uuid` ^4.5.1, `http` ^1.1.0, `crypto` ^3.0.0, etc.) so all devs share exact package versions.
* Push the initial commit to `main` and notify Devs 2 and 3 that they can clone, branch, and fill out their respective commit plans as their very first action.


* **✅ Human Verification Checklist:**
* [ ] Repository exists on `main` with the complete `/working_docs/` directory and tracking files in place.
* [ ] All project dependencies in `pubspec.yaml` resolve cleanly with `flutter pub get`.
* [ ] A blank Flutter desktop app builds and runs successfully via `flutter run`.



---

## Phase 1: Local Data, Asset Management, & UI Shell

*Goal: With the repo initialized, Devs 1, 2, and 3 work in parallel on isolated branches to build the core building blocks.*

### 🛠️ Dev 1: LLM Asset Manager & Path Resolver (`feature/ai-engine`)

* **Tasks:**
* Hardcode the official DepEd **ILAW Format** (Intentions, Learning Experiences, Assessing Learning, Ways Forward) with an AI Use Declaration footer as a string constant.
* Write the absolute file-path resolver using `path_provider` to ensure `llama_cpp_dart` can locate the SEA-LION GGUF weights safely across Windows/Linux sandboxes.
* Implement automatic model download from remote URL if GGUF file doesn't exist locally, with checksum verification.
* Integrate `llama_cpp_dart` running inside a background `compute` isolate for non-blocking token generation.


* **✅ Human Verification Checklist:**
* [ ] The app successfully resolves the absolute path of the local GGUF model file on startup without throwing path-not-found exceptions.
* [ ] If model is missing, the app downloads the GGUF file from the configured URL and verifies checksum.
* [ ] A test token generation call fires in a background isolate and returns text to the console without freezing the UI thread.



### 🛠️ Dev 2: Database Layer & First-Run Seeding (`feature/database`)

* **Tasks:**
* Set up **Drift / SQLite** locally using `path_provider`.
* Define database schemas for generated lesson plans, custom teacher reference notes, and structured bibliography metadata (Author, Title, Year).
* Implement the **First-Run Seeding Hook** so that an empty local environment auto-populates required default structures on initial launch.


* **✅ Human Verification Checklist:**
* [ ] The local SQLite database file is successfully created in the application support directory upon first launch.
* [ ] Tables for lesson plans, reference notes, and bibliography metadata read and write correctly.
* [ ] Deleting the local database file and restarting the app successfully triggers the auto-seeding hook without crashing.



### 🛠️ Dev 3: UI Skeleton, Riverpod & Navigation Shell (`feature/ui-shell`)

* **Tasks:**
* Scaffold the main Flutter desktop navigation shell and layout structure using **Riverpod** for global state management.
* Build clean placeholder screens for the Lesson Plan Generator, Chatbot, and Resource Library.


* **✅ Human Verification Checklist:**
* [ ] The desktop app launches with a responsive multi-pane navigation layout.
* [ ] Riverpod providers initialize cleanly without scope injection errors.
* [ ] Clicking between navigation tabs smoothly switches views across all placeholder screens.



> **🔄 Phase 1 Merge Milestone:** Dev 1 pulls `feature/ai-engine`, `feature/database`, and `feature/ui-shell` into `main`, resolves conflicts, and pushes a unified stable build.

---

## Phase 2: Core Features & Manual Reference Inputs

*Goal: Connect UI forms, manual reference notes/bibliographies, multi-grade toggles, and the LLM generation engine.*

### 🛠️ Dev 1: Prompt Engineering & AI Worker Integration (`feature/ai-prompt`)

* **Tasks:**
* Write the prompt construction service that merges the hardcoded ILAW template, teacher inputs, manual reference notes, and bibliography data into a structured payload for SEA-LION.
* Implement streaming response handling from the background isolate to the UI state.


* **✅ Human Verification Checklist:**
* [ ] Passing dummy form inputs and reference notes into the prompt builder yields a correctly formatted ILAW output string.
* [ ] LLM text generation streams back updates incrementally without locking up application memory.



### 🛠️ Dev 2: Reference Notes & Bibliography Input UI/Logic (`feature/references`)

* **Tasks:**
* Build Drift data operations for saving, updating, and retrieving custom **Reference Notes** and **Bibliography Entries**.
* Build the Flutter form fields allowing teachers to input, edit, and attach multiple reference notes and citations to a target lesson plan draft.


* **✅ Human Verification Checklist:**
* [ ] Teachers can successfully type/paste manual reference notes and structured bibliography fields into the UI.
* [ ] Entering data and saving persists the records accurately in SQLite across application restarts.



### 🛠️ Dev 3: Generator Form & Chatbot Screen Wiring (`feature/generator-ui`)

* **Tasks:**
* Wire up the primary Lesson Plan Generator form—including the **Multi-Grade Toggle** (splitting inputs for Grade A and Grade B parallel tracks).
* Build the offline conversational chatbot UI, connecting it to local database records for context retrieval.


* **✅ Human Verification Checklist:**
* [ ] Toggling the multi-grade option dynamically reveals parallel grade input fields in the generator form.
* [ ] Submitting the generator form triggers the background AI worker and displays the streaming output in real-time.
* [ ] The offline chatbot interface renders message bubbles correctly and accepts local queries.



> **🔄 Phase 2 Merge Milestone:** Dev 1 pulls all Phase 2 feature branches into `main`, links database inputs to the AI worker, and verifies end-to-end generation.

---

## Phase 3: Export Pipelines & P2P USB Sharing

*Goal: Build document exporters, `.lms` zip packaging, and directory saving mechanisms in parallel.*

### 🛠️ Dev 1: Custom `.lms` P2P Bundle Engine (`feature/p2p-bundle`)

* **Tasks:**
* Implement the custom **`.lms` file format generator and parser** using Dart's native `archive` package.
* Bundle lesson plan text, reference notes, and bibliography metadata into a compressed zip payload with the `.lms` extension.


* **✅ Human Verification Checklist:**
* [ ] Exporting a lesson plan creates a valid `.lms` file in memory.
* [ ] Importing a `.lms` file successfully unpacks and restores the lesson plan text, notes, and bibliography into the local SQLite database.



### 🛠️ Dev 2: Exporters (`.docx` & PDF) (`feature/exporters`)

* **Tasks:**
* Build pure-Dart document export tools using the `pdf` package (v3.13.1) for professional layout rendering.
* Implement DOCX generation using `docs_gee` package for Word document exports with HTML structural formatting.
* Ensure AI Use Declaration and bibliography sections anchor cleanly at the bottom of exports.


* **✅ Human Verification Checklist:**
* [ ] Generating a PDF export builds a readable document complete with formatted headers and bibliographies without external printer dependencies.
* [ ] Generating a `.docx` export creates an editable file that opens correctly in standard word processors.



### 🛠️️ Dev 3: Export UI & Directory Binding (`feature/export-ui`)

* **Tasks:**
* Configure local file writing via `path_provider` to target the predictable `/LMS_Data/Exports/` directory.
* Build user-facing export buttons and status snackbars across the generation and library screens.


* **✅ Human Verification Checklist:**
* [ ] Clicking export successfully writes the `.pdf`, `.docx`, or `.lms` file into the physical `/LMS_Data/Exports/` folder on the local machine.
* [ ] The UI displays a clear success message pointing to the file save location.



> **🔄 Phase 3 Merge Milestone:** Dev 1 pulls export, bundle, and UI branches into `main`, verifying file creation pipelines.

---

## Phase 4: Offline Updates, Diagnostics, & Final Packaging

*Goal: Finalize local bug logging, USB update scanning, package the desktop installer, and run the final release merge.*

### 🛠️ Dev 1: Final Integration Merge & Release Prep (`main`)

* **Tasks:**
* Pull Dev 2 (`feature/diagnostics`) and Dev 3 (`feature/installer`) branches into `main`.
* Run full end-to-end integration tests on the unified build before final packaging.


* **✅ Human Verification Checklist:**
* [ ] Final merge into `main` compiles with zero errors on all target environments.
* [ ] A fresh clean checkout builds and runs the entire application workflow without regressions.



### 🛠️ Dev 2: Local Diagnostics & Bug Logging Module (`feature/diagnostics`)

* **Tasks:**
* Implement a local SQLite table capturing application state errors, exceptions, and crash logs.
* Build an interface screen allowing teachers to export a text-based diagnostic summary package if they reach an internet hotspot.


* **✅ Human Verification Checklist:**
* [ ] Simulated application errors write descriptive log entries into the SQLite diagnostics table.
* [ ] Teachers can export the accumulated log file locally via the UI.



### 🛠️ Dev 3: Installer Packaging & USB Update Scanner (`feature/installer`)

* **Tasks:**
* Configure native desktop packaging targets (MSIX for Windows / AppImage or `.deb` for Linux) to bundle the app binary, SQLite seed database, and SEA-LION GGUF weights into a single executable installer package.
* Implement folder-scanning logic checking a plug-in USB drive (`/LMS_Data/Updates/`) for offline version patches or database updates on boot.


* **✅ Human Verification Checklist:**
* [ ] Running the packaging script produces a working installer package that successfully embeds model weights and assets.
* [ ] Placing a mock update manifest or database patch inside a test folder triggers the app's local update scanner successfully.



> **🚀 Final Release Merge:** Dev 1 merges Phase 4 components, and the application is ready for field deployment.