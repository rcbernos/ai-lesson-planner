# ILAW Multigrade DLP: AI Scaffolding Template

Derived from four reference DLPs (Kasilayan Elementary School: Makabansa/AP G3-4, Filipino G3-4, GMRC G5-6, Reading & Literacy G1-2).

Three consumers use this file:

1. **LLM prompts** (sections 4 and 5): what the model must produce, one section at a time.
2. **Validators** (section 6): hard and soft checks on the generated JSON.
3. **Renderers** (section 7): Flutter plan view and DOCX export, so both draw the same document.

Conventions:

- The LLM outputs **JSON only**. The app draws the layout.
- Field names follow the current Dart view code (`header.school`, `flow[].activityByGrade`, and so on). Fields marked **NEW** are in the references but not used anywhere in the view code. Check them against `lesson_plan.dart`.
- Section generation order: `intentions` -> `learningExperience` -> `assessment` -> `waysForward`. Pass earlier sections to later prompts as context.

---

## 1. Document anatomy (top to bottom)

| # | Block | Layout | Filled by |
|---|-------|--------|-----------|
| 0 | Title: `DAILY LESSON PLAN FOR GRADE {gradeLevels}` | centered, bold, roman numerals | app (from `header.gradeLevels`) |
| 1 | Header table | 4 columns (label, value, label, value), 5 rows; last row "Multigrade Model" spans the value across 3 columns | teacher input |
| 2 | Banner `I  INTENTIONS` | full-width filled bar | app |
| 2a | Shared Sub-theme | bold; one line per grade tagged `(Grade N)`, or a single line | AI |
| 2b | Standards table | blank corner, then one column per grade. Rows: Content Standard, Performance Standard | curriculum source (copy, don't invent) |
| 2c | Learning Competencies and Codes | bullets, each tagged `[Grade N]` | curriculum source |
| 2d | Learning Objectives | bullets tagged `[Grade N]`, then one tagged `[Both Grades]` | AI |
| 3 | Banner `L  LEARNING EXPERIENCE` | full-width filled bar | app |
| 3a | Learner Context | 1-2 short paragraphs | AI |
| 3b | Instructional Materials and Resources | two lists: Materials (Mga Kagamitan), References (Mga Sanggunian) | AI, constrained |
| 3c | Flow of the Lesson | table: Time, Stage, one column per grade. Whole-class rows merge the grade cells | AI |
| 4 | Banner `A  ASSESSMENT` + table | blank corner, grade columns. Rows: Formative, Exit Task, Success Criteria | AI |
| 5 | Banner `W  WAYS FORWARD` | full-width filled bar | app |
| 5a | Reflection Questions | bullets: either general, or tagged per grade | AI |
| 5b | Remediation and Enrichment | blank corner, grade columns. Rows: Remediation, Enrichment | AI |
| 5c | Notes for Next Session / Whole-School Follow-Up | one paragraph (G1-2 doc titles it just "Notes for Next Session") | AI |
| 6 | Signatures | two blocks side by side: `Prepared by:` / `Checked by:`, NAME IN CAPS, role beneath ("Classroom Adviser", "School Head") | teacher / school profile |

Key shape fact: **all three body tables (standards, assessment, remediation/enrichment) put grades in COLUMNS and the criteria in ROWS**, the same orientation as the flow table. Never transpose.

---

## 2. JSON skeleton

Comments are documentation only. Real output is plain JSON.

```jsonc
{
  "language": "fil",                       // NEW: "fil" | "en" | "mixed"; drives labels and generated text
  "header": {
    "school": "Kasilayan Elementary School",
    "teacher": "…",
    "learningArea": "Makabansa / Araling Panlipunan",
    "date": "August 24, 2026",
    "term": "Term 1",
    "sessions": 1,
    "sessionMinutes": 45,
    "multigradeModel": "Same Theme, Different Task (STDT) with a Grade 4 peer leader supporting Grade 3",
    "gradeLevels": "III & IV",             // NEW: roman numerals, used in title and header
    "learnerCounts": [                     // NEW
      { "gradeLabel": "Grade 3", "total": 6, "male": 3, "female": 3 },
      { "gradeLabel": "Grade 4", "total": 1, "male": 1, "female": 0 }
    ]
  },

  "sharedSubTheme": "…",                   // umbrella line, or the only line if grades share one
  "grades": [                              // all references: exactly 2 grades; app code supports N
    {
      "gradeLabel": "Grade 3",             // exact string reused as key everywhere below
      "subTheme": "…",                     // NEW: optional per-grade line
      "contentStandard": "…",
      "performanceStandard": "…",
      "competencies": ["…"],
      "objectives": ["…"]
    },
    { "gradeLabel": "Grade 4", "subTheme": "…", "contentStandard": "…", "performanceStandard": "…", "competencies": ["…"], "objectives": ["…"] }
  ],
  "bothGradesObjective": "…",

  "learnerContext": "…",
  "materials": {                           // NEW
    "items": ["…"],                        // Mga Kagamitan / Materials
    "references": ["…"]                    // Mga Sanggunian / References
  },

  "flow": [
    {
      "minutes": 5,
      "stage": "Whole-Class Motivation",
      "wholeClass": true,                  // true => one merged cell, text in wholeClassActivity
      "wholeClassActivity": "…",
      "activityByGrade": {}
    },
    {
      "minutes": 10,
      "stage": "Direct Teaching",
      "wholeClass": false,                 // false => one text per grade, keyed by gradeLabel
      "wholeClassActivity": "",
      "activityByGrade": { "Grade 3": "…", "Grade 4": "…" }
    }
  ],

  "assessments": [
    { "gradeLabel": "Grade 3", "formative": "…", "exitTask": "…", "successCriteria": "…" },
    { "gradeLabel": "Grade 4", "formative": "…", "exitTask": "…", "successCriteria": "…" }
  ],
  "waysForward": [
    { "gradeLabel": "Grade 3", "remediation": "…", "enrichment": "…" },
    { "gradeLabel": "Grade 4", "remediation": "…", "enrichment": "…" }
  ],
  "reflectionQuestions": [
    { "gradeLabel": null, "text": "…" },               // null => general bullet
    { "gradeLabel": "Grade 3", "text": "…" }            // per-grade bullet
  ],
  "notesNextSession": "…",

  "preparedBy": "JOCELYN E. MALLORCA",
  "preparedByRole": "Classroom Adviser",   // NEW
  "checkedBy": "DEXTER T. ORLANDEZ",
  "checkedByRole": "School Head",          // NEW
  "aiUseDeclaration": "…"                  // not in any reference; keep only if your policy requires it
}
```

Derived display strings (the renderer builds these, the AI never writes them):

| Display | Rule |
|---------|------|
| Time / Sessions | `"{sessions} session(s), {sessionMinutes} minutes"` -> `1 session, 45 minutes` |
| No. of Learners | `"Gr.3: 6  │  Gr.4: 1 (M-3, F-3) (M-1, F-0)"`: totals joined by `"  │  "`, then one `(M-x, F-y)` per grade, in grade order |
| Flow time cell | `"{minutes} min"` |
| Banner text | `"I  INTENTIONS"` (letter, two spaces, uppercase) |

---

## 3. Who fills what (anti-hallucination map)

| Field group | Source | Rule for the AI |
|-------------|--------|-----------------|
| `header.*`, `learnerCounts`, `preparedBy`, `checkedBy` and roles | teacher / school profile | Never generated. If missing, leave empty. |
| `contentStandard`, `performanceStandard`, `competencies` | official curriculum text supplied by the app or teacher | Copy verbatim from the supplied excerpt. If not supplied, return `""` or `[]`. Never write a competency code unless it is in the input (none of the four references contain codes). |
| `sharedSubTheme`, `subTheme`, `objectives`, `bothGradesObjective` | AI | Must stay inside the supplied topic and competencies. |
| `learnerContext`, `materials`, `flow`, `assessments`, `waysForward`, `reflectionQuestions`, `notesNextSession` | AI | Constrained by sections 4 to 6. |

---

## 4. Authoring rules per field

Lengths are approximate, observed across the four references.

| Field | Shape | Rules |
|-------|-------|-------|
| `sharedSubTheme` / `subTheme` | one short phrase per grade | Names the topic of that grade's lesson. Two grades may have different topics under one theme. |
| `objectives` | 1-2 sentences per grade, plus 1 `bothGradesObjective` | Start with a measurable learner verb in the output language. The both-grades objective ties the two grade topics to one shared outcome. |
| `learnerContext` | 1-2 short paragraphs | Who the learners are and which familiar local examples the teacher will use. No statistics. |
| `materials.items` | 3-6 items | Only low-resource items: printed pictures, activity sheets, board and chalk/pentel pen. No projector, internet or tablets unless the teacher listed them. |
| `materials.references` | 2-4 items | Generic DepEd sources (Curriculum Guide, Learner's Materials, Teacher's Guide) plus teacher-prepared texts. Never invent titles, authors or URLs. |
| `flow[].stage` | from the stage vocabulary below | Free text allowed, but prefer the vocabulary. |
| `flow[].activityByGrade[g]` | 1-3 sentences, about 15-50 words | One concrete teacher or learner action. Include a short example in quotes when it helps. Must be doable with the listed materials. |
| `assessments[].formative` | 1 sentence | Observation of participation, or a short "Panuto/Directions" task. |
| `assessments[].exitTask` | 1 sentence | One thing the learner says, writes or marks. Must match that grade's Application stage. |
| `assessments[].successCriteria` | 1 sentence | Starts with a learner-performance verb (Nakapagbibigay..., Identify...). Measurable. Maps to that grade's objective. |
| `reflectionQuestions` | 1-3 items | Either general (`gradeLabel: null`, often teacher-facing: "How many learners met the objectives?") or one per grade (learner-facing). Don't mix the two styles in one plan. |
| `waysForward[].remediation` | 1-2 sentences | Re-teach with teacher help, pictures or a peer tutor. Same topic, lower demand. |
| `waysForward[].enrichment` | 1-2 sentences | Extension task on the same topic: a list of two or five, a bookmark, a checklist. |
| `notesNextSession` | 1-2 sentences | Home task or continuation. No new content. |

### Flow of the Lesson rules

- **Total time:** the sum of `flow[].minutes` must equal `header.sessionMinutes`. This holds in all four references (45, 90, 45, 50).
- **Size:** 5-7 rows in total.
- **First and last rows are whole-class** (`Whole-Class Motivation`, `Whole-Class Wrap-Up`). This holds in 4 of 4 references. They render as one merged cell across the grade columns.
- **Stage vocabulary** (observed): `Whole-Class Motivation`, `Direct Teaching`, `Direct Teaching (switch)`, `Guided Practice`, `Cross-Grade Collaboration`, `Buddy Reading`, `Application`, `Generalization`, `Whole-Class Wrap-Up`.
- **STDT switch pattern:** this is how one teacher handles two grades. In `Direct Teaching`, Grade A gets teacher-led instruction while Grade B does an independent task. In `Direct Teaching (switch)`, the roles swap. Use the verbs `Guro: ...` (teacher-led) and `Malayang Gawain: ...` (independent) in Filipino, or "Teacher-Led" / "Independent Task" in English. A plan may skip the switch and use `Guided Practice` instead (Makabansa reference).
- **Cross-Grade Collaboration / Buddy Reading:** a peer-support row where the older grade helps the younger. The two cells may carry the same text (Filipino reference) or role-specific text (GMRC reference). The model must say which grade supports which.
- **Application row:** one product per grade that the exit task can reuse.
- **Optional whole-class prefix:** whole-class cells may start with `Magkasamang Gawain:` (Filipino) or `Both grades:` (English).

### Labels by output language

Section banners and the assessment/ways-forward row labels stay in English in all four references. Only the standards labels follow the plan language:

| Key | `en` | `fil` |
|-----|------|-------|
| Content standard | Content Standard | Pamantayang Pangnilalaman |
| Performance standard | Performance Standard | Pamantayan sa Pagganap |

---

## 5. Per-section prompt scaffolds

Replace `{{placeholders}}` with app data. Keep the system block identical across calls.

### 5.0 Shared system block

```text
You write content for a DepEd ILAW Daily Lesson Plan for a small multigrade classroom
(one teacher, {{gradeLabels}} together, model: {{multigradeModel}}).

Output ONLY valid JSON that matches the schema in the task. No prose, no markdown fences.
Write in {{language}}.

Hard rules:
- Use only the inputs provided. Do not invent curriculum standards, competency codes,
  learner counts, names, book titles or URLs. If an input is missing, return "" or [].
- Use the exact gradeLabel strings given: {{gradeLabelsJson}}.
- Activities must be doable by one teacher with a board, chalk or pentel pen,
  printed pictures and activity sheets, unless the materials list says otherwise.
- Each grade's text must fit that grade's reading and writing level.
- Keep every cell short: 1-3 sentences.
```

### 5.1 Intentions

```text
INPUT
  gradeLabels: {{gradeLabels}}
  topicPerGrade: {{topicPerGrade}}
  curriculumExcerptPerGrade: {{curriculumExcerptPerGrade}}   // standards + competencies, official text

TASK
  Return { "sharedSubTheme": string,
           "grades": [ { "gradeLabel", "subTheme", "contentStandard", "performanceStandard",
                         "competencies": [string], "objectives": [string] } ],
           "bothGradesObjective": string }

RULES
  - contentStandard, performanceStandard and competencies: copy verbatim from curriculumExcerptPerGrade.
    If not present, return "" / [].
  - objectives: 1-2 per grade, each starting with a measurable learner verb.
  - bothGradesObjective: one sentence that ties both grade topics to a single shared outcome.
  - subTheme: one short phrase per grade.
```

### 5.2 Learning Experience

Call this as three steps (context, materials, flow) so each can be regenerated alone.

```text
INPUT   intentions: {{intentionsJson}}   sessionMinutes: {{sessionMinutes}}   materialsAvailable: {{materialsAvailable}}

STEP A  Return { "learnerContext": string }               // 1-2 short paragraphs
STEP B  Return { "materials": { "items": [string], "references": [string] } }
STEP C  Return { "flow": [ { "minutes": int, "stage": string, "wholeClass": bool,
                             "wholeClassActivity": string, "activityByGrade": { "<gradeLabel>": string } } ] }

FLOW RULES
  - 5-7 rows. Sum of minutes == {{sessionMinutes}}.
  - First row = "Whole-Class Motivation" (wholeClass true). Last row = "Whole-Class Wrap-Up" (wholeClass true).
  - Middle rows use: Direct Teaching, Direct Teaching (switch), Guided Practice,
    Cross-Grade Collaboration or Buddy Reading, Application, Generalization.
  - STDT: when one grade is teacher-led, the other has an independent task.
    In "(switch)" the roles swap.
  - Whole-class rows: fill wholeClassActivity, leave activityByGrade {}.
    Other rows: one non-empty entry per grade label, wholeClassActivity "".
  - Each grade has an Application row that produces something the exit task can reuse.
  - Use only materials from the list.
```

### 5.3 Assessment

```text
INPUT   intentions: {{intentionsJson}}   flow: {{flowJson}}

TASK    Return { "assessments": [ { "gradeLabel", "formative", "exitTask", "successCriteria" } ] }
        One entry per grade, same order as gradeLabels.

RULES
  - exitTask for each grade must be the same kind of task as that grade's Application row.
  - successCriteria for each grade maps to that grade's objective and is measurable.
  - formative is observation of participation, or a short directions-based task.
```

### 5.4 Ways Forward

```text
INPUT   intentions: {{intentionsJson}}   flow: {{flowJson}}   assessments: {{assessmentsJson}}

TASK    Return { "reflectionQuestions": [ { "gradeLabel": string|null, "text": string } ],
                 "waysForward": [ { "gradeLabel", "remediation", "enrichment" } ],
                 "notesNextSession": string }

RULES
  - reflectionQuestions: 1-3 items, EITHER all general (gradeLabel null) OR one per grade.
  - remediation: same topic, with teacher help, pictures or a peer tutor.
  - enrichment: an extension on the same topic that needs no new materials.
  - notesNextSession: a home task or continuation only; do not introduce new content.
```

### 5.5 Single-grade regeneration

```text
Regenerate ONLY the {{section}} content for {{gradeLabel}}.
Keep the other grades' text unchanged and consistent with it.
Return the same JSON shape as the full section, with the other grades' entries copied back verbatim.
```

---

## 6. Validation rules

Severity names match the existing `IssueSeverity.error` / `IssueSeverity.warning`.

| ID | Severity | Rule |
|----|----------|------|
| V1 | error | Every `gradeLabel` in `assessments`, `waysForward` and `flow[].activityByGrade` keys matches `grades[].gradeLabel` exactly (same strings, same order). |
| V2 | error | Sum of `flow[].minutes` equals `header.sessionMinutes`. |
| V3 | error | `flow.first.wholeClass` and `flow.last.wholeClass` are both true. |
| V4 | error | Whole-class row: `wholeClassActivity` non-empty and `activityByGrade` empty. Other row: every grade key present and non-empty. |
| V5 | error | `assessments` and `waysForward` each have exactly one entry per grade. |
| V6 | error | Every `assessments` and `waysForward` cell is non-empty. |
| V7 | error | Each grade has at least 1 objective. |
| V8 | warning | Each grade has at least 1 competency, and non-empty content and performance standards (these come from the curriculum source and may be legitimately absent). |
| V9 | warning | Flow has 5-7 rows. |
| V10 | warning | No placeholder text (`TBD`, `...`, `{{`, `lorem`). |
| V11 | warning | Output language matches `language` (English words inside Filipino text are fine; other-language words such as Cebuano are flagged). |
| V12 | warning | Materials mentioned in flow activities appear in `materials.items`. |
| V13 | warning | `reflectionQuestions` are all general or all per-grade. |

---

## 7. Renderer parity spec (Flutter view and DOCX export)

| Item | Reference value |
|------|-----------------|
| Page | A4 (11906 x 16838 twips). Margins 720 twips (0.5") in 3 of 4 references. The G1-2 doc is an outlier (left 1418, bottom 284). |
| Body text | 11 pt (sz 22), banners and title 12 pt (sz 24) |
| Font | Inconsistent across references (Times New Roman, Century Gothic, Bookman Old Style). Pick one default and make it configurable. |
| Header table | label cells: fill `1F3864`, white bold text. Value cells: plain. |
| Banner `I  INTENTIONS` | fill `1F3864`, white bold, full width |
| Banner `L  LEARNING EXPERIENCE` | fill `2E6B2E`, white bold, full width (singular "EXPERIENCE") |
| Banner `A  ASSESSMENT` | fill `8C5A1E`, white bold, full width |
| Banner `W  WAYS FORWARD` | fill `7A2048`, white bold, full width |
| Table corner / Time / Stage headers | fill `444444`, white text |
| Grade column header, 1st grade | fill `8C5A1E`, white bold, text `GRADE 3` |
| Grade column header, 2nd grade | fill `2E6B2E`, white bold. A third colour is not defined in any reference. |
| Row-label cells (standards, assessment, ways forward, flow stage names) | fill `1F3864`, white text |
| Flow table | columns: Time (narrow), Stage (narrow), then equal-width grade columns. Whole-class rows span all grade columns. |
| Learner-count and time formats | see the "Derived display strings" table in section 2 |
| Signature block | two blocks side by side; name in caps; role in smaller text beneath |

---

## 8. Caveats about the reference documents

Use them for **structure**, not as text examples:

- **Filipino G3-4:** the Learning Objectives contain Cebuano words ("aron", "ug"). Don't use it as a few-shot example.
- **"Grade 12 Reading and Literacy" file:** the file name says Grade 12 but the content is **Grades I & II**. It has typos and mixed English/Filipino inside single cells, its "Learner Context" reads like a materials list, and it uses the heading "Learner materials." instead of "Instructional Materials and Resources".
- **Makabansa G3-4:** the Wrap-Up cell has a duplicated "Tanong: Itanong:".
- **All four:** no competency codes, despite the heading "Learning Competencies and Codes".
- **Standards language:** two documents show standards in English inside a Filipino-subject plan, so the standards language follows the curriculum source, not `language`.
- **Few-shot advice:** write one cleaned example per language by hand (see section 9) and use that.

---

## 9. Abridged worked example (Makabansa G3-4, Aug 24, 2026)

Strings are shortened with "…". Structure is real.

```json
{
  "language": "fil",
  "header": {
    "school": "Kasilayan Elementary School",
    "teacher": "Jocelyn E. Mallorca",
    "learningArea": "Makabansa / Araling Panlipunan",
    "date": "August 24, 2026",
    "term": "Term 1",
    "sessions": 1,
    "sessionMinutes": 45,
    "multigradeModel": "Same Theme, Different Task (STDT) with a Grade 4 peer leader supporting Grade 3",
    "gradeLevels": "III & IV",
    "learnerCounts": [
      { "gradeLabel": "Grade 3", "total": 6, "male": 3, "female": 3 },
      { "gradeLabel": "Grade 4", "total": 1, "male": 1, "female": 0 }
    ]
  },
  "sharedSubTheme": "Pangangalaga sa komunidad at likas na yaman",
  "grades": [
    {
      "gradeLabel": "Grade 3",
      "subTheme": "Pagpapahalaga sa Pagbabagong Naganap at Nagaganap sa Kinabibilangang Komunidad",
      "contentStandard": "Nauunawaan ang kasaysayan ng kinabibilangang pook …",
      "performanceStandard": "Nakagagawa ng likhang-sining na nagpapakita ng kasaysayan …",
      "competencies": ["Napahahalagahan ang kasaysayan at pagbabagong nagaganap sa kinabibilangang komunidad."],
      "objectives": ["Makapagbibigay ng mga paraan upang mapanatili ang kapayapaan, kalinisan, at kaunlaran …"]
    },
    {
      "gradeLabel": "Grade 4",
      "subTheme": "Mga pinagkukunang-yaman ng bansa (likas na yamang enerhiya)",
      "contentStandard": "Naipamamalas ang pag-unawa sa pagkakakilanlan ng bansa …",
      "performanceStandard": "Nakabubuo ng gawaing nagsusulong sa pangangalaga sa heograpiya …",
      "competencies": ["Natatalakay ang mga hamon at pagtugon sa mga gawaing pangkabuhayan ng bansa."],
      "objectives": ["Matutukoy ang mga pinagkukunang yaman mula sa kagubatan at enerhiya …"]
    }
  ],
  "bothGradesObjective": "Makapagpapakita ng pagpapahalaga sa pangangalaga at wastong paggamit ng mga yaman ng komunidad …",
  "learnerContext": "Ang mga mag-aaral sa Grades 3 at 4 ay may mga karanasan sa kanilang sariling komunidad …",
  "materials": {
    "items": ["Mga larawan ng pagbabago sa komunidad", "Mga larawan ng kagubatan, tubig, kuryente", "Pisara at chalk"],
    "references": ["DepEd Curriculum Guide", "Learner's Materials", "Teacher's Guide"]
  },
  "flow": [
    { "minutes": 5,  "stage": "Whole-Class Motivation", "wholeClass": true,
      "wholeClassActivity": "Magkasamang gawain: Magbanggit ang guro ng mga nakikita sa komunidad …", "activityByGrade": {} },
    { "minutes": 10, "stage": "Direct Teaching", "wholeClass": false, "wholeClassActivity": "",
      "activityByGrade": { "Grade 3": "Ipaliwanag: \"Nagbabago ang komunidad …\"", "Grade 4": "Ipaliwanag: \"Ang kagubatan at enerhiya ay mga pinagkukunang-yaman …\"" } },
    { "minutes": 10, "stage": "Guided Practice", "wholeClass": false, "wholeClassActivity": "",
      "activityByGrade": { "Grade 3": "Magbanggit ng 3 gawain. Sasagot ang Grade 3 ng Mabuti o Hindi Mabuti.", "Grade 4": "Magbanggit ng 3 gawain. Sasagot ang Grade 4 ng Wasto o Hindi Wasto." } },
    { "minutes": 15, "stage": "Application", "wholeClass": false, "wholeClassActivity": "",
      "activityByGrade": { "Grade 3": "Magbigay ng isang paraan upang mapanatili ang kalinisan, kapayapaan, o kaunlaran …", "Grade 4": "Magbigay ng isang paraan upang magamit o mapangalagaan ang kagubatan o enerhiya." } },
    { "minutes": 5,  "stage": "Whole-Class Wrap-Up", "wholeClass": true,
      "wholeClassActivity": "Magkasamang gawain: Itanong: \"Ano ang isang paraan na maaari nating gawin …?\"", "activityByGrade": {} }
  ],
  "assessments": [
    { "gradeLabel": "Grade 3", "formative": "Obserbahan ang pakikilahok …", "exitTask": "Magbigay ng isang paraan upang mapanatili ang kalinisan …", "successCriteria": "Nakapagbibigay ng isang wastong paraan …" },
    { "gradeLabel": "Grade 4", "formative": "Obserbahan ang pakikilahok …", "exitTask": "Magbigay ng isang paraan upang magamit nang wasto …", "successCriteria": "Nakapagbibigay ng isang wastong paraan …" }
  ],
  "waysForward": [
    { "gradeLabel": "Grade 3", "remediation": "Muling magbanggit ang guro ng mga halimbawa …", "enrichment": "Magbigay ng dalawang paraan …" },
    { "gradeLabel": "Grade 4", "remediation": "Muling magbanggit ang guro ng mga halimbawa ng paggamit ng likas na yaman …", "enrichment": "Magbigay ng dalawang paraan upang magamit nang wasto …" }
  ],
  "reflectionQuestions": [
    { "gradeLabel": null, "text": "Ano ang isang pagbabago sa ating komunidad na nais nating mapanatili? Bakit?" },
    { "gradeLabel": null, "text": "Paano natin mapangangalagaan ang mga likas na yaman at enerhiya sa ating komunidad?" }
  ],
  "notesNextSession": "Magbigay ng isang simpleng gawain sa bahay …",
  "preparedBy": "JOCELYN E. MALLORCA",
  "preparedByRole": "Classroom Adviser",
  "checkedBy": "DEXTER T. ORLANDEZ",
  "checkedByRole": "School Head"
}
```

Validation of this example: V2 passes (5+10+10+15+5 = 45), V3 passes, V1/V4/V5 pass.