# Evaluation Results T5.9

**Date:** 2026-11-26
**Engine:** FakeEngine (testing mode)
**Seed:** 42

## Summary
- Total requests: 3
- Passed: 0
- Failed: 3

## Results Table

| ID | Name | Status | Errors | Error Codes |
|----|------|--------|--------|-------------|
| req-1 | 2 grades Filipino 60min | FAIL | 1 | EXCEPTION: EngineException: No token sequence found for key: system:You write content for a DepEd ILAW Daily Lesson Plan. Output ONLY valid JSON matching the schema. Write in Filipino. Never invent competency codes, standards, learner names, or URLs. Use the grade labels: Grade 3, Grade 4. Model: Gemma-SEA-LION-v4-4B-VL
Generate flow: 60 minutes total, 5-7 rows. First=Whole-Class Motivation, Last=Whole-Class Wrap-Up. Return JSON: {"flow": [{"minutes": n, "stage": "...", "wholeClass": true/false, "wholeClassActivity": "...", "activityByGrade": {...}}]}
VALIDATION ERRORS to fix:
- The lesson flow adds up to 61 minutes but the session is 60 minutes.
Fix only these issues.; |
| req-2 | 2 grades English 60min | FAIL | 1 | EXCEPTION: EngineException: No token sequence found for key: system:You write content for a DepEd ILAW Daily Lesson Plan. Output ONLY valid JSON matching the schema. Write in English. Never invent competency codes, standards, learner names, or URLs. Use the grade labels: Grade 3, Grade 4. Model: Gemma-SEA-LION-v4-4B-VL
Generate flow: 60 minutes total, 5-7 rows. First=Whole-Class Motivation, Last=Whole-Class Wrap-Up. Return JSON: {"flow": [{"minutes": n, "stage": "...", "wholeClass": true/false, "wholeClassActivity": "...", "activityByGrade": {...}}]}
VALIDATION ERRORS to fix:
- The lesson flow adds up to 61 minutes but the session is 60 minutes.
Fix only these issues.; |
| req-3 | 4 grades Filipino 90min | FAIL | 1 | EXCEPTION: EngineException: No token sequence found for key: system:You write content for a DepEd ILAW Daily Lesson Plan. Output ONLY valid JSON matching the schema. Write in Filipino. Never invent competency codes, standards, learner names, or URLs. Use the grade labels: Grade 1, Grade 2, Grade 3, Grade 4. Model: Gemma-SEA-LION-v4-4B-VL
Generate Intentions:
- sharedSubTheme: one phrase
- grades: subTheme, objectives (1-2 each), bothGradesObjective
- Grounded: copy standards from curriculum input.
Return JSON: {"sharedSubTheme": "...", "grades": [{"gradeLabel": "...", "subTheme": "...", "objectives": [...]}], "bothGradesObjective": "..."}
VALIDATION ERRORS to fix:
- Grade Grade 3 has no objectives defined.
- Grade Grade 4 has no objectives defined.
Fix only these issues.; |
