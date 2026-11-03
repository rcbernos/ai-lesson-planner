/// Generation controller for managing lesson plan generation state.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/providers.dart';

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
      _handleEvent,
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

  void _handleEvent(GenerationEvent event) {
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

  /// Cancels any ongoing generation.
  void cancel() {
    final generator = _ref.read(lessonGeneratorProvider);
    generator.cancel();
    _cancelSubscription();
    state = const GenerationState();
  }

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
