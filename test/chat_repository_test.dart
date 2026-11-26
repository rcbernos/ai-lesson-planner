import 'dart:io';

import 'package:ai_lesson_planner/core/chat/chat_session.dart' as chat;
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage, GenerationRequest;
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' show PlanHeader;
import 'package:ai_lesson_planner/services/database/app_database.dart';
import 'package:ai_lesson_planner/services/database/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late File dbFile;
  late ChatRepository repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ai_lesson_planner_test');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}test.db');
    db = AppDatabase.forTesting(dbFile);
    repo = ChatRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ChatSession model', () {
    test('canGenerate returns true for complete session', () {
      final session = chat.ChatSession(
        header: PlanHeader(
          school: 'Test School',
          teacher: 'Test Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 3',
            male: 5,
            female: 5,
            subTheme: 'Ecosystems',
            competency: 'S3.1.1',
          ),
          GradeInput(
            gradeLabel: 'Grade 4',
            male: 4,
            female: 4,
            subTheme: 'Ecosystems',
            competency: 'S4.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things in the Environment',
        outputLanguage: OutputLanguage.filipino,
      );

      expect(session.canGenerate, isTrue);
    });

    test('canGenerate returns false for incomplete session', () {
      final session = chat.ChatSession(
        header: PlanHeader(
          school: '', // Empty - should fail
          teacher: 'Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 3',
            male: 5,
            female: 5,
            subTheme: '', // Empty - should fail
            competency: '', // Empty - should fail
          ),
        ],
        sharedSubTheme: 'Theme',
        outputLanguage: OutputLanguage.filipino,
      );

      expect(session.canGenerate, isFalse);
    });

    test('toGenerationRequest builds from session fields', () {
      final session = chat.ChatSession(
        header: PlanHeader(
          school: 'Test School',
          teacher: 'Test Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 2,
          sessionMinutes: 120,
          multigradeModel: 'Peer Leader',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 5',
            male: 6,
            female: 4,
            subTheme: 'Matter',
            competency: 'S5.1.1',
          ),
        ],
        sharedSubTheme: 'Properties of Matter',
        outputLanguage: OutputLanguage.english,
      );

      final request = session.toGenerationRequest();
      expect(request.header.school, equals('Test School'));
      expect(request.header.teacher, equals('Test Teacher'));
      expect(request.header.learningArea, equals('Science'));
      expect(request.header.sessions, equals(2));
      expect(request.header.sessionMinutes, equals(120));
      expect(request.sharedSubTheme, equals('Properties of Matter'));
      expect(request.language, equals(OutputLanguage.english));
      expect(request.grades.length, equals(1));
      expect(request.grades[0].gradeLabel, equals('Grade 5'));
    });

    test('addMessage caps history at maxChatHistory', () {
      var session = chat.ChatSession(
        header: PlanHeader(
          school: 'School',
          teacher: 'Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        sharedSubTheme: 'Theme',
      );

      for (var i = 0; i < 15; i++) {
        session = session.addMessage(
          chat.ChatMessage(role: 'user', content: 'Message $i'),
        );
      }

      expect(session.messages.length, equals(12));
      expect(session.messages.first.content, equals('Message 3'));
      expect(session.messages.last.content, equals('Message 14'));
    });
  });

  group('ChatSession JSON round-trip', () {
    test('toJson and fromJson round-trip', () {
      final session = chat.ChatSession(
        header: PlanHeader(
          school: 'Test School',
          teacher: 'Test Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 3',
            male: 5,
            female: 5,
            subTheme: 'Ecosystems',
            competency: 'S3.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      final json = session.toJson();
      final restored = chat.ChatSession.fromJson(json);

      expect(restored.id, equals(session.id));
      expect(restored.header.school, equals(session.header.school));
      expect(restored.header.teacher, equals(session.header.teacher));
      expect(restored.sharedSubTheme, equals(session.sharedSubTheme));
      expect(restored.outputLanguage, equals(OutputLanguage.english));
      expect(restored.grades.length, equals(1));
      expect(restored.grades[0].gradeLabel, equals('Grade 3'));
    });
  });

  group('ChatSessionData model', () {
    test('toJson and fromJson round-trip', () {
      final session = chat.ChatSession(
        header: PlanHeader(
          school: 'Test School',
          teacher: 'Test Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 3',
            male: 5,
            female: 5,
            subTheme: 'Ecosystems',
            competency: 'S3.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      final json = session.toJson();
      final restored = chat.ChatSession.fromJson(json);

      expect(restored.id, equals(session.id));
      expect(restored.header.school, equals(session.header.school));
      expect(restored.header.teacher, equals(session.header.teacher));
      expect(restored.sharedSubTheme, equals(session.sharedSubTheme));
      expect(restored.outputLanguage, equals(OutputLanguage.english));
      expect(restored.grades.length, equals(1));
      expect(restored.grades[0].gradeLabel, equals('Grade 3'));
    });
  });
}
