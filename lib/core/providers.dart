/// Riverpod providers for the lesson plan generation pipeline.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/drafts/draft_store.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/llm_lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/mock_lesson_generator.dart';
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/llm/local_llama_engine.dart';
import 'package:ai_lesson_planner/core/llm/model_paths.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/features/generator/generation_controller.dart';
import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';
import 'package:ai_lesson_planner/services/database/plan_repository.dart';

/// State of the LLM backend availability.
enum LlmState {
  /// Model is available and loaded.
  available,

  /// No model file found or model too small.
  unavailable,

  /// Model is currently loading.
  loading,

  /// Model failed to load.
  error,
}

/// Provider for LLM backend state.
final llmStateProvider = FutureProvider<LlmState>((ref) async {
  final path = await ModelPaths.getExpectedModelPath();
  final file = File(path);

  if (!await file.exists()) {
    return LlmState.unavailable;
  }

  final size = await file.length();
  if (size < 100 * 1024 * 1024) {
    return LlmState.unavailable;
  }

  return LlmState.available;
});

/// Provides the LessonGenerator implementation.
/// Returns LocalLlamaEngine-backed LlmLessonGenerator when model is available,
/// falls back to MockLessonGenerator otherwise.
///
/// NOTE: This provider initializes asynchronously. Callers should use
/// ref.watch(lessonGeneratorProvider) or handle the async nature properly.
final lessonGeneratorProvider = FutureProvider<LessonGenerator>((ref) async {
  final path = await ModelPaths.getExpectedModelPath();
  final file = File(path);

  if (!await file.exists()) {
    return MockLessonGenerator();
  }

  final size = await file.length();
  if (size < 100 * 1024 * 1024) {
    return MockLessonGenerator();
  }

  try {
    final engine = LocalLlamaEngine();
    await engine.load(ModelSpec(path: path, contextSize: 2048, threads: 4));
    return LlmLessonGenerator(engine: engine, seed: 42);
  } catch (e) {
    // If model fails to load, fall back to mock
    return MockLessonGenerator();
  }
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

/// Provides the on-disk store for the unsaved plan draft
/// (`<app support dir>/drafts/current_draft.json`).
final draftStoreProvider = Provider<DraftStore>((ref) {
  return DraftStore.inSupportDir();
});

/// Provides the plan editor state with undo history.
/// Survives tab switches (no auto-dispose).
final planEditorProvider =
    StateNotifierProvider<PlanEditorNotifier, PlanEditorState?>((ref) {
      ref.keepAlive();
      return PlanEditorNotifier(drafts: ref.read(draftStoreProvider));
    });
