# AI Lesson Plan Assistant

**Offline AI Lesson Plan Assistant for DepEd Teachers**

This Flutter desktop application helps teachers generate lesson plans using local AI models. It operates entirely offline, ensuring privacy and accessibility in areas with limited internet connectivity.

## ⚠️ PROJECT STATUS: Phase 0 - Scaffolding Complete

**This project is in early scaffold phase.** The codebase contains foundational setup only - application logic, database integration, and AI functionality are NOT yet implemented. See Development Phases for details.

## Table of Contents

- [Overview](#overview)
- [Current Status](#current-status)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Development Phases](#development-phases)
- [Architecture](#architecture)
- [Dependencies](#dependencies)
- [Remaining Work](#remaining-work)

## Overview

This project plans to implement an offline lesson planning tool that integrates:
- **LLM Integration**: Local GGUF model support via `llama_cpp_dart`
- **Database**: Drift/SQLite for lesson plans, references, and bibliographies
- **Export**: PDF, DOCX, and custom `.lms` formats
- **UI**: Riverpod state management with responsive desktop navigation

The application follows the **ILAW Format** (Intentions, Learning Experiences, Assessing Learning, Ways Forward) with an AI Use Declaration footer.

## Current Status

**Phase: 0 (Scaffolding Complete)**

The repository has been initialized with:
- ✅ Flutter project structure with `/lib/core/`, `/lib/features/`, `/lib/services/` directories
- ✅ `pubspec.yaml` with all required dependencies (drift, llama_cpp_dart, pdf, docs_gee, etc.)
- ✅ Core configuration (`app_config.dart`) with ILAW format template
- ✅ Utility functions (`utils.dart`) for path resolution
- ✅ Basic Flutter app entry point (`main.dart`) - shows simple text screen
- ✅ Documentation framework in `/working_docs/`
- ✅ `.gitignore` configured for Flutter desktop projects

**NOT YET IMPLEMENTED:**
- ❌ Database layer (Drift/SQLite tables and operations)
- ❌ AI model integration (llama_cpp_dart)
- ❌ Export functionality (PDF, DOCX, .lms)
- ❌ Feature-specific UI modules
- ❌ Service layer integrations

## Prerequisites

### System Requirements

- **Flutter SDK**: 3.19.0 or later
- **Dart SDK**: 3.0.0+
- **Operating System**: Windows 10+, macOS 10.15+, or Linux (x64)
- **Desktop Dependencies**:
  - Windows: CMake and Visual Studio Build Tools
  - macOS: Xcode Command Line Tools
  - Linux: Build essentials (`build-essential`), CMake

### Verify Your Setup

```bash
flutter --version
dart --version
git --version
