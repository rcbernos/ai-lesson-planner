/// Section runners for prompt building and JSON extraction.
library;

import 'dart:convert';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';

/// Builds the shared system block for all prompts.
String buildSystemBlock({
  required OutputLanguage language,
  required List<String> gradeLabels,
  required String multigradeModel,
}) {
  final labels = gradeLabels.join(', ');
  final lang = language == OutputLanguage.filipino ? 'Filipino' : 'English';
  return 'You write content for a DepEd ILAW Daily Lesson Plan. Output ONLY valid JSON matching the schema. Write in '
        '$lang. Never invent competency codes, standards, learner names, or URLs. Use the grade labels: $labels. '
        'Model: $multigradeModel';
}

/// Builds the Intentions section prompt.
String buildIntentionsPrompt(GenerationRequest request) {
  final labels = request.grades.map((g) => g.gradeLabel).toList();
  final block = buildSystemBlock(
    language: request.language,
    gradeLabels: labels,
    multigradeModel: request.header.multigradeModel,
  );
  return '$block\n'
      'Generate Intentions:\n'
      '- sharedSubTheme: one phrase\n'
      '- grades: subTheme, objectives (1-2 each), bothGradesObjective\n'
      '- Grounded: copy standards from curriculum input.\n'
      'Return JSON: {"sharedSubTheme": "...", "grades": [{"gradeLabel": "...", "subTheme": "...", "objectives": [...]}], "bothGradesObjective": "..."}';
}

/// Builds Learning Experience Step A prompt (learner context).
String buildLearnerContextPrompt(GenerationRequest request) {
  final labels = request.grades.map((g) => g.gradeLabel).toList();
  final block = buildSystemBlock(
    language: request.language,
    gradeLabels: labels,
    multigradeModel: request.header.multigradeModel,
  );
  return '$block\n'
      'Generate learnerContext: 1-2 paragraphs about learners in ${labels.join(', ')}. '
      'Return JSON: {"learnerContext": "text"}';
}

/// Builds Learning Experience Step B prompt (materials).
String buildMaterialsPrompt(GenerationRequest request) {
  final labels = request.grades.map((g) => g.gradeLabel).toList();
  final block = buildSystemBlock(
    language: request.language,
    gradeLabels: labels,
    multigradeModel: request.header.multigradeModel,
  );
  return '$block\n'
      'Generate materials: items 3-6 classroom low-resource items, references 2-4 DepEd sources. '
      'Return JSON: {"materials": {"items": [...], "references": [...]}}';
}

/// Builds Learning Experience Step C prompt (flow table).
String buildFlowPrompt(GenerationRequest request) {
  final labels = request.grades.map((g) => g.gradeLabel).toList();
  final minutes = request.header.sessionMinutes;
  final block = buildSystemBlock(
    language: request.language,
    gradeLabels: labels,
    multigradeModel: request.header.multigradeModel,
  );
  return '$block\n'
      'Generate flow: $minutes minutes total, 5-7 rows. '
      'First=Whole-Class Motivation, Last=Whole-Class Wrap-Up. '
      'Return JSON: {"flow": [{"minutes": n, "stage": "...", "wholeClass": true/false, '
      '"wholeClassActivity": "...", "activityByGrade": {...}}]}';
}

/// Builds a retry prompt with validation issues.
String buildRetryPrompt(List<String> issues, String basePrompt) {
  final issuesText = issues.map((i) => '- $i').join('\n');
  return '$basePrompt\n'
      'VALIDATION ERRORS to fix:\n'
      '$issuesText\n'
      'Fix only these issues.';
}

/// Extracts JSON from text, handling malformed output.
Map<String, dynamic>? extractJson(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end == -1 || start > end) return null;

  final jsonStr = text.substring(start, end + 1);
  try {
    final parsed = json.decode(jsonStr);
    if (parsed is Map<String, dynamic>) return parsed;
  } catch (_) {}
  return null;
}