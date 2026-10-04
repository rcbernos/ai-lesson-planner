# Phase 0: Dev 1 Commit Plan
**Branch:** `feature/scaffolding`

---

## Overview

This document outlines the step-by-step plan for Dev 1 to establish the base repository, folder structures, documentation framework, and foundational configuration for the Offline AI Lesson Plan Assistant project.

---

## 📋 Tasks to Execute

### Task 1: Initialize Git Repository & Directory Structure

1. **Initialize the Git repository:**
   ```bash
   git init
   git checkout -b main
   ```

2. **Create the root directory architecture:**
   - Create `/lib` directory
   - Create `/lib/core` directory (for core logic, utilities, constants)
   - Create `/lib/features` directory (for feature-based modules)
   - Create `/lib/services` directory (for external integrations, models)

3. **Ensure `/working_docs/` directory exists** (already created)

**Commit Message:** `feat: initialize repository with directory scaffolding`

---

### Task 2: Create Foundational Flutter Project Structure

1. **Create initial Flutter project files:**
   - Create `pubspec.yaml` with all required dependencies:
     - `drift` (SQLite ORM)
     - `riverpod` (state management)
     - `llama_cpp_dart` ^0.2.2 (local LLM inference)
     - `archive ^4.0.2` (archive file handling)
     - `pdf ^3.13.1` (PDF generation)
     - `path_provider` (file system paths)
      - `docs_gee` ^1.5.0 (DOCX generation)
      - `uuid` ^4.5.1 (UUID generation)
      - `flutter` (Flutter SDK)
   
   - Create `main.dart` entry point in `/lib/`
   
   - Create basic project structure files:
     - `/lib/main.dart`
     - `/lib/core/app_config.dart`
     - `/lib/core/utils.dart`
     - `/lib/features/home/` (placeholder)
     - `/lib/services/` (placeholder)

2. **Add flutter packages:**
   ```bash
   flutter pub get
   ```

**Commit Message:** `feat: add Flutter project with initial dependencies`

---

### Task 3: Create Documentation Tracking Templates

Create the following markdown templates inside `/working_docs/`:

| File | Purpose |
|------|---------|
| `commit_log.md` | Log of all commits with descriptions |
| `task_template.md` | Standard task tracking template |
| `verification_checklist.md` | Checklist for task verification |
| `dev1_progress.md` | Dev 1's progress tracking |
| `branch_strategy.md` | Git branching strategy documentation |

**Commit Message:** `docs: add documentation tracking templates`

---

### Task 4: Push Initial Commit to Main

1. **Create initial `.gitignore` file** (ignore Flutter artifacts, IDE files)
2. **Stage all files:**
   ```bash
   git add .
   ```

3. **Create initial commit:**
   ```bash
   git commit -m "chore: initial commit - Phase 0 scaffolding complete

   - Repository initialized with Flutter project structure
   - Core directory structure created (/core, /features, /services)
   - All required dependencies added to pubspec.yaml
   - Documentation tracking templates added
   - .gitignore configured for Flutter desktop project"
   ```

4. **Push to remote main branch:**
   ```bash
   git remote add origin <repository-url>
   git push -u origin main
   ```

**Commit Message:** (merged above)

---

## ✅ Human Verification Checklist

Before completing Phase 0, verify all items:

- [ ] Repository exists on `main` with the complete `/working_docs/` directory and tracking files in place.
- [ ] All project dependencies in `pubspec.yaml` resolve cleanly with `flutter pub get`.
- [ ] A blank Flutter desktop app builds and runs successfully via `flutter run`.

---

## 📢 Post-Commit Notification

After pushing the initial commit, Dev 1 must notify Devs 2 and 3 that they can:

1. Clone the repository
2. Create their respective branches:
   - Dev 2: `feature/database`
   - Dev 3: `feature/ui-shell`
3. Fill out their commit plans in:
   - `working_docs/phase1_dev2_commitplan.md`
   - `working_docs/phase1_dev3_commitplan.md`

---

## 📊 Expected Outcome

After Phase 0 completion, the repository will have:

```
📁 ai-lesson-planner/
├── 📁 lib/
│   ├── 📁 core/
│   │   ├── app_config.dart
│   │   └── utils.dart
│   ├── 📁 features/
│   ├── 📁 services/
│   └── main.dart
├── 📁 working_docs/
│   ├── phase0_complete_dev_plan.md
│   └── commit_log.md
├── pubspec.yaml
└── .gitignore
```

---

## 🔄 Phase 0 Merge Milestone

Dev 1 completes Phase 0, establishing the foundational repository for all developers to begin their parallel development work.

---

## Notes

- All dependencies should use exact versions for consistency across the team
- The `/working_docs/` directory should contain all tracking files
- Ensure the app builds for desktop (Windows/Linux) as primary target

---

## ✅ Phase 0 Completion Status

**Date Completed:** 2026-10-04

### Completed Tasks
- [x] Initialize Git repository with main branch
- [x] Create directory structure (`/lib/core`, `/lib/features`, `/lib/services`)
- [x] Create `pubspec.yaml` with all required dependencies
- [x] Create `main.dart` entry point
- [x] Create tracking templates in `/working_docs/`
- [x] Create `.gitignore` file
- [x] Push initial commit to main

### Initial Commit Details
```
commit 79e2425 (HEAD -> main)
chore: initial commit - Phase 0 scaffolding complete
```

Devs 2 and 3 can now proceed with their Phase 1 tasks.
