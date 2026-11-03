# Progress

## Phase 0 - Repository Reconciliation (dev1 branch)

**Status:** dev1 branch is checked out. `main` and `dev1` branches exist.

### Completed Tasks:
- P0.2: Moved unverified AI code to `lib/services/ai/legacy/`
- P0.3: Fixed dependencies - removed `llama_cpp_dart`, added `file_picker`
- P0.4: Added Noto Sans fonts (Regular, Bold) to `assets/fonts/`
- P0.5: Fixed hardcoded path in `utils.dart` - now uses `path_provider`
- P0.6: Replaced default counter test with smoke test verifying app title
- P0.7: Verified clean build - `flutter analyze` passes, `flutter test` passes, `flutter build linux` produces binary

**Next task:** Phase 1 T1.1 (Domain model)