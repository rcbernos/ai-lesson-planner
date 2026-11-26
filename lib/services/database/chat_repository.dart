/// Repository for managing chat sessions.
library;

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:ai_lesson_planner/core/chat/chat_session.dart'
    as chat
    show ChatSession, ChatMessage;
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage;
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' show PlanHeader;
import 'package:ai_lesson_planner/services/database/app_database.dart';
import 'package:ai_lesson_planner/services/database/database_helper.dart';

/// Repository for persisting and retrieving chat sessions.
class ChatRepository {
  ChatRepository([AppDatabase? db]) : _db = db ?? DatabaseHelper.instance.db;
  final AppDatabase _db;

  /// Saves a chat session to the database.
  /// Returns the session ID (inserts new or updates existing).
  Future<int> save(chat.ChatSession session) async {
    final companion = ChatSessionsCompanion(
      id: drift.Value(session.id),
      created: drift.Value(session.created),
      messages: drift.Value(
        jsonEncode(session.messages.map((m) => m.toJson()).toList()),
      ),
      header: drift.Value(jsonEncode(session.header.toJson())),
      grades: drift.Value(
        jsonEncode(
          session.grades
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
        ),
      ),
      sharedSubTheme: drift.Value(session.sharedSubTheme),
      multigradeModel: drift.Value(session.multigradeModel),
      outputLanguage: drift.Value(session.outputLanguage.name),
    );

    if (session.id == 0) {
      // New session
      return await _db.insertChatSession(companion);
    } else {
      // Existing session - use update
      await _db.updateChatSession(
        ChatSession(
          id: session.id,
          created: session.created,
          messages: jsonEncode(
            session.messages.map((m) => m.toJson()).toList(),
          ),
          header: jsonEncode(session.header.toJson()),
          grades: jsonEncode(
            session.grades
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
          ),
          sharedSubTheme: session.sharedSubTheme,
          multigradeModel: session.multigradeModel,
          outputLanguage: session.outputLanguage.name,
        ),
      );
      return session.id;
    }
  }

  /// Gets all chat sessions, most recent first.
  Future<List<chat.ChatSession>> getAll() async {
    final rows = await _db.getAllChatSessions();
    return rows.map(_fromDataRow).toList();
  }

  /// Gets a chat session by ID.
  Future<chat.ChatSession?> getById(int id) async {
    final row = await _db.getChatSessionById(id);
    if (row == null) return null;
    return _fromDataRow(row);
  }

  /// Deletes a chat session.
  Future<void> delete(int id) async {
    await _db.deleteChatSession(id);
  }

  /// Clears all chat sessions.
  Future<void> clearAll() async {
    await (_db.delete(_db.chatSessions)).go();
  }

  /// Converts a database row to a ChatSession model.
  chat.ChatSession _fromDataRow(ChatSession row) {
    final messagesJson = jsonDecode(row.messages) as List<dynamic>;
    final messages = messagesJson
        .map((m) => chat.ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    final gradesJson = jsonDecode(row.grades) as List<dynamic>;
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

    final headerJson = jsonDecode(row.header) as Map<String, dynamic>;
    final header = PlanHeader.fromJson(headerJson);

    final languageName = row.outputLanguage;
    final outputLanguage = OutputLanguage.values.firstWhere(
      (e) => e.name == languageName,
      orElse: () => OutputLanguage.filipino,
    );

    return chat.ChatSession(
      id: row.id,
      created: row.created,
      messages: messages,
      header: header,
      grades: grades,
      sharedSubTheme: row.sharedSubTheme,
      multigradeModel: row.multigradeModel,
      outputLanguage: outputLanguage,
    );
  }
}
