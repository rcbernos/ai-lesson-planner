/// Local LLM engine implementation using llamadart for on-device inference.
///
/// Runs models via llamadart's FFI bindings on the main isolate
/// (llamadart handles background execution internally).
library;

import 'dart:async';

import 'package:llamadart/llamadart.dart';

import 'llm_engine.dart';

/// Local LLM engine backed by llamadart's FFI bindings.
///
/// Loads GGUF models from a file path and streams token completions.
class LocalLlamaEngine implements LlmEngine {
  LocalLlamaEngine();

  LlamaEngine? _engine;
  final StreamController<EngineState> _stateController =
      StreamController<EngineState>.broadcast();

  @override
  Stream<EngineState> get state => _stateController.stream;

  @override
  EngineState get currentState => _currentState;
  EngineState _currentState = EngineState.unloaded;

  /// Subscription for the current generation, used for cancellation.
  StreamSubscription<LlamaCompletionChunk>? _currentSubscription;

  void _emitState(EngineState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> load(ModelSpec spec) async {
    _emitState(EngineState.loading);

    if (_engine != null) {
      await unload();
    }

    try {
      final modelSource = ModelSource.path(spec.path);
      final model = LlamaModel(modelSource);
      final modelParams = ModelParams(contextSize: spec.contextSize);

      _engine = await LlamaEngine.load(model, params: modelParams);
      _emitState(EngineState.ready);
    } catch (e, stack) {
      _emitState(EngineState.error);
      _engine = null;
      // Emit error through state stream
      _stateController.addError(
        EngineException('Failed to load model: $e'),
        stack,
      );
    }
  }

  @override
  Stream<String> complete(List<ChatMsg> messages, GenParams params) {
    if (_engine == null) {
      final errorController = StreamController<String>();
      scheduleMicrotask(() {
        if (!errorController.isClosed) {
          errorController.addError(
            EngineException('Engine not loaded. Call load() first.'),
          );
          errorController.close();
        }
      });
      return errorController.stream;
    }

    _emitState(EngineState.generating);

    final llamaMessages = messages
        .map(
          (msg) => LlamaChatMessage.fromText(
            role: _toLlamaRole(msg.role),
            text: msg.content,
          ),
        )
        .toList();

    // llamadart 0.21.0 uses 'temp' instead of 'temperature'
    // and 'stopSequences' instead of 'stop'
    final generationParams = GenerationParams(
      temp: params.temperature,
      maxTokens: params.maxTokens,
      stopSequences: params.stop,
      seed: params.seed,
    );

    final controller = StreamController<String>();
    late StreamSubscription<LlamaCompletionChunk> sub;

    sub = _engine!
        .create(llamaMessages, params: generationParams)
        .listen(
          (chunk) {
            if (!controller.isClosed) {
              controller.add(chunk.text);
            }
          },
          onError: (error, stackTrace) {
            _emitState(EngineState.error);
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
              controller.close();
            }
          },
          onDone: () {
            _emitState(EngineState.ready);
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );

    // Store subscription for cancellation tracking
    _currentSubscription = sub;

    return controller.stream;
  }

  LlamaChatRole _toLlamaRole(String role) {
    return switch (role) {
      'system' => LlamaChatRole.system,
      'user' => LlamaChatRole.user,
      'assistant' => LlamaChatRole.assistant,
      _ => LlamaChatRole.user,
    };
  }

  @override
  Future<void> cancel() {
    // Cancel the current subscription
    _currentSubscription?.cancel();
    // Cancel generation in the engine
    _engine?.cancelGeneration();
    _currentSubscription = null;
    _emitState(EngineState.ready);
    return Future.value();
  }

  @override
  Future<void> unload() async {
    if (_engine != null) {
      await _engine!.unloadModel();
      _engine = null;
    }
    _currentSubscription = null;
    _emitState(EngineState.unloaded);
  }

  @override
  Future<void> dispose() async {
    // Unload first (emits unloaded state if engine was loaded)
    await unload();
    // Then close the state controller
    await _stateController.close();
  }
}
