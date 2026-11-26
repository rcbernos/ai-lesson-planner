/// Chat session model for the guided slot-filling assistant.
library;

import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage, GenerationRequest;
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' show PlanHeader;

// Note: The name 'ChatSession' conflicts with Drift's generated ChatSession data class.
// We use this alias to avoid the conflict when importing app_database.dart.
// The Drift class is accessed via 'AppDatabase' methods that return 'ChatSession' (data class).
// This file's ChatSession is imported as 'core::ChatSession' when needed via prefix.

/// Represents a single message in the chat session.
class ChatMessage {
  ChatMessage({required this.role, required this.content, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  ChatMessage copyWith({String? role, String? content, DateTime? timestamp}) =>
      ChatMessage(
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
      );
}

/// Maximum number of messages to send to the model in a single request.
const int maxChatHistory = 12;

/// Chat session for guided slot-filling conversation.
class ChatSession {
  ChatSession({
    int? id,
    DateTime? created,
    List<ChatMessage>? messages,
    PlanHeader? header,
    List<GradeInput>? grades,
    String? sharedSubTheme,
    String? multigradeModel,
    OutputLanguage? outputLanguage,
  }) : id = id ?? 0,
       created = created ?? DateTime.now(),
       messages = messages ?? const [],
       header =
           header ??
           PlanHeader(
             school: '',
             teacher: '',
             learningArea: '',
             date: '',
             term: '',
             sessions: 1,
             sessionMinutes: 90,
             multigradeModel: 'STDT',
           ),
       grades = grades ?? const [],
       sharedSubTheme = sharedSubTheme ?? '',
       multigradeModel = multigradeModel ?? 'STDT',
       outputLanguage = outputLanguage ?? OutputLanguage.filipino;

  final int id;
  final DateTime created;
  final List<ChatMessage> messages;
  final PlanHeader header;
  final List<GradeInput> grades;
  final String sharedSubTheme;
  final String multigradeModel;
  final OutputLanguage outputLanguage;

  /// Returns a GenerationRequest built from the draft fields.
  GenerationRequest toGenerationRequest() => GenerationRequest(
    header: header,
    grades: grades,
    sharedSubTheme: sharedSubTheme,
    language: outputLanguage,
  );

  /// Builds a ChatSession from a GenerationRequest (for starting from form).
  factory ChatSession.fromGenerationRequest(GenerationRequest request) {
    return ChatSession(
      header: request.header,
      grades: request.grades,
      sharedSubTheme: request.sharedSubTheme,
      multigradeModel: request.header.multigradeModel,
      outputLanguage: request.language,
    );
  }

  /// Checks if the session has enough information to generate a plan.
  bool get canGenerate {
    if (header.school.isEmpty ||
        header.teacher.isEmpty ||
        header.learningArea.isEmpty ||
        header.date.isEmpty ||
        header.term.isEmpty) {
      return false;
    }
    if (header.sessionMinutes <= 0 || header.sessions <= 0) {
      return false;
    }
    if (sharedSubTheme.isEmpty) {
      return false;
    }
    if (grades.isEmpty) {
      return false;
    }
    for (final g in grades) {
      if (g.gradeLabel.isEmpty || g.subTheme.isEmpty || g.competency.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created': created.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'header': header.toJson(),
    'grades': grades
        .map(
          (g) => {
            'gradeLabel': g.gradeLabel,
            'male': g.male,
            'female': g.female,
            'subTheme': g.subTheme,
            'competency': g.competency,
          },
        )
        .toList(),
    'sharedSubTheme': sharedSubTheme,
    'multigradeModel': multigradeModel,
    'outputLanguage': outputLanguage.name,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    final gradesJson = json['grades'] as List<dynamic>? ?? [];
    final grades = gradesJson
        .map(
          (g) => GradeInput(
            gradeLabel: g['gradeLabel'] as String,
            male: g['male'] as int,
            female: g['female'] as int,
            subTheme: g['subTheme'] as String,
            competency: g['competency'] as String,
          ),
        )
        .toList();

    final headerJson = json['header'] as Map<String, dynamic>?;
    final header = headerJson != null
        ? PlanHeader.fromJson(headerJson)
        : PlanHeader(
            school: '',
            teacher: '',
            learningArea: '',
            date: '',
            term: '',
            sessions: 1,
            sessionMinutes: 90,
            multigradeModel: 'STDT',
          );

    final languageName = json['outputLanguage'] as String? ?? 'filipino';
    final outputLanguage = OutputLanguage.values.firstWhere(
      (e) => e.name == languageName,
      orElse: () => OutputLanguage.filipino,
    );

    return ChatSession(
      id: json['id'] as int? ?? 0,
      created: DateTime.parse(
        json['created'] as String? ?? DateTime.now().toIso8601String(),
      ),
      messages: messages,
      header: header,
      grades: grades,
      sharedSubTheme: json['sharedSubTheme'] as String? ?? '',
      multigradeModel: json['multigradeModel'] as String? ?? 'STDT',
      outputLanguage: outputLanguage,
    );
  }

  ChatSession copyWith({
    int? id,
    DateTime? created,
    List<ChatMessage>? messages,
    PlanHeader? header,
    List<GradeInput>? grades,
    String? sharedSubTheme,
    String? multigradeModel,
    OutputLanguage? outputLanguage,
  }) => ChatSession(
    id: id ?? this.id,
    created: created ?? this.created,
    messages: messages ?? List.from(this.messages),
    header: header ?? this.header,
    grades: grades ?? List.from(this.grades),
    sharedSubTheme: sharedSubTheme ?? this.sharedSubTheme,
    multigradeModel: multigradeModel ?? this.multigradeModel,
    outputLanguage: outputLanguage ?? this.outputLanguage,
  );

  /// Adds a message to the session, keeping history within the cap.
  ChatSession addMessage(ChatMessage message) {
    final newMessages = List<ChatMessage>.from(messages)..add(message);
    if (newMessages.length > maxChatHistory) {
      newMessages.removeAt(0);
    }
    return copyWith(messages: newMessages);
  }
}
