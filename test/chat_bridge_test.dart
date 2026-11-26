import 'package:ai_lesson_planner/core/chat/chat_session.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage;
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' show PlanHeader;
import 'package:ai_lesson_planner/features/generator/generator_form_state.dart';
import 'package:test/test.dart';

void main() {
  group('Chat Bridge', () {
    test(
      'ChatSession.toGenerationRequest() and back produces equivalent results',
      () {
        final session = ChatSession(
          header: PlanHeader(
            school: 'Test School',
            teacher: 'Test Teacher',
            learningArea: 'Science',
            date: '2026-01-15',
            term: 'Term 1',
            sessions: 2,
            sessionMinutes: 90,
            multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
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
              subTheme: 'Weather',
              competency: 'S4.1.1',
            ),
          ],
          sharedSubTheme: 'Living Things in the Environment',
          outputLanguage: OutputLanguage.english,
        );

        // Convert to GenerationRequest
        final request = session.toGenerationRequest();

        // Convert back to GeneratorFormState
        final formState = GeneratorFormState.fromGenerationRequest(request);

        // Compare form state fields with original chat session
        expect(formState.school, equals(session.header.school));
        expect(formState.teacher, equals(session.header.teacher));
        expect(formState.learningArea, equals(session.header.learningArea));
        expect(formState.date, equals(session.header.date));
        expect(formState.term, equals(session.header.term));
        expect(formState.sessions, equals(session.header.sessions));
        expect(formState.sessionMinutes, equals(session.header.sessionMinutes));
        expect(
          formState.multigradeModel,
          equals(session.header.multigradeModel),
        );
        expect(formState.sharedSubTheme, equals(session.sharedSubTheme));
        expect(formState.outputLanguage, equals(session.outputLanguage));
      },
    );

    test('Form state matches chat draft for all fields', () {
      final session = ChatSession(
        header: PlanHeader(
          school: 'Remote Village Elementary',
          teacher: 'Maria Santos',
          learningArea: 'MATH',
          date: '01/15/2026',
          term: 'Third Term',
          sessions: 3,
          sessionMinutes: 120,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 2',
            male: 8,
            female: 7,
            subTheme: 'Numbers up to 100',
            competency: 'M2NS-II.1.1',
          ),
          GradeInput(
            gradeLabel: 'Grade 3',
            male: 10,
            female: 9,
            subTheme: 'Addition and Subtraction',
            competency: 'M3NS-II.2.1',
          ),
        ],
        sharedSubTheme: 'Basic Operations',
        outputLanguage: OutputLanguage.filipino,
      );

      final request = session.toGenerationRequest();
      final formState = GeneratorFormState.fromGenerationRequest(request);

      // Verify all header fields
      expect(formState.school, equals('Remote Village Elementary'));
      expect(formState.teacher, equals('Maria Santos'));
      expect(formState.learningArea, equals('MATH'));
      expect(formState.date, equals('01/15/2026'));
      expect(formState.term, equals('Third Term'));
      expect(formState.sessions, equals(3));
      expect(formState.sessionMinutes, equals(120));
      expect(formState.multigradeModel, equals('STDT'));

      // Verify shared sub-theme
      expect(formState.sharedSubTheme, equals('Basic Operations'));

      // Verify output language
      expect(formState.outputLanguage, equals(OutputLanguage.filipino));

      // Verify grades
      expect(formState.grades.length, equals(2));

      expect(formState.grades[0].gradeLabel, equals('Grade 2'));
      expect(formState.grades[0].male, equals(8));
      expect(formState.grades[0].female, equals(7));
      expect(formState.grades[0].subTheme, equals('Numbers up to 100'));
      expect(formState.grades[0].competency, equals('M2NS-II.1.1'));

      expect(formState.grades[1].gradeLabel, equals('Grade 3'));
      expect(formState.grades[1].male, equals(10));
      expect(formState.grades[1].female, equals(9));
      expect(formState.grades[1].subTheme, equals('Addition and Subtraction'));
      expect(formState.grades[1].competency, equals('M3NS-II.2.1'));
    });

    test('canGenerate returns true for complete chat session', () {
      final session = ChatSession(
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
            subTheme: 'Weather',
            competency: 'S4.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things in the Environment',
        outputLanguage: OutputLanguage.english,
      );

      final request = session.toGenerationRequest();
      final formState = GeneratorFormState.fromGenerationRequest(request);

      expect(session.canGenerate, isTrue);
      expect(formState.canGenerate, isTrue);
    });

    test('canGenerate returns false for incomplete chat session', () {
      // Missing school
      final incompleteSession1 = ChatSession(
        header: PlanHeader(
          school: '', // Empty - should fail
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
            subTheme: 'Weather',
            competency: 'S4.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      final request1 = incompleteSession1.toGenerationRequest();
      final formState1 = GeneratorFormState.fromGenerationRequest(request1);

      expect(incompleteSession1.canGenerate, isFalse);
      expect(formState1.canGenerate, isFalse);

      // Missing grade label
      final incompleteSession2 = ChatSession(
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
            gradeLabel: '', // Empty - should fail
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
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      final request2 = incompleteSession2.toGenerationRequest();
      final formState2 = GeneratorFormState.fromGenerationRequest(request2);

      expect(incompleteSession2.canGenerate, isFalse);
      expect(formState2.canGenerate, isFalse);

      // Missing grade subTheme
      final incompleteSession3 = ChatSession(
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
            subTheme: '', // Empty - should fail
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
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      final request3 = incompleteSession3.toGenerationRequest();
      final formState3 = GeneratorFormState.fromGenerationRequest(request3);

      expect(incompleteSession3.canGenerate, isFalse);
      expect(formState3.canGenerate, isFalse);

      // Missing grade competency
      final incompleteSession4 = ChatSession(
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
            competency: '', // Empty - should fail
          ),
          GradeInput(
            gradeLabel: 'Grade 4',
            male: 4,
            female: 4,
            subTheme: 'Weather',
            competency: 'S4.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      final request4 = incompleteSession4.toGenerationRequest();
      final formState4 = GeneratorFormState.fromGenerationRequest(request4);

      expect(incompleteSession4.canGenerate, isFalse);
      expect(formState4.canGenerate, isFalse);
    });
  });
}
