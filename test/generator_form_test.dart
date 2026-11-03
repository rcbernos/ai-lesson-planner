/// Widget tests for the generator form.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lesson_planner/features/generator/generator_form_state.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';

void main() {
  group('GeneratorFormNotifier tests', () {
    late GeneratorFormNotifier notifier;

    setUp(() {
      notifier = GeneratorFormNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state has empty grades', () {
      expect(notifier.state.grades.length, equals(0));
    });

    test('canGenerate is false initially', () {
      expect(notifier.state.canGenerate, isFalse);
    });

    test('adding grades up to 6 works', () {
      expect(notifier.state.grades.length, equals(0));

      for (var i = 0; i < 6; i++) {
        notifier.addGrade(GradeInput(
          gradeLabel: 'Grade ${i + 2}',
          male: 10,
          female: 10,
          subTheme: 'Test Theme',
          competency: 'Test Competency',
        ));
      }

      expect(notifier.state.grades.length, equals(6));
    });

    test('cannot add grade beyond 6', () {
      for (var i = 0; i < 6; i++) {
        notifier.addGrade(GradeInput(
          gradeLabel: 'Grade ${i + 2}',
          male: 10,
          female: 10,
          subTheme: 'Test Theme',
          competency: 'Test Competency',
        ));
      }

      final initialLength = notifier.state.grades.length;
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 8',
        male: 10,
        female: 10,
        subTheme: 'Test',
        competency: 'Test',
      ));

      expect(notifier.state.grades.length, equals(initialLength));
    });

    test('removing grade below 2 is blocked', () {
      // Add 2 grades first
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 2',
        male: 10,
        female: 10,
        subTheme: 'Test',
        competency: 'Test',
      ));
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 3',
        male: 10,
        female: 10,
        subTheme: 'Test',
        competency: 'Test',
      ));

      expect(notifier.state.grades.length, equals(2));

      // Try to remove
      notifier.removeGrade(0);

      // Should still be 2
      expect(notifier.state.grades.length, equals(2));
    });

    test('removing grade when 3+ works', () {
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 2',
        male: 10,
        female: 10,
        subTheme: 'Test',
        competency: 'Test',
      ));
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 3',
        male: 10,
        female: 10,
        subTheme: 'Test',
        competency: 'Test',
      ));
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 4',
        male: 10,
        female: 10,
        subTheme: 'Test',
        competency: 'Test',
      ));

      expect(notifier.state.grades.length, equals(3));

      notifier.removeGrade(0);

      expect(notifier.state.grades.length, equals(2));
    });

    test('canGenerate becomes true when all fields filled', () {
      // Add 2 grades
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 2',
        male: 10,
        female: 10,
        subTheme: 'Math',
        competency: 'M5NS-Ia-1',
      ));
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 3',
        male: 10,
        female: 10,
        subTheme: 'Math',
        competency: 'M5NS-Ia-2',
      ));

      // Fill header fields
      notifier.updateSchool('Test Elementary');
      notifier.updateTeacher('Teacher Name');
      notifier.updateLearningArea('Mathematics');
      notifier.updateDate('2024-01-15');
      notifier.updateTerm('Term 1');
      notifier.updateSharedSubTheme('Numbers');

      // Can generate now
      expect(notifier.state.canGenerate, isTrue);
    });

    test('canGenerate is false when required fields missing', () {
      // Add 2 grades but no other fields
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 2',
        male: 10,
        female: 10,
        subTheme: 'Math',
        competency: '',
      ));
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 3',
        male: 10,
        female: 10,
        subTheme: 'Math',
        competency: 'Competency',
      ));

      // Missing required fields
      expect(notifier.state.canGenerate, isFalse);
    });

    test('buildGenerationRequest creates valid request', () {
      // Fill all fields
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 2',
        male: 10,
        female: 10,
        subTheme: 'Math',
        competency: 'M5NS-Ia-1',
      ));
      notifier.addGrade(GradeInput(
        gradeLabel: 'Grade 3',
        male: 15,
        female: 15,
        subTheme: 'Math',
        competency: 'M5NS-Ia-2',
      ));
      notifier.updateSchool('Test School');
      notifier.updateTeacher('Test Teacher');
      notifier.updateLearningArea('Mathematics');
      notifier.updateDate('2024-01-15');
      notifier.updateTerm('Term 1');
      notifier.updateSessions(2);
      notifier.updateSessionMinutes(60);
      notifier.updateSharedSubTheme('Numbers');
      notifier.updateMultigradeModel('STDT');
      notifier.updateOutputLanguage(OutputLanguage.filipino);

      final request = notifier.state.buildGenerationRequest();

      expect(request.header.school, equals('Test School'));
      expect(request.header.teacher, equals('Test Teacher'));
      expect(request.header.learningArea, equals('Mathematics'));
      expect(request.header.sessions, equals(2));
      expect(request.header.sessionMinutes, equals(60));
      expect(request.grades.length, equals(2));
      expect(request.sharedSubTheme, equals('Numbers'));
      expect(request.language, equals(OutputLanguage.filipino));
    });
  });
}
