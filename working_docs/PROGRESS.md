# Progress

## Phase 0.1 - Repository Reconciliation

**Status:** dev1 branch is checked out. `main` and `dev1` branches exist.

### Completed Tasks:
- P0.2: Moved unverified AI code to legacy directory
  - `lib/services/ai_service.dart` → `lib/services/ai/legacy/ai_service.dart`
  - `lib/services/downloads.dart` → `lib/services/ai/legacy/downloads.dart`
  - `lib/services/providers/ai_providers.dart` → `lib/services/ai/legacy/ai_providers.dart`
  - Updated `lib/services/index.dart` to export only database services
  - No imports of moved files remain in codebase (verified)
  - `lib/services/providers/` directory removed (empty)
  - Test file updated to import from legacy location

**Next task:** P0.3 - Fix dependencies