import 'package:ai_lesson_planner/core/chat/chat_session.dart' as chat;
import 'package:ai_lesson_planner/core/chat/slot_filler.dart' as slot_filler;
import 'package:ai_lesson_planner/core/chat/slot_schema.dart' as slot;
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage;
import 'package:ai_lesson_planner/core/llm/fake_engine.dart' as fake;
import 'package:ai_lesson_planner/core/llm/llm_engine.dart' show ModelSpec;
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' show PlanHeader;
import 'package:test/test.dart';

void main() {
  group('SlotFiller', () {
    group('processMessage', () {
      test('"Grade 3 and 4, Science, 90 minutes" fills three fields', () async {
        const userMessage = 'Grade 3 and 4, Science, 90 minutes';
        final session = _emptySession();
        final prompt = slot_filler.buildSlotExtractionPrompt(
          session,
          userMessage,
        );
        final engine = fake.FakeEngine(
          tokenSequences: {
            'user:$prompt;': fake.FakeTokenSequence(
              tokens: [
                '{"response": "Got it! Science, Grades 3-4, 90 minutes.", "patch": {"learningArea": "Science", "sessionMinutes": 90, "gradeLabels": ["Grade 3", "Grade 4"]}}',
              ],
            ),
          },
          useFullKey: true,
        );
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final result = await filler.processMessage(userMessage, session);

        expect(result.assistantResponse, contains('Science'));
        expect(result.assistantResponse, contains('90 minutes'));
        expect(result.patch['learningArea'], equals('Science'));
        expect(result.patch['sessionMinutes'], equals(90));
        expect(
          result.patch['gradeLabels'],
          containsAll(['Grade 3', 'Grade 4']),
        );
        expect(result.validationErrors, isEmpty);

        await engine.dispose();
      });

      test('invalid grade values are rejected', () async {
        final session = _emptySession();
        final prompt = slot_filler.buildSlotExtractionPrompt(
          session,
          'Grade 7, Science',
        );
        final engine = fake.FakeEngine(
          tokenSequences: {
            'user:$prompt;': fake.FakeTokenSequence(
              tokens: [
                '{"response": "Hmm, Grade 7 is not valid.", "patch": {"gradeLabels": ["Grade 7"]}}',
              ],
            ),
          },
          useFullKey: true,
        );
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final result = await filler.processMessage('Grade 7, Science', session);

        expect(result.validationErrors, isNotEmpty);
        expect(result.validationErrors, anyElement(contains('grades')));

        await engine.dispose();
      });

      test('unrelated chat does not change fields', () async {
        final session = _emptySession();
        final prompt = slot_filler.buildSlotExtractionPrompt(
          session,
          'Hello how are you',
        );
        final engine = fake.FakeEngine(
          tokenSequences: {
            'user:$prompt;': fake.FakeTokenSequence(
              tokens: [
                '{"response": "Hello! How can I help with your lesson?", "patch": {}}',
              ],
            ),
          },
          useFullKey: true,
        );
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final result = await filler.processMessage(
          'Hello how are you',
          session,
        );

        expect(result.assistantResponse, contains('Hello'));
        expect(result.patch, isEmpty);

        await engine.dispose();
      });

      test('partial fill works correctly', () async {
        final session = _emptySession();
        final prompt = slot_filler.buildSlotExtractionPrompt(
          session,
          'Science',
        );
        final engine = fake.FakeEngine(
          tokenSequences: {
            'user:$prompt;': fake.FakeTokenSequence(
              tokens: [
                '{"response": "Science noted. What grades and duration?", "patch": {"learningArea": "Science"}}',
              ],
            ),
          },
          useFullKey: true,
        );
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final result = await filler.processMessage('Science', session);

        expect(result.patch['learningArea'], equals('Science'));
        expect(result.patch['gradeLabels'], isNull);
        expect(result.patch['sessionMinutes'], isNull);

        await engine.dispose();
      });

      test('multi-field extraction in one response', () async {
        final session = _emptySession();
        final prompt = slot_filler.buildSlotExtractionPrompt(
          session,
          'We are teaching Science and Math to Grades 3-4 for 90 minutes in Filipino',
        );
        final engine = fake.FakeEngine(
          tokenSequences: {
            'user:$prompt;': fake.FakeTokenSequence(
              tokens: [
                '''{
                    "response": "Noted: Science and Math, Grades 3-4, 90 minutes, Filipino.",
                    "patch": {
                      "learningArea": "Science",
                      "sessionMinutes": 90,
                      "gradeLabels": ["Grade 3", "Grade 4"],
                      "outputLanguage": "filipino"
                    }
                  }''',
              ],
            ),
          },
          useFullKey: true,
        );
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final result = await filler.processMessage(
          'We are teaching Science and Math to Grades 3-4 for 90 minutes in Filipino',
          session,
        );

        expect(result.patch['sessionMinutes'], equals(90));
        expect(result.patch['gradeLabels'], contains('Grade 3'));
        expect(result.patch['gradeLabels'], contains('Grade 4'));
        expect(result.patch['outputLanguage'], equals('filipino'));

        await engine.dispose();
      });
    });

    group('applyPatchToSession', () {
      test('applies JSON patch to chat session', () {
        final session = _emptySession();
        final patch = {
          'learningArea': 'Science',
          'sessionMinutes': 90,
          'gradeLabels': ['Grade 3', 'Grade 4'],
          'outputLanguage': 'english',
          'school': 'Test School',
          'teacher': 'Test Teacher',
        };

        final updated = slot_filler.applyPatchToSession(session, patch);

        expect(updated.header.learningArea, equals('Science'));
        expect(updated.header.sessionMinutes, equals(90));
        expect(updated.grades.length, equals(2));
        expect(updated.grades[0].gradeLabel, equals('Grade 3'));
        expect(updated.grades[1].gradeLabel, equals('Grade 4'));
        expect(updated.outputLanguage, equals(OutputLanguage.english));
        expect(updated.header.school, equals('Test School'));
        expect(updated.header.teacher, equals('Test Teacher'));
      });

      test('preserves existing values not in patch', () {
        final session = _emptySession().copyWith(
          header: _emptySession().header.copyWith(
            school: 'Original School',
            teacher: 'Original Teacher',
            learningArea: 'Math',
            date: '2026-01-15',
            term: 'Term 1',
          ),
          sharedSubTheme: 'Original Theme',
        );

        final patch = {'learningArea': 'Science'};
        final updated = slot_filler.applyPatchToSession(session, patch);

        expect(updated.header.learningArea, equals('Science'));
        expect(updated.header.school, equals('Original School'));
        expect(updated.header.teacher, equals('Original Teacher'));
        expect(updated.header.date, equals('2026-01-15'));
        expect(updated.sharedSubTheme, equals('Original Theme'));
      });
    });

    group('getNextMissingField', () {
      test('returns school when missing', () {
        final session = _emptySession();
        expect(slot_filler.getNextMissingField(session), equals('school'));
      });

      test('returns teacher when school set but teacher missing', () {
        final session = _emptySession().copyWith(
          header: _emptySession().header.copyWith(school: 'Test School'),
        );
        expect(slot_filler.getNextMissingField(session), equals('teacher'));
      });

      test('returns learningArea when header fields set', () {
        final session = _emptySession().copyWith(
          header: _emptySession().header.copyWith(
            school: 'Test School',
            teacher: 'Test Teacher',
          ),
        );
        expect(
          slot_filler.getNextMissingField(session),
          equals('learningArea'),
        );
      });

      test('returns grades when all other fields set', () {
        final session = _emptySession().copyWith(
          header: PlanHeader(
            school: 'Test School',
            teacher: 'Test Teacher',
            learningArea: 'Science',
            date: '2026-01-15',
            term: 'Term 1',
            sessions: 1,
            sessionMinutes: 90,
            multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
          ),
          sharedSubTheme: 'Weather',
        );
        expect(slot_filler.getNextMissingField(session), equals('grades'));
      });

      test('returns gradeLabel when grades exist but missing label', () {
        final session = _emptySession().copyWith(
          header: PlanHeader(
            school: 'Test School',
            teacher: 'Test Teacher',
            learningArea: 'Science',
            date: '2026-01-15',
            term: 'Term 1',
            sessions: 1,
            sessionMinutes: 90,
            multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
          ),
          sharedSubTheme: 'Weather',
          grades: [
            GradeInput(
              gradeLabel: '',
              male: 5,
              female: 5,
              subTheme: '',
              competency: '',
            ),
          ],
        );
        expect(slot_filler.getNextMissingField(session), equals('gradeLabel'));
      });

      test('returns "all filled" when complete', () {
        final session = chat.ChatSession(
          header: PlanHeader(
            school: 'Test School',
            teacher: 'Test Teacher',
            learningArea: 'Science',
            date: '2026-01-15',
            term: 'Term 1',
            sessions: 1,
            sessionMinutes: 90,
            multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
          ),
          sharedSubTheme: 'Weather',
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
              subTheme: 'Weather',
              competency: 'S4.1.1',
            ),
          ],
          outputLanguage: OutputLanguage.filipino,
        );
        expect(slot_filler.getNextMissingField(session), equals('all filled'));
      });
    });

    group('SlotSchema validation', () {
      test('isValidGradeLabel accepts valid formats', () {
        expect(slot.SlotSchema.isValidGradeLabel('Grade 3'), isTrue);
        expect(slot.SlotSchema.isValidGradeLabel('Grade 4'), isTrue);
        expect(slot.SlotSchema.isValidGradeLabel('GRADE 5'), isTrue);
        expect(slot.SlotSchema.isValidGradeLabel('Grade 6'), isTrue);
      });

      test('isValidGradeLabel rejects invalid formats', () {
        expect(slot.SlotSchema.isValidGradeLabel('3'), isFalse);
        expect(slot.SlotSchema.isValidGradeLabel('Grade'), isFalse);
        expect(slot.SlotSchema.isValidGradeLabel(''), isFalse);
      });

      test('isValidSessionMinutes accepts valid values', () {
        expect(slot.SlotSchema.isValidSessionMinutes(60), isTrue);
        expect(slot.SlotSchema.isValidSessionMinutes(90), isTrue);
        expect(slot.SlotSchema.isValidSessionMinutes(120), isTrue);
      });

      test('isValidSessionMinutes rejects invalid values', () {
        expect(slot.SlotSchema.isValidSessionMinutes(45), isFalse);
        expect(slot.SlotSchema.isValidSessionMinutes(30), isFalse);
        expect(slot.SlotSchema.isValidSessionMinutes(180), isFalse);
      });

      test('isValidGradeCount validates range', () {
        expect(slot.SlotSchema.isValidGradeCount(2), isTrue);
        expect(slot.SlotSchema.isValidGradeCount(6), isTrue);
        expect(slot.SlotSchema.isValidGradeCount(1), isFalse);
        expect(slot.SlotSchema.isValidGradeCount(7), isFalse);
      });
    });

    group('isFreeFormRequest detection', () {
      test('detects "make a lesson plan" request', () {
        final engine = fake.FakeEngine(tokenSequences: {});
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);
        // This test verifies the method exists and works
        expect(
          filler.isFreeFormRequest('make a lesson plan about photosynthesis'),
          isTrue,
        );
      });

      test('detects "generate lesson plan" request', () {
        final engine = fake.FakeEngine(tokenSequences: {});
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);
        expect(
          filler.isFreeFormRequest('generate lesson plan for Grade 5'),
          isTrue,
        );
      });

      test('does not detect slot-filling messages', () {
        final engine = fake.FakeEngine(tokenSequences: {});
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);
        expect(filler.isFreeFormRequest('Science'), isFalse);
        expect(filler.isFreeFormRequest('Grade 3 and 4, 90 minutes'), isFalse);
      });
    });

    group('Full lesson plan generation', () {
      test('builds correct lesson plan prompt', () {
        final engine = fake.FakeEngine(tokenSequences: {});
        final filler = slot_filler.SlotFiller(engine: engine, seed: 42);
        final prompt = filler.buildLessonPlanPrompt(
          'Make a lesson plan about photosynthesis for Grade 5, 60 minutes, in Filipino',
        );
        expect(prompt, contains('You are an AI lesson plan assistant'));
        expect(prompt, contains('generate a complete DepEd ILAW lesson plan'));
        expect(prompt, contains('User Request:'));
        expect(prompt, contains('photosynthesis'));
        expect(prompt, contains('Grade 5'));
      });
    });
  });
}

/// Creates an empty chat session for testing.
chat.ChatSession _emptySession() {
  return chat.ChatSession(
    header: PlanHeader(
      school: '',
      teacher: '',
      learningArea: '',
      date: '',
      term: '',
      sessions: 1,
      sessionMinutes: 90,
      multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
    ),
    grades: [],
    sharedSubTheme: '',
    outputLanguage: OutputLanguage.filipino,
  );
}
