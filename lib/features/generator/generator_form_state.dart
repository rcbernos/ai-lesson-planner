/// Riverpod StateNotifier for the generator form state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// State for the generator form.
class GeneratorFormState {
  const GeneratorFormState({
    this.school = '',
    this.teacher = '',
    this.learningArea = '',
    this.date = '',
    this.term = '',
    this.sessions = 1,
    this.sessionMinutes = 90,
    this.sharedSubTheme = '',
    this.multigradeModel = 'STDT',
    this.outputLanguage = OutputLanguage.filipino,
    this.grades = const [],
  });

  final String school;
  final String teacher;
  final String learningArea;
  final String date;
  final String term;
  final int sessions;
  final int sessionMinutes;
  final String sharedSubTheme;
  final String multigradeModel;
  final OutputLanguage outputLanguage;
  final List<GradeInput> grades;

  GeneratorFormState copyWith({
    String? school,
    String? teacher,
    String? learningArea,
    String? date,
    String? term,
    int? sessions,
    int? sessionMinutes,
    String? sharedSubTheme,
    String? multigradeModel,
    OutputLanguage? outputLanguage,
    List<GradeInput>? grades,
  }) {
    return GeneratorFormState(
      school: school ?? this.school,
      teacher: teacher ?? this.teacher,
      learningArea: learningArea ?? this.learningArea,
      date: date ?? this.date,
      term: term ?? this.term,
      sessions: sessions ?? this.sessions,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      sharedSubTheme: sharedSubTheme ?? this.sharedSubTheme,
      multigradeModel: multigradeModel ?? this.multigradeModel,
      outputLanguage: outputLanguage ?? this.outputLanguage,
      grades: grades ?? this.grades,
    );
  }

  /// Returns true if the form has valid data and can be submitted.
  bool get canGenerate {
    if (school.isEmpty) return false;
    if (teacher.isEmpty) return false;
    if (learningArea.isEmpty) return false;
    if (date.isEmpty) return false;
    if (term.isEmpty) return false;
    if (sharedSubTheme.isEmpty) return false;
    if (sessionMinutes <= 0) return false;
    if (sessions <= 0) return false;
    if (grades.isEmpty) return false;

    // Check all grades have required fields
    for (final grade in grades) {
      if (grade.gradeLabel.isEmpty) return false;
      if (grade.subTheme.isEmpty) return false;
      if (grade.competency.isEmpty) return false;
    }

    return true;
  }

  /// Builds a GenerationRequest from the form state.
  GenerationRequest buildGenerationRequest() {
    final header = PlanHeader(
      school: school,
      teacher: teacher,
      learningArea: learningArea,
      date: date,
      term: term,
      sessions: sessions,
      sessionMinutes: sessionMinutes,
      multigradeModel: multigradeModel,
    );

    return GenerationRequest(
      header: header,
      grades: grades.toList(),
      sharedSubTheme: sharedSubTheme,
      language: outputLanguage,
    );
  }
}

/// StateNotifier for managing generator form state.
class GeneratorFormNotifier extends StateNotifier<GeneratorFormState> {
  GeneratorFormNotifier() : super(const GeneratorFormState());

  void updateSchool(String value) {
    state = state.copyWith(school: value);
  }

  void updateTeacher(String value) {
    state = state.copyWith(teacher: value);
  }

  void updateLearningArea(String value) {
    state = state.copyWith(learningArea: value);
  }

  void updateDate(String value) {
    state = state.copyWith(date: value);
  }

  void updateTerm(String value) {
    state = state.copyWith(term: value);
  }

  void updateSessions(int value) {
    state = state.copyWith(sessions: value);
  }

  void updateSessionMinutes(int value) {
    state = state.copyWith(sessionMinutes: value);
  }

  void updateSharedSubTheme(String value) {
    state = state.copyWith(sharedSubTheme: value);
  }

  void updateMultigradeModel(String value) {
    state = state.copyWith(multigradeModel: value);
  }

  void updateOutputLanguage(OutputLanguage value) {
    state = state.copyWith(outputLanguage: value);
  }

  void addGrade(GradeInput grade) {
    if (state.grades.length >= 12) return;
    state = state.copyWith(grades: [...state.grades, grade]);
  }

  void removeGrade(int index) {
    if (state.grades.length <= 1) return;  // Block removal below 1 grade - allows monograde plans
    final newGrades = [...state.grades];
    newGrades.removeAt(index);
    state = state.copyWith(grades: newGrades);
  }

  void updateGrade(int index, GradeInput updatedGrade) {
    final newGrades = [...state.grades];
    newGrades[index] = updatedGrade;
    state = state.copyWith(grades: newGrades);
  }

  void reset() {
    state = const GeneratorFormState();
  }
}

/// Provider for the generator form state.
final generatorFormProvider =
    StateNotifierProvider<GeneratorFormNotifier, GeneratorFormState>((ref) {
  return GeneratorFormNotifier();
});
