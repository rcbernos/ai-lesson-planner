# Verification Checklist

## Phase 0 Verification

Before completing Phase 0, verify:

- [ ] Repository exists on `main` with the complete `/working_docs/` directory
- [ ] All project dependencies resolve cleanly
- [ ] A blank Flutter desktop app builds and runs successfully

---

## Phase 1 Verification (Dev 1 - AI Engine)
- [ ] App resolves absolute path of local GGUF model file
- [ ] Test token generation works in background isolate

---

## Phase 1 Verification (Dev 2 - Database)
- [x] Local SQLite database created on first launch
- [x] Tables for lesson plans, notes, bibliography work correctly
- [x] Auto-seeding hook runs on fresh database and survives delete/restart
- [x] CRUD operations verified for all entities
- [x] Unit tests pass (`flutter test test/database/database_test.dart`)
- [x] Code compiles without analyzer warnings (`flutter analyze`)

---

## Phase 1 Verification (Dev 3 - UI Shell)
- [ ] Desktop app launches with navigation layout
- [ ] Riverpod providers initialize
