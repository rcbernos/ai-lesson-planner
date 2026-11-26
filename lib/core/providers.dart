/// Riverpod providers for the lesson plan generation pipeline.
library;

import 'dart:async';
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
import 'package:ai_lesson_planner/core/chat/slot_filler.dart' as slot_filler;
import 'package:ai_lesson_planner/features/generator/generation_controller.dart';
import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';
import 'package:ai_lesson_planner/services/database/plan_repository.dart';
import 'package:ai_lesson_planner/services/database/chat_repository.dart';
import 'package:ai_lesson_planner/core/llm/fake_engine.dart';

/// Provider for the LLM engine (uses FakeEngine in tests/dev).
/// Returns a loaded engine ready for use. Falls back to unloaded state if model unavailable.
final llmEngineProvider = FutureProvider<LlmEngine>((ref) async {
  // In tests, FakeEngine is injected via override
  // In development, use FakeEngine with token sequences
  // In production, this will use LocalLlamaEngine

  // Check if a model file exists and is valid
  final path = await ModelPaths.getExpectedModelPath();
  final file = File(path);

  if (await file.exists()) {
    final size = await file.length();
    if (size >= 100 * 1024 * 1024) {
      // Model file exists and is valid, use LocalLlamaEngine
      final engine = LocalLlamaEngine();
      await engine.load(ModelSpec(path: path, contextSize: 2048, threads: 4));
      return engine;
    }
  }

  // No valid model file, return FakeEngine for testing/development
  // Must load the FakeEngine before returning or it will error on use
  final fakeEngine = FakeEngine(tokenSequences: {});
  await fakeEngine.load(
    ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
  );
  return fakeEngine;
});

/// Provider for the SlotFiller used in chat mode.
/// Handles async engine initialization automatically.
final slotFillerProvider = Provider<slot_filler.SlotFiller>((ref) {
  final engineAsync = ref.watch(llmEngineProvider);

  // Return a SlotFiller with the engine (even if loading/error state)
  // The engine will be ready or will error during complete()
  final engine = engineAsync.hasValue && engineAsync.value != null
      ? engineAsync.value!
      : _UnloadedLlmEngine();

  return slot_filler.SlotFiller(
    engine: engine,
    temperature: 0.3,
    maxTokens: 512,
    seed: 42,
  );
});

/// Placeholder engine that returns errors for unloaded state.
class _UnloadedLlmEngine implements LlmEngine {
  @override
  Stream<EngineState> get state => Stream.value(EngineState.unloaded);

  @override
  EngineState get currentState => EngineState.unloaded;

  @override
  Future<void> load(ModelSpec spec) async {
    // No-op for placeholder
  }

  @override
  Stream<String> complete(List<ChatMsg> messages, GenParams params) {
    final controller = StreamController<String>();
    scheduleMicrotask(() {
      controller.addError(
        EngineException('Engine not loaded. Model file not found.'),
      );
      controller.close();
    });
    return controller.stream;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> unload() async {}

  @override
  Future<void> dispose() async {}
}

/// Provider for ChatRepository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

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
