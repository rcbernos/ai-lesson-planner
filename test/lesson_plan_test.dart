import 'dart:convert';

import 'package:test/test.dart';

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'fixtures/sample_plan.dart';

void main() {
  group('LessonPlan domain model', () {
    late LessonPlan samplePlan;

    setUp(() {
      samplePlan = createSamplePlan();
    });

    group('PlanHeader', () {
      test('JSON round-trip preserves all fields', () {
        final json = jsonEncode(samplePlan.header.toJson());
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final header = PlanHeader.fromJson(decoded);

        expect(header.school, equals(samplePlan.header.school));
        expect(header.teacher, equals(samplePlan.header.teacher));
        expect(header.learningArea, equals(samplePlan.header.learningArea));
        expect(header.date, equals(samplePlan.header.date));
        expect(header.term, equals(samplePlan.header.term));
        expect(header.sessions, equals(samplePlan.header.sessions));
        expect(header.sessionMinutes, equals(samplePlan.header.sessionMinutes));
        expect(
            header.multigradeModel, equals(samplePlan.header.multigradeModel));
      });

      test('copyWith creates modified copy', () {
        final updated = samplePlan.header.copyWith(
          teacher: 'Juan Dela Cruz',
        );
        expect(updated.teacher, equals('Juan Dela Cruz'));
        expect(updated.school, equals(samplePlan.header.school));
      });
    });

    group('GradeBlock', () {
      test('JSON round-trip preserves all fields', () {
        final grade = samplePlan.grades.first;
        final json = jsonEncode(grade.toJson());
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final block = GradeBlock.fromJson(decoded);

        expect(block.gradeLabel, equals(grade.gradeLabel));
        expect(block.learnersMale, equals(grade.learnersMale));
        expect(block.learnersFemale, equals(grade.learnersFemale));
        expect(block.subTheme, equals(grade.subTheme));
        expect(block.contentStandard, equals(grade.contentStandard));
        expect(block.performanceStandard, equals(grade.performanceStandard));
        expect(block.competencies, equals(grade.competencies));
        expect(block.objectives, equals(grade.objectives));
      });
    });

    group('FlowStage', () {
      test('JSON round-trip preserves all fields', () {
        final stage = samplePlan.flow.first;
        final json = jsonEncode(stage.toJson());
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final result = FlowStage.fromJson(decoded);

        expect(result.minutes, equals(stage.minutes));
        expect(result.stage, equals(stage.stage));
        expect(result.wholeClass, equals(stage.wholeClass));
        expect(result.activityByGrade, equals(stage.activityByGrade));
        expect(result.wholeClassActivity, equals(stage.wholeClassActivity));
      });
    });

    group('Flow minutes sum', () {
      test('flow minutes sum equals sessionMinutes', () {
        final totalFlowMinutes = samplePlan.totalFlowMinutes;
        expect(totalFlowMinutes, equals(samplePlan.header.sessionMinutes));
      });
    });

    group('LessonPlan', () {
      test('JSON round-trip equals original', () {
        final json = jsonEncode(samplePlan.toJson());
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final result = LessonPlan.fromJson(decoded);

        // Compare header
        expect(result.header.school, equals(samplePlan.header.school));
        expect(result.header.teacher, equals(samplePlan.header.teacher));

        // Compare grades count
        expect(result.grades.length, equals(samplePlan.grades.length));

        // Compare flow count
        expect(result.flow.length, equals(samplePlan.flow.length));
      });

      test('has correct number of grade blocks', () {
        expect(samplePlan.grades.length, equals(2));
      });

      test('grades are Grade 3 and Grade 4', () {
        final labels = samplePlan.grades.map((g) => g.gradeLabel).toList();
        expect(labels, contains('Grade 3'));
        expect(labels, contains('Grade 4'));
      });

      test('Phase 1 JSON without schemaVersion loads successfully', () {
        final jsonMap = samplePlan.toJson();
        jsonMap.remove('schemaVersion');
        final json = jsonEncode(jsonMap);
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final result = LessonPlan.fromJson(decoded);

        expect(result.header.school, equals(samplePlan.header.school));
        expect(result.grades.length, equals(samplePlan.grades.length));
        expect(result.flow.length, equals(samplePlan.flow.length));
      });

      test('JSON with schemaVersion > current throws PlanVersionException', () {
        final jsonMap = samplePlan.toJson();
        jsonMap['schemaVersion'] = 99;
        final json = jsonEncode(jsonMap);
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        expect(
          () => LessonPlan.fromJson(decoded),
          throwsA(isA<PlanVersionException>()),
        );
      });
    });

    group('ReflectionQuestion', () {
      test('supports null gradeLabel for whole-class questions', () {
        final question =
            ReflectionQuestion(gradeLabel: null, text: 'General question');
        expect(question.gradeLabel, isNull);
        expect(question.text, equals('General question'));
      });

      test('JSON round-trip with null gradeLabel', () {
        final question = ReflectionQuestion(gradeLabel: null, text: 'Test');
        final json = jsonEncode(question.toJson());
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final result = ReflectionQuestion.fromJson(decoded);

        expect(result.gradeLabel, isNull);
        expect(result.text, equals('Test'));
      });

      test('copyWith with clearGradeLabel sets gradeLabel to null', () {
        final question = ReflectionQuestion(
          gradeLabel: 'Grade 3',
          text: 'Test question',
        );
        final updated = question.copyWith(clearGradeLabel: true);

        expect(updated.gradeLabel, isNull);
        expect(updated.text, equals('Test question'));
      });

      test(
          'copyWith with gradeLabel and clearGradeLabel=false keeps new gradeLabel',
          () {
        final question = ReflectionQuestion(
          gradeLabel: 'Grade 3',
          text: 'Test question',
        );
        final updated = question.copyWith(
          gradeLabel: 'Grade 4',
          clearGradeLabel: false,
        );

        expect(updated.gradeLabel, equals('Grade 4'));
        expect(updated.text, equals('Test question'));
      });
    });

    group('PlanSection', () {
      test('eventName matches MockLessonGenerator section names', () {
        expect(PlanSection.header.eventName, equals(''));
        expect(PlanSection.intentions.eventName, equals('Intentions'));
        expect(PlanSection.learningExperiences.eventName,
            equals('Learning Experiences'));
        expect(PlanSection.assessment.eventName, equals('Assessment'));
        expect(PlanSection.waysForward.eventName, equals('Ways Forward'));
      });
    });
  });
}
