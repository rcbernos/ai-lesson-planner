---
paths:
  - "lib/core/**"
  - "test/fixtures/**"
---

# Models, validation and generation rules

- Plan models are plain Dart with hand-written `toJson` and `fromJson`. No code generation.
- `fromJson` must accept older saves: missing optional fields get defaults. Bump `LessonPlan.currentSchemaVersion` when the JSON shape changes.
- Models, validation and the generator interface have no `package:flutter` imports.
- Grounded fields (header data, standards, competencies, sub-theme, learner counts) come from the teacher. Generation and regeneration never overwrite them.
- Never invent competency codes, URLs or citations, not even in mock output.
- Validator issues have a stable `code` and a plain-English `message` that could be pasted into a retry prompt.
- Flow stage minutes must add up to `sessionMinutes`.
