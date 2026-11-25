import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/llm_lesson_generator.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/llm/fake_engine.dart';
import 'package:test/test.dart';

void main() {
  group('LlmLessonGenerator', () {
    test('cancel() works without error', () {
      final engine = FakeEngine();
      final generator = LlmLessonGenerator(engine: engine, seed: 42);

      generator.cancel();
      engine.dispose();
    });

    test('generateSection for header returns completed immediately', () async {
      final engine = FakeEngine();
      final generator = LlmLessonGenerator(engine: engine, seed: 42);

      final header = PlanHeader(
        school: 'Test School',
        teacher: 'Test Teacher',
        learningArea: 'Science',
        date: '2024-01-15',
        term: 'First',
        sessions: 2,
        sessionMinutes: 90,
        multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
      );

      final request = GenerationRequest(
        header: header,
        grades: [],
        sharedSubTheme: 'Test',
        language: OutputLanguage.filipino,
      );

      final emptyPlan = LessonPlan(
        header: header,
        grades: [],
        sharedSubTheme: '',
        bothGradesObjective: '',
        learnerContext: '',
        materials: Materials(),
        flow: [],
        assessments: [],
        reflectionQuestions: [],
        waysForward: [],
        notesNextSession: '',
        preparedBy: header.teacher,
        checkedBy: header.teacher,
        aiUseDeclaration: '',
      );

      var completed = false;
      await for (final event in generator.generateSection(request, PlanSection.header, emptyPlan)) {
        if (event is GenerationCompleted) {
          completed = true;
        }
      }

      expect(completed, isTrue);
      await engine.dispose();
    });
  });
}
