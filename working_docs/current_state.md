# Current State

## Repository Overview

**Platform**: Flutter Desktop (Linux/macOS/Windows) - Android not yet configured.
**Status**: Phase 0 complete - Core infrastructure and form generation ready.
**Tests**: 108 passing unit/widget tests.
**Schema Version**: 3 (gradeLevels, language, preparedByRole, checkedByRole, materials).

---

## Specification Feature Mapping

| Spec # | Feature | Status | Implementation Details |
|--------|---------|--------|------------------------|
| 1 | Android-Compatible | ❌ Not Started | App is Desktop-only. No `android/` directory. Requires full Android platform integration. |
| 2 | 4GB RAM Hardware Constraint | ❌ Not Started | Dependencies present but no `llama_cpp_dart` integration. Memory management absent. |
| 3 | Form/Chat Assistant Generation | ✅ Partial | **Form Mode**: Complete (generator, mock, UI). **Chat Mode**: Placeholder only. |
| 4 | Local AI Model Execution | ❌ Not Started | No `llama_cpp_dart` package, no model file handling, no streaming API. |
| 5 | DepEd ILAW Alignment | ✅ Complete | Full ILAW format in `ilaw_plan_view.dart`, correct banner colors (#1F3864, #2E6B2E, #8C5A1E, #7A2048), 4-column header table. |
| 6 | Cross-Device Import/Export | ❌ Not Started | Packages in pubspec.yaml unused. No USB/IMS implementation. |
| 7 | Document Export Formats | ❌ Not Started | `pdf`, `docs_gee` packages unused. No export code. |
| 8 | Voice-to-Text | ❌ Not Started | Not implemented. |
| 9 | IPEd/Manobo Context Toggle | ❌ Not Started | Not implemented. |
| 10 | Offline-First Cloud Sync | ❌ Not Started | Database is local-only. |

---

## Architecture Summary

### Core Models (`lib/core/models/lesson_plan.dart`)
- Schema v3: `gradeLevels`, `language`, `preparedByRole`, `checkedByRole`, `materials`
- Full ILAW section support

### Generation Layer (`lib/core/generation/`)
- `lesson_generator.dart`: Streaming interface with `GenerationEvent` pipeline
- `mock_lesson_generator.dart`: Development mock
- `generation_controller.dart`: `regenerateSection()` with `gradeLabel` parameter

### Database (`lib/services/database/`)
- Drift tables: `lesson_plans`, `reference_notes`, `bibliography`
- `plan_repository.dart`: CRUD with `update()` preserving `createdAt`

### UI Features
- **Shell**: `app_shell.dart` - NavRail (Library, Assistant, Settings)
- **Library**: `library_screen.dart` - List/savedId/New Plan flow
- **Generator**: Form-based creation with multigrade support
- **Workspace**: `plan_workspace.dart` - Save/Undo/Clone, dirty indicator
- **View**: `ilaw_plan_view.dart` - Reference ILAW renderer
- **Validation**: Modular validators with stable error codes

### State Management
- Riverpod 2.x, `providerScope.keepAlive()` for editor state
- `generation_controller.dart` manages streaming generation

---

## Android Implementation Checklist (per ai_implementation_spec.md)

Before claiming Features 1-4 complete:
- [ ] Add `android/` directory
- [ ] Configure `build.gradle` for `llama_cpp_dart` AAR
- [ ] Add `llama_cpp_dart: ^0.9.x` dependency
- [ ] Implement model download with progress/checksum
- [ ] Add `INTERNET` permission (no external storage)
- [ ] Store model in app-private directory
- [ ] Implement `LlamaService` with streaming, background isolate
