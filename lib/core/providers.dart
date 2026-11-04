/// Riverpod providers for the lesson plan generation pipeline.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/mock_lesson_generator.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/features/generator/generation_controller.dart';
import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';
import 'package:ai_lesson_planner/services/database/plan_repository.dart';

/// Provides the LessonGenerator implementation.
/// During development, returns MockLessonGenerator.
/// In production, will return the actual LLM-based generator.
final lessonGeneratorProvider = Provider<LessonGenerator>((ref) {
  return MockLessonGenerator();
});

/// Holds the currently generated lesson plan.
/// Null until a plan is generated.
final generatedPlanProvider = StateProvider<LessonPlan?>((ref) => null);

/// Provides the generation controller for managing the generation state.
final generationControllerProvider =
    StateNotifierProvider<GenerationController, GenerationState>((ref) {
  return GenerationController(ref);
});

/// Provides the PlanRepository for persisting lesson plans.
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

/// Provides the plan editor state with undo history.
/// Survives tab switches (no auto-dispose).
final planEditorProvider =
    StateNotifierProvider<PlanEditorNotifier, PlanEditorState?>(
  (ref) {
    ref.keepAlive();
    return PlanEditorNotifier();
  },
);
