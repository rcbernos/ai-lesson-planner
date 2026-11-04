---
paths:
  - "lib/services/database/**"
  - "lib/models/database/**"
  - "test/database/**"
  - "drift_schemas/**"
---

# Database rules (Drift / SQLite)

- Don't change columns of existing tables unless the card says so.
- A schema change means: bump `schemaVersion`, add an `onUpgrade` step, and add or update a migration test.
- After editing tables run `dart run build_runner build --delete-conflicting-outputs`. Never hand-edit `*.g.dart`.
- `LessonPlans.ilawContent` holds the whole plan as JSON from `LessonPlan.toJson()`. When updating a plan, keep `title`, `gradeLevel`, `subject` and `updatedAt` in step with it.
- SQLite foreign keys are off by default. Delete child rows (for example plan-note links) yourself, in the same transaction.
- Tests use an in-memory database and fictional data. First-run seeding must never duplicate rows.
- Seed data comes only from a file the human supplies. If it is missing, seed nothing.
