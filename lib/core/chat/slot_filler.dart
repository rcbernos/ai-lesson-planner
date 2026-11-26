/// Slot-filling prompt and parser for the chat assistant.
/// Processes user messages and extracts form fields using an LLM.
library;

import 'dart:convert';
import 'package:ai_lesson_planner/core/chat/chat_session.dart' as chat;
import 'package:ai_lesson_planner/core/chat/slot_schema.dart' as slot;
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage;
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';

/// Result of processing a user message for slot extraction.
class SlotFillResult {
  const SlotFillResult({
    required this.assistantResponse,
    required this.patch,
    this.validationErrors = const [],
  });

  /// The text response to show the user.
  final String assistantResponse;

  /// JSON patch of extracted fields to merge into the session.
  final Map<String, dynamic> patch;

  /// List of validation errors (empty if patch is valid).
  final List<String> validationErrors;
}

/// Builds the slot extraction prompt for the given session and user message.
/// This is a top-level function to allow testing prompt generation.
String buildSlotExtractionPrompt(chat.ChatSession session, String userMessage) {
  final buffer = StringBuffer();
  buffer.writeln(
    'You are a helpful assistant that extracts lesson plan details from teacher messages.',
  );
  buffer.writeln(
    'Extract the following fields from the user message and return as JSON.',
  );
  buffer.writeln(
    'Do NOT invent values - leave unknown fields empty or omit them.',
  );
  buffer.writeln('CURRENT PROGRESS:');
  buffer.writeln(
    '  School: ${session.header.school.isEmpty ? 'Not set' : session.header.school}',
  );
  buffer.writeln(
    '  Teacher: ${session.header.teacher.isEmpty ? 'Not set' : session.header.teacher}',
  );
  buffer.writeln(
    '  Learning Area: ${session.header.learningArea.isEmpty ? 'Not set' : session.header.learningArea}',
  );
  buffer.writeln(
    '  Date: ${session.header.date.isEmpty ? 'Not set' : session.header.date}',
  );
  buffer.writeln(
    '  Term: ${session.header.term.isEmpty ? 'Not set' : session.header.term}',
  );
  buffer.writeln('  Sessions: ${session.header.sessions}');
  buffer.writeln('  Session Minutes: ${session.header.sessionMinutes}');
  buffer.writeln(
    '  Grades: ${session.grades.isEmpty ? 'Not set' : session.grades.map((g) => g.gradeLabel).join(', ')}',
  );
  buffer.writeln('USER MESSAGE: "$userMessage"');
  buffer.writeln(
    'Return JSON: {response: "...", patch: {learningArea: "...", sessionMinutes: n, gradeLabels: [...], ...}}',
  );
  return buffer.toString();
}

/// Slot-filling processor for the chat assistant.
class SlotFiller {
  SlotFiller({
    required this.engine,
    this.temperature = 0.3,
    this.maxTokens = 512,
    int? seed,
  }) : _seed = seed,
       _isCancelled = false;

  final LlmEngine engine;
  final double temperature;
  final int maxTokens;
  final int? _seed;
  bool _isCancelled;

  /// Processes a user message and returns extracted slot fields.
  Future<SlotFillResult> processMessage(
    String userMessage,
    chat.ChatSession currentSession,
  ) async {
    _isCancelled = false;

    final prompt = buildSlotExtractionPrompt(currentSession, userMessage);
    final messages = [ChatMsg(role: 'user', content: prompt)];
    final params = GenParams(
      temperature: temperature,
      maxTokens: maxTokens,
      seed: _seed,
    );

    final buffer = StringBuffer();
    String? responseText;

    await for (final token in engine.complete(messages, params)) {
      if (_isCancelled) {
        return const SlotFillResult(
          assistantResponse: 'Generation cancelled.',
          patch: {},
        );
      }
      buffer.write(token);
      responseText = buffer.toString();
    }

    if (responseText == null) {
      return const SlotFillResult(
        assistantResponse: 'I did not understand that. Could you clarify?',
        patch: {},
      );
    }

    return _parseModelResponse(responseText);
  }

  /// Parses the model's JSON response.
  SlotFillResult _parseModelResponse(String response) {
    final json = _extractJson(response);
    if (json == null) {
      return const SlotFillResult(
        assistantResponse:
            'I need to think about that. Can you provide more details?',
        patch: {},
      );
    }

    final patch = json['patch'] as Map<String, dynamic>? ?? json;
    final responseText = json['response'] as String? ?? 'Added to your plan.';

    final validation = _validatePatch(patch);
    if (validation.isNotEmpty) {
      return SlotFillResult(
        assistantResponse: responseText,
        patch: patch,
        validationErrors: validation,
      );
    }

    return SlotFillResult(assistantResponse: responseText, patch: patch);
  }

  /// Extracts JSON from model response text.
  Map<String, dynamic>? _extractJson(String text) {
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

  /// Validates the JSON patch.
  List<String> _validatePatch(Map<String, dynamic> patch) {
    final errors = <String>[];

    // Validate grade labels - check both 'grades' and 'gradeLabels' keys
    final gradesList =
        patch['grades'] as List<dynamic>? ??
        patch['gradeLabels'] as List<dynamic>?;
    if (gradesList != null) {
      final labels = <String>[];
      for (final g in gradesList) {
        final label = g is Map<String, dynamic>
            ? g['gradeLabel'] as String?
            : (g is String ? g : null);
        if (label != null) {
          labels.add(label);
        }
      }
      if (labels.length < 2 || labels.length > 6) {
        errors.add('Please specify 2 to 6 grades (found ${labels.length}).');
      } else {
        for (final label in labels) {
          if (!slot.SlotSchema.isValidGradeLabel(label)) {
            errors.add('Invalid grade: $label. Use format "Grade 3".');
          }
        }
      }
    }

    // Validate learning area
    final learningArea = patch['learningArea'] as String?;
    if (learningArea != null && learningArea.isEmpty) {
      errors.add('Learning area cannot be empty.');
    }

    // Validate session minutes
    final sessionMinutes = patch['sessionMinutes'] as int?;
    if (sessionMinutes != null &&
        !slot.SlotSchema.isValidSessionMinutes(sessionMinutes)) {
      errors.add('Session length must be 60, 90, or 120 minutes.');
    }

    return errors;
  }

  /// Cancels any ongoing generation.
  Future<void> cancel() async {
    _isCancelled = true;
    await engine.cancel();
  }

  /// Unloads the model and frees memory.
  Future<void> dispose() async {
    await engine.unload();
  }
}

/// Creates a generation request from a chat session after slot filling.
chat.ChatSession applyPatchToSession(
  chat.ChatSession session,
  Map<String, dynamic> patch,
) {
  chat.ChatSession updated = session;

  // Apply header patches
  if (patch['school'] is String && (patch['school'] as String).isNotEmpty) {
    updated = updated.copyWith(
      header: session.header.copyWith(school: patch['school'] as String),
    );
  }
  if (patch['teacher'] is String && (patch['teacher'] as String).isNotEmpty) {
    updated = updated.copyWith(
      header: updated.header.copyWith(teacher: patch['teacher'] as String),
    );
  }
  if (patch['learningArea'] is String &&
      (patch['learningArea'] as String).isNotEmpty) {
    updated = updated.copyWith(
      header: updated.header.copyWith(
        learningArea: patch['learningArea'] as String,
      ),
    );
  }
  if (patch['date'] is String && (patch['date'] as String).isNotEmpty) {
    updated = updated.copyWith(
      header: updated.header.copyWith(date: patch['date'] as String),
    );
  }
  if (patch['term'] is String && (patch['term'] as String).isNotEmpty) {
    updated = updated.copyWith(
      header: updated.header.copyWith(term: patch['term'] as String),
    );
  }
  if (patch['sessionMinutes'] is int) {
    updated = updated.copyWith(
      header: updated.header.copyWith(
        sessionMinutes: patch['sessionMinutes'] as int,
      ),
    );
  }
  if (patch['outputLanguage'] is String) {
    final lang = (patch['outputLanguage'] as String).toLowerCase();
    final outputLang = lang == 'english' || lang == 'en'
        ? OutputLanguage.english
        : OutputLanguage.filipino;
    updated = updated.copyWith(outputLanguage: outputLang);
  }
  if (patch['sharedSubTheme'] is String &&
      (patch['sharedSubTheme'] as String).isNotEmpty) {
    updated = updated.copyWith(
      sharedSubTheme: patch['sharedSubTheme'] as String,
    );
  }

  // Apply grades patch
  if (patch['gradeLabels'] is List) {
    final labels = (patch['gradeLabels'] as List).whereType<String>().toList();
    final grades = <GradeInput>[];
    for (final label in labels) {
      grades.add(
        GradeInput(
          gradeLabel: label,
          male: 0,
          female: 0,
          subTheme: '',
          competency: '',
        ),
      );
    }
    updated = updated.copyWith(grades: grades);
  }

  return updated;
}

/// Returns the next missing field that needs to be filled.
String getNextMissingField(chat.ChatSession session) {
  if (session.header.school.isEmpty) return 'school';
  if (session.header.teacher.isEmpty) return 'teacher';
  if (session.header.learningArea.isEmpty) return 'learningArea';
  if (session.header.date.isEmpty) return 'date';
  if (session.header.term.isEmpty) return 'term';
  if (session.sharedSubTheme.isEmpty) return 'sharedSubTheme';
  if (session.grades.isEmpty) return 'grades';
  for (final g in session.grades) {
    if (g.gradeLabel.isEmpty) return 'gradeLabel';
    if (g.subTheme.isEmpty) return 'subTheme for ${g.gradeLabel}';
    if (g.competency.isEmpty) return 'competency for ${g.gradeLabel}';
  }
  return 'all filled';
}
