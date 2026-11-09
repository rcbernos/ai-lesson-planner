import 'dart:convert';

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

    test('competencyIndexByGrade is populated for non-whole-class stages',
        () async {
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
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.english,
      );

      final plan = await _getCompletedPlan(generator.generate(request));

      // Check whole-class stages have empty competencyIndexByGrade
      for (final stage in plan.flow) {
        if (stage.wholeClass) {
          expect(stage.competencyIndexByGrade, isEmpty,
              reason:
                  'Whole-class stage "${stage.stage}" should have empty map');
        }
      }

      // Check non-whole-class stages have index for each grade
      final nonWholeClassStages =
          plan.flow.where((s) => !s.wholeClass).toList();
      for (final stage in nonWholeClassStages) {
        for (final grade in plan.grades) {
          expect(stage.competencyIndexByGrade[grade.gradeLabel], equals(0),
              reason:
                  'Stage "${stage.stage}" should have index 0 for ${grade.gradeLabel}');
        }
      }
    });

    test('competencyIndex is set for assessments', () async {
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
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.english,
      );

      final plan = await _getCompletedPlan(generator.generate(request));

      for (final assessment in plan.assessments) {
        expect(assessment.competencyIndex, equals(0),
            reason:
                'Assessment for ${assessment.gradeLabel} should have competencyIndex 0');
      }
    });

    test('competency indices are within range for each grade', () async {
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
              competency: 'Comp 3'),
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.filipino,
      );

      final plan = await _getCompletedPlan(generator.generate(request));

      // Check flow stages
      for (final stage in plan.flow) {
        for (final entry in stage.competencyIndexByGrade.entries) {
          final gradeLabel = entry.key;
          final index = entry.value;
          final grade =
              plan.grades.firstWhere((g) => g.gradeLabel == gradeLabel);
          expect(index, inInclusiveRange(0, grade.competencies.length - 1),
              reason: 'Index $index for $gradeLabel out of range '
                  '(competencies: ${grade.competencies.length})');
        }
      }

      // Check assessments
      for (final assessment in plan.assessments) {
        if (assessment.competencyIndex != null) {
          final grade = plan.grades
              .firstWhere((g) => g.gradeLabel == assessment.gradeLabel);
          expect(assessment.competencyIndex,
              inInclusiveRange(0, grade.competencies.length - 1),
              reason: 'Assessment index ${assessment.competencyIndex} for '
                  '${assessment.gradeLabel} out of range');
        }
      }
    });

    test('version 1 JSON loads with empty maps and null indexes', () async {
      // Create a plan with no competencyIndexByGrade / competencyIndex
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
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.filipino,
      );

      final plan = await _getCompletedPlan(generator.generate(request));

      // Create JSON and remove the new fields to simulate v1 format
      final jsonMap = Map<String, dynamic>.from(plan.toJson());
      jsonMap['schemaVersion'] = 1;

      // Remove competencyIndexByGrade from flow stages
      for (var stage in jsonMap['flow'] as List) {
        (stage as Map<String, dynamic>).remove('competencyIndexByGrade');
      }

      // Remove competencyIndex from assessments
      for (var assessment in jsonMap['assessments'] as List) {
        (assessment as Map<String, dynamic>).remove('competencyIndex');
      }

      // Also remove schemaVersion to test default behavior
      jsonMap.remove('schemaVersion');

      final json = jsonEncode(jsonMap);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final result = LessonPlan.fromJson(decoded);

      // Flow stages should have empty maps
      for (final stage in result.flow) {
        expect(stage.competencyIndexByGrade, isEmpty,
            reason:
                'Flow stage should have empty competencyIndexByGrade in v1');
      }

      // Assessments should have null competencyIndex
      for (final assessment in result.assessments) {
        expect(assessment.competencyIndex, isNull,
            reason: 'Assessment should have null competencyIndex in v1');
      }
    });

    test('JSON round-trip preserves competency indexes', () async {
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
        ],
        sharedSubTheme: 'Theme',
        language: OutputLanguage.filipino,
      );

      final plan = await _getCompletedPlan(generator.generate(request));

      // Round-trip through JSON
      final json = jsonEncode(plan.toJson());
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final result = LessonPlan.fromJson(decoded);

      // Verify flow stages
      for (int i = 0; i < plan.flow.length; i++) {
        expect(result.flow[i].competencyIndexByGrade,
            equals(plan.flow[i].competencyIndexByGrade),
            reason: 'Flow stage $i competencyIndexByGrade mismatch');
      }

      // Verify assessments
      for (int i = 0; i < plan.assessments.length; i++) {
        expect(result.assessments[i].competencyIndex,
            equals(plan.assessments[i].competencyIndex),
            reason: 'Assessment $i competencyIndex mismatch');
      }
    });

    test('GenerationRequest.fromPlan builds correct request', () async {
      final plan = LessonPlan(
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
        grades: [
          GradeBlock(
            gradeLabel: 'Grade 3',
            learnersMale: 5,
            learnersFemale: 5,
            subTheme: 'Theme',
            contentStandard: 'Standard',
            performanceStandard: 'Performance',
            competencies: ['Comp 1', 'Comp 2'],
            objectives: ['Obj 1', 'Obj 2'],
          ),
          GradeBlock(
            gradeLabel: 'Grade 4',
            learnersMale: 4,
            learnersFemale: 4,
            subTheme: 'Theme',
            contentStandard: 'Standard',
            performanceStandard: 'Performance',
            competencies: ['Comp 3'],
            objectives: ['Obj 3'],
          ),
        ],
        sharedSubTheme: 'Theme',
        bothGradesObjective: 'Both',
        learnerContext: 'Context',
        materials: Materials(
          items: ['M'],
          references: ['R'],
        ),
        flow: [],
        assessments: [],
        reflectionQuestions: [],
        waysForward: [],
        notesNextSession: 'Next',
        preparedBy: 'Teacher',
        checkedBy: 'Checker',
        aiUseDeclaration: defaultAiUseDeclaration,
      );

      final request = GenerationRequest.fromPlan(plan, OutputLanguage.english);

      expect(request.header, equals(plan.header));
      expect(request.sharedSubTheme, equals('Theme'));
      expect(request.language, equals(OutputLanguage.english));
      expect(request.grades.length, equals(2));
      expect(request.grades[0].gradeLabel, equals('Grade 3'));
      expect(request.grades[0].competency, equals('Comp 1; Comp 2'));
      expect(request.grades[1].gradeLabel, equals('Grade 4'));
      expect(request.grades[1].competency, equals('Comp 3'));
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
