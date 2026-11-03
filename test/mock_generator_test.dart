import 'package:test/test.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/mock_lesson_generator.dart';

void main() {
  group('MockLessonGenerator', () {
    late MockLessonGenerator generator;

    setUp(() {
      generator = MockLessonGenerator();
    });

    test('emits all four sections in correct order', () async {
      final request = GenerationRequest(
        header: PlanHeader(
          school: 'Test',
          teacher: 'Test',
          learningArea: 'Filipino',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
              gradeLabel: 'Grade 3',
              male: 3,
              female: 3,
              subTheme: 'Test',
              competency: 'Test')
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.filipino,
      );

      final events = <GenerationEvent>[];
      await for (final event in generator.generate(request)) {
        events.add(event);
      }

      expect(events[0], isA<SectionStarted>());
      expect((events[0] as SectionStarted).name, equals('Intentions'));
      expect(events[1], isA<SectionCompleted>());
      expect((events[1] as SectionCompleted).name, equals('Intentions'));
      expect(events[2], isA<SectionStarted>());
      expect(
          (events[2] as SectionStarted).name, equals('Learning Experiences'));
      expect(events[3], isA<SectionCompleted>());
      expect(events[4], isA<SectionStarted>());
      expect((events[4] as SectionStarted).name, equals('Assessment'));
      expect(events[5], isA<SectionCompleted>());
      expect(events[6], isA<SectionStarted>());
      expect((events[6] as SectionStarted).name, equals('Ways Forward'));
      expect(events[7], isA<SectionCompleted>());
      expect(events[8], isA<GenerationCompleted>());
    });

    test('plan has one GradeBlock per requested grade', () async {
      final request = GenerationRequest(
        header: PlanHeader(
          school: 'Test',
          teacher: 'Test',
          learningArea: 'Filipino',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
              gradeLabel: 'Grade 3',
              male: 3,
              female: 3,
              subTheme: 'Test',
              competency: 'Comp 1'),
          GradeInput(
              gradeLabel: 'Grade 4',
              male: 2,
              female: 2,
              subTheme: 'Test',
              competency: 'Comp 2'),
          GradeInput(
              gradeLabel: 'Grade 5',
              male: 1,
              female: 1,
              subTheme: 'Test',
              competency: 'Comp 3'),
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.english,
      );

      final plan = await _getCompletedPlan(generator.generate(request));
      expect(plan.grades.length, equals(3));
      expect(plan.grades[0].gradeLabel, equals('Grade 3'));
      expect(plan.grades[1].gradeLabel, equals('Grade 4'));
      expect(plan.grades[2].gradeLabel, equals('Grade 5'));
    });

    test('flow minutes sum to sessionMinutes', () async {
      final request = GenerationRequest(
        header: PlanHeader(
          school: 'Test',
          teacher: 'Test',
          learningArea: 'Filipino',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 120,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
              gradeLabel: 'Grade 3',
              male: 3,
              female: 3,
              subTheme: 'Test',
              competency: 'Test')
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.filipino,
      );

      final plan = await _getCompletedPlan(generator.generate(request));
      expect(plan.totalFlowMinutes, equals(120));
    });

    test('cancel() stops the stream', () async {
      final request = GenerationRequest(
        header: PlanHeader(
          school: 'Test',
          teacher: 'Test',
          learningArea: 'Filipino',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'STDT',
        ),
        grades: [
          GradeInput(
              gradeLabel: 'Grade 3',
              male: 3,
              female: 3,
              subTheme: 'Test',
              competency: 'Test')
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.filipino,
      );

      final stream = generator.generate(request);
      generator.cancel();

      final events = <GenerationEvent>[];
      await for (final event in stream) {
        events.add(event);
      }

      final hasCompleted = events.any((e) => e is GenerationCompleted);
      expect(hasCompleted, isFalse);
    });
  });
}

Future<LessonPlan> _getCompletedPlan(Stream<GenerationEvent> stream) async {
  await for (final event in stream) {
    if (event is GenerationCompleted) {
      return event.plan;
    }
  }
  throw StateError('Generation did not complete');
}
