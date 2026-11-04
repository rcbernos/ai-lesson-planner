/// Generation controller for managing lesson plan generation state.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/providers.dart';

/// Provider for the current output language during regeneration.
/// Defaults to Filipino; will be updated from settings in T2.17.
final currentLanguageProvider = Provider<OutputLanguage>((ref) {
  return OutputLanguage.filipino;
});

/// State for the generation process.
class GenerationState {
  const GenerationState({
    this.currentSection,
    this.isGenerating = false,
    this.errorMessage,
  });

  final String? currentSection;
  final bool isGenerating;
  final String? errorMessage;

  GenerationState copyWith({
    String? currentSection,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return GenerationState(
      currentSection: currentSection ?? this.currentSection,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Controller for managing the lesson plan generation process.
class GenerationController extends StateNotifier<GenerationState> {
  GenerationController(this._ref) : super(const GenerationState());

  final Ref _ref;
  StreamSubscription<GenerationEvent>? _subscription;

  /// Starts generation with the given request.
  void startGeneration(GenerationRequest request) {
    // Cancel any existing subscription
    _cancelSubscription();

    // Reset state
    state = const GenerationState(isGenerating: true);
    _ref.read(generatedPlanProvider.notifier).state = null;

    // Create a new generator instance for each generation
    final generator = _ref.read(lessonGeneratorProvider);

    // Start listening to the stream
    _subscription = generator.generate(request).listen(
      _handleFullGenerationEvent,
      onError: (error, stackTrace) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: 'Generation failed: $error',
        );
      },
      onDone: () {
        if (state.isGenerating && state.errorMessage == null) {
          // Stream completed without yielding a plan - unexpected
          state = state.copyWith(
            isGenerating: false,
            errorMessage: 'Generation did not complete.',
          );
        }
      },
    );
  }

  /// Handles events for full generation (sets generatedPlanProvider).
  void _handleFullGenerationEvent(GenerationEvent event) {
    if (event is SectionStarted) {
      state = state.copyWith(currentSection: event.name);
    } else if (event is SectionCompleted) {
      // Keep current section visible until completion
    } else if (event is GenerationCompleted) {
      state = state.copyWith(
        isGenerating: false,
        currentSection: null,
      );
      _ref.read(generatedPlanProvider.notifier).state = event.plan;
    } else if (event is GenerationFailed) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: event.message,
      );
    }
  }

  /// Regenerates a specific section of the current plan.
  /// Applies changes directly to the editor with undo capability.
  void regenerateSection(PlanSection section) {
    // Cancel any existing subscription
    _cancelSubscription();

    // Reset state
    state = const GenerationState(isGenerating: true);

    // Get current plan from editor
    final editorState = _ref.read(planEditorProvider);
    if (editorState == null) {
      state = const GenerationState(errorMessage: 'No plan loaded');
      return;
    }

    final plan = editorState.plan;
    final language = _ref.read(currentLanguageProvider);

    // Build request from the current plan
    final request = GenerationRequest.fromPlan(plan, language);

    // Get generator and start regeneration
    final generator = _ref.read(lessonGeneratorProvider);

    // Start listening to the stream
    _subscription = generator.generateSection(request, section, plan).listen(
      _handleRegenerationEvent,
      onError: (error, stackTrace) {
        state = state.copyWith(
          isGenerating: false,
          errorMessage: 'Generation failed: $error',
        );
      },
      onDone: () {
        if (state.isGenerating && state.errorMessage == null) {
          state = state.copyWith(
            isGenerating: false,
            errorMessage: 'Generation did not complete.',
          );
        }
      },
    );
  }

  /// Handles events for section regeneration (applies to editor).
  void _handleRegenerationEvent(GenerationEvent event) {
    if (event is SectionStarted) {
      state = state.copyWith(currentSection: event.name);
    } else if (event is SectionCompleted) {
      // Keep current section visible until completion
    } else if (event is GenerationCompleted) {
      state = state.copyWith(
        isGenerating: false,
        currentSection: null,
      );
      // Apply the regenerated plan to the editor with undo capability
      _ref.read(planEditorProvider.notifier).applyRegenerated(event.plan);
    } else if (event is GenerationFailed) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: event.message,
      );
    }
  }

  /// Cancels any ongoing generation.
  void cancel() {
    final generator = _ref.read(lessonGeneratorProvider);
    generator.cancel();
    _cancelSubscription();
    state = const GenerationState();
  }

  /// Cancels any ongoing generation subscription.
  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
}
