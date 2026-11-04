/// Generation layer for lesson plan creation.
/// Defines the interface and data structures for the generation pipeline.
library;

import 'dart:async';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// Output language for generated lesson plans.
enum OutputLanguage { filipino, english }

/// Input for a single grade level in a generation request.
class GradeInput {
  GradeInput({
    required this.gradeLabel,
    required this.male,
    required this.female,
    required this.subTheme,
    required this.competency,
  });

  final String gradeLabel;
  final int male;
  final int female;
  final String subTheme;
  final String competency;
}

/// Request object for lesson plan generation.
class GenerationRequest {
  GenerationRequest({
    required this.header,
    required this.grades,
    required this.sharedSubTheme,
    required this.language,
  });

  final PlanHeader header;
  final List<GradeInput> grades;
  final String sharedSubTheme;
  final OutputLanguage language;

  /// Builds a request from an existing lesson plan.
  /// Competencies are joined with '; ' for each grade.
  factory GenerationRequest.fromPlan(
          LessonPlan plan, OutputLanguage language) =>
      GenerationRequest(
        header: plan.header,
        grades: plan.grades
            .map((g) => GradeInput(
                  gradeLabel: g.gradeLabel,
                  male: g.learnersMale,
                  female: g.learnersFemale,
                  subTheme: g.subTheme,
                  competency: g.competencies.join('; '),
                ))
            .toList(),
        sharedSubTheme: plan.sharedSubTheme,
        language: language,
      );
}

/// Base class for generation events in the streaming pipeline.
sealed class GenerationEvent {}

/// Emitted when a new section of the plan begins generation.
class SectionStarted extends GenerationEvent {
  SectionStarted(this.name);
  final String name;
}

/// Emitted with incremental text during token streaming.
class TokenDelta extends GenerationEvent {
  TokenDelta(this.text);
  final String text;
}

/// Emitted when a section completes generation.
class SectionCompleted extends GenerationEvent {
  SectionCompleted(this.name);
  final String name;
}

/// Emitted when generation completes with a full lesson plan.
class GenerationCompleted extends GenerationEvent {
  GenerationCompleted(this.plan);
  final LessonPlan plan;
}

/// Emitted when generation fails with an error message.
class GenerationFailed extends GenerationEvent {
  GenerationFailed(this.message);
  final String message;
}

/// Abstract interface for lesson plan generators.
/// Implementations can use LLMs, templates, or other sources.
abstract class LessonGenerator {
  /// Generates a lesson plan from the request.
  /// Emits [GenerationEvent] objects as the plan is built.
  Stream<GenerationEvent> generate(GenerationRequest request);

  /// Generates a single section of a lesson plan.
  /// Emits [GenerationEvent] objects as the section is built.
  /// The result is the current plan with the section replaced by the freshly generated content.
  Stream<GenerationEvent> generateSection(
    GenerationRequest request,
    PlanSection section,
    LessonPlan current, {
    String? gradeLabel,
  });

  /// Cancels any ongoing generation.
  void cancel();
}
