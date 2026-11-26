/// Fake LLM engine for testing and development.
/// Plays back scripted token sequences with simulated delays.
library;

import 'dart:async';
import 'dart:math';

import 'llm_engine.dart';

/// A fake token sequence for testing.
class FakeTokenSequence {
  FakeTokenSequence({required this.tokens, this.delayMs = 10});
  final List<String> tokens;
  final int delayMs;
}

/// Fake engine that replays scripted token sequences.
/// Supports cancellable streaming and failure injection for testing.
class FakeEngine implements LlmEngine {
  FakeEngine({
    this.tokenSequences = const {},
    this.failOnLoad = false,
    this.useFullKey = false,
  });

  /// Token sequences keyed by a hash of the messages.
  final Map<String, FakeTokenSequence> tokenSequences;

  /// If true, load() throws an exception.
  final bool failOnLoad;

  /// If true, use full message content as key (for testing).
  final bool useFullKey;

  final StreamController<EngineState> _stateController =
      StreamController<EngineState>.broadcast();
  EngineState _currentState = EngineState.unloaded;
  bool _isCancelled = false;

  @override
  Stream<EngineState> get state => _stateController.stream;

  @override
  EngineState get currentState => _currentState;

  void _emitState(EngineState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> load(ModelSpec spec) async {
    _emitState(EngineState.loading);

    if (failOnLoad) {
      _emitState(EngineState.error);
      throw EngineException('Simulated load failure for testing');
    }

    // Validate the model spec
    if (spec.path.isEmpty) {
      _emitState(EngineState.error);
      throw EngineException('Model path cannot be empty');
    }

    await Future.delayed(const Duration(milliseconds: 10));
    _emitState(EngineState.ready);
  }

  @override
  Stream<String> complete(List<ChatMsg> messages, GenParams params) {
    if (_currentState != EngineState.ready) {
      // Return a stream that immediately error
      final errorController = StreamController<String>();
      scheduleMicrotask(() {
        if (!errorController.isClosed) {
          errorController.addError(EngineException('Engine not loaded'));
          errorController.close();
        }
      });
      return errorController.stream;
    }

    _isCancelled = false;
    _emitState(EngineState.generating);

    return _generateTokens(messages);
  }

  Stream<String> _generateTokens(List<ChatMsg> messages) async* {
    final key = _computeKey(messages);
    final sequence = tokenSequences[key];

    if (sequence == null) {
      _emitState(EngineState.error);
      throw EngineException('No token sequence found for key: $key');
    }

    try {
      for (final token in sequence.tokens) {
        if (_isCancelled) {
          return;
        }
        await Future.delayed(Duration(milliseconds: sequence.delayMs));
        yield token;
      }
    } finally {
      if (!_isCancelled) {
        _emitState(EngineState.ready);
      }
    }
  }

  @override
  Future<void> cancel() async {
    _isCancelled = true;
    _emitState(EngineState.ready);
  }

  @override
  Future<void> unload() async {
    _isCancelled = false;
    _emitState(EngineState.unloaded);
  }

  /// Computes a simple key from the messages for sequence lookup.
  String _computeKey(List<ChatMsg> messages) {
    if (useFullKey) {
      final buffer = StringBuffer();
      for (final msg in messages) {
        buffer.write('${msg.role}:${msg.content};');
      }
      return buffer.toString();
    }
    final buffer = StringBuffer();
    for (final msg in messages) {
      buffer.write(
        '${msg.role}:${msg.content.substring(0, min(20, msg.content.length))};',
      );
    }
    return buffer.toString();
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }
}

/// Extension for easy copyWith on ModelSpec.
extension ModelSpecCopyWith on ModelSpec {
  ModelSpec copyWith({String? path, int? contextSize, int? threads}) =>
      ModelSpec(
        path: path ?? this.path,
        contextSize: contextSize ?? this.contextSize,
        threads: threads ?? this.threads,
      );
}
