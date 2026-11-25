/// Helper class for managing llamadart engine lifecycle.
///
/// This file provides a clean wrapper around the llama.cpp FFI bindings.
/// For the prototype, it provides a simple helper class.
/// If UI jank occurs during generation, this can be upgraded to use Dart isolates.
library;

import 'package:llamadart/llamadart.dart';

/// A helper that encapsulates the llamadart engine session.
///
/// This class is designed to be a future-proof location for isolate
/// management if needed. For the prototype, it provides a clean
/// separation between engine state and LlamaEngine operations.
class LlamaEngineWrapper {
  LlamaEngineWrapper();

  LlamaEngine? _engine;
  ChatSession? _session;

  /// Returns the underlying engine, or null if not loaded.
  LlamaEngine? get engine => _engine;

  /// Returns the current session, or null if not loaded.
  ChatSession? get session => _session;

  /// Loads a model with the given parameters.
  Future<void> loadModel(String path, {int contextSize = 2048}) async {
    final modelSource = ModelSource.path(path);
    final model = LlamaModel(modelSource);
    final modelParams = ModelParams(contextSize: contextSize);

    _engine = await LlamaEngine.load(model, params: modelParams);
    _session = ChatSession(_engine!);
  }

  /// Unloads the current model and frees resources.
  Future<void> unload() async {
    if (_engine != null) {
      await _engine!.unloadModel();
      _engine = null;
    }
    _session = null;
  }

  /// Checks if a model is currently loaded.
  bool get isLoaded => _engine != null;
}
