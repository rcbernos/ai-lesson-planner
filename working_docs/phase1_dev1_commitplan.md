## Summary of Current State

**Project Status:**
- Phase 0 (Scaffolding) has been completed
- Git repository initialized with commits on `main` and `dev1` branches
- Basic Flutter project structure exists with `/lib/core/` containing `app_config.dart` and `utils.dart`
- `pubspec.yaml` has all required dependencies (Drift, Riverpod, llama_cpp_dart, pdf, docs_gee, etc.)
- `/working_docs/` directory exists with various tracking templates
- `phase1_dev1_commitplan.md` file has been populated with the complete commit plan

**Phase 1 Dev 1 Requirements (from the finalized dev plan):**
- **Branch:** `feature/ai-engine`
- **Tasks:**
  1. Hardcode the official DepEd **ILAW Format** as a string constant
  2. Write absolute file-path resolver using `path_provider` for GGUF model weights
  3. Implement automatic model download from remote URL with checksum verification
  4. Integrate `llama_cpp_dart` running in a background `compute` isolate
- **Verification Checklist:**
  - App resolves absolute path of GGUF model file on startup
  - If model is missing, app downloads it and verifies checksum
  - Test token generation works in background isolate

---

## commit plan for phase 1 dev 1

Based on the development plan and the existing project structure, here's the **commit plan for Phase 1 Dev 1** that should replace the empty `phase1_dev1_commitplan.md` file:

---

# Phase 1 Dev 1 Commit Plan

**Branch:** `dev1`

---

## Overview

This document outlines the step-by-step plan for Dev 1 to implement the LLM Asset Manager & Path Resolver for the Offline AI Lesson Plan Assistant. This includes the ILAW format constant, GGUF model path resolution, automatic model download with checksum verification, and background isolate integration for non-blocking token generation.

---

## 📋 Tasks to Execute

### Task 1: Update ILAW Format Constant

1. **Update the ILAW format in `app_config.dart`:**
   - Ensure the hardcoded ILAW format (Intentions, Learning Experiences, Assessing Learning, Ways Forward) is complete
   - Verify the AI Use Declaration footer is present

**Commit Message:** `feat: complete ILAW format constant with AI declaration`

---

### Task 2: Implement GGUF Model Path Resolver and Auto-Download

1. **Create `lib/services/ai_service.dart`:**
   - Add path resolution logic using `path_provider`
   - Create method to resolve absolute path of GGUF model file
   - Add `downloadModel()` method to fetch GGUF from remote URL
   - Implement checksum verification for downloaded file integrity
   - Add download progress reporting callback
   - Ensure cross-platform compatibility (Windows/Linux)

2. **Update `app_config.dart`:**
   - Add model path configuration constants
   - Add model download URL constant
   - Add model file size and checksum constants
   - Add download configuration helper methods

**Commit Message:** `feat: add GGUF model path resolver with auto-download capability using path_provider and http`

---

### Task 3: Integrate llama_cpp_dart Background Isolate

1. **Implement AI inference in `ai_service.dart`:**
   - Create `generateLessonPlan()` method using `llama_cpp_dart`
   - Wrap token generation in `compute()` for background execution
   - Add proper error handling and logging

2. **Create AI service provider for Riverpod:**
   - Create `lib/services/providers/ai_providers.dart`
   - Add provider for AI service management

**Commit Message:** `feat: integrate llama_cpp_dart in background isolate`

---

### Task 4: Verify Implementation & Push

1. **Run verification tests:**
   - Verify model path resolution works without errors
   - Test token generation in background isolate
   - Ensure no UI thread freezing

2. **Push branch:**
   - Push `feature/ai-engine` branch to remote

**Commit Message:** `test: verify AI engine path resolution and isolate execution`

---

## ✅ Human Verification Checklist

Before completing Phase 1 Dev 1, verify all items:

- [ ] The app successfully resolves the absolute path of the local GGUF model file on startup without throwing path-not-found exceptions.
- [ ] If model is missing, the app automatically downloads the GGUF file from the configured URL and verifies checksum integrity.
- [ ] A test token generation call fires in a background isolate and returns text to the console without freezing the UI thread.

---

## 📊 Expected Outcome

After Phase 1 Dev 1 completion, the repository will have:

```
📁 lib/
├── 📁 core/
│   ├── app_config.dart (updated with ILAW format, model config, and download URL)
│   └── utils.dart
├── 📁 features/
│   └── ai-engine/ (placeholder for feature integration)
├── 📁 services/
│   ├── ai_service.dart (new - path resolver, download manager, and background isolate)
│   ├── downloads.dart (new - download with checksum verification)
│   └── providers/
│       └── ai_providers.dart (new - Riverpod providers)
└── main.dart
```

---

## 🔄 Phase 1 Merge Milestone

Dev 1 completes the AI Engine feature, establishing:

- ILAW format as a string constant
- Cross-platform GGUF model path resolution with automatic download
- Download verification with checksum integrity
- Non-blocking AI inference via background isolate

---

## Notes

- All changes must be backward compatible
- Use conventional commits format: `feat(scope): description`
- Test on both Windows and Linux if possible
- Ensure proper error handling for missing model files and download failures
- Handle offline scenarios gracefully with appropriate user notifications
- Verify downloaded file checksums match expected values

---

## ✅ Phase 1 Dev 1 Completion Status

**Date:** 2026-10-05

### Completed Tasks
- [ ] Update ILAW format constant in `app_config.dart`
- [ ] Create `ai_service.dart` with path resolution and download capability
- [ ] Implement model download with checksum verification
- [ ] Implement background isolate for token generation
- [ ] Create AI providers for Riverpod
- [ ] Verify all acceptance criteria