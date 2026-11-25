/// LLM Engine interface for on-device inference.
/// Pure Dart interface with no Flutter dependencies.
library;

/// Domain model for conversation messages sent to the LLM.
class ChatMsg {
  ChatMsg({required this.role, required this.content});

  final String role; // 'system' | 'user' | 'assistant'
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
  factory ChatMsg.fromJson(Map<String, dynamic> json) =>
      ChatMsg(role: json['role'] as String, content: json['content'] as String);
}

/// Generation parameters for the LLM.
class GenParams {
  GenParams({
    required this.temperature,
    required this.maxTokens,
    this.seed,
    this.jsonSchema,
    this.grammar,
    this.stop = const [],
  });

  final double temperature;
  final int maxTokens;
  final int? seed;
  final String? jsonSchema;
  final String? grammar;
  final List<String> stop;

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'maxTokens': maxTokens,
    if (seed != null) 'seed': seed,
    if (jsonSchema != null) 'jsonSchema': jsonSchema,
    if (grammar != null) 'grammar': grammar,
    'stop': stop,
  };
}

/// Model specification for loading a GGUF model.
class ModelSpec {
  ModelSpec({
    required this.path,
    required this.contextSize,
    required this.threads,
  });

  final String path;
  final int contextSize;
  final int threads;

  Map<String, dynamic> toJson() => {
    'path': path,
    'contextSize': contextSize,
    'threads': threads,
  };
  factory ModelSpec.fromJson(Map<String, dynamic> json) => ModelSpec(
    path: json['path'] as String,
    contextSize: json['contextSize'] as int,
    threads: json['threads'] as int,
  );
}

/// Engine state for reactive UI updates.
enum EngineState { unloaded, loading, ready, generating, error }

/// Exception thrown when engine operations fail.
class EngineException implements Exception {
  EngineException(this.message);
  final String message;
  @override
  String toString() => 'EngineException: $message';
}

/// Abstract interface for LLM engines.
/// Implementations run inference in a background isolate for responsiveness.
abstract class LlmEngine {
  /// Stream of state changes for UI binding.
  Stream<EngineState> get state;

  /// Returns the current engine state.
  EngineState get currentState;

  /// Loads a model file with the given specification.
  /// Throws [EngineException] if loading fails.
  Future<void> load(ModelSpec spec);

  /// Streams token deltas from the model completing the conversation.
  /// Uses the chat format expected by the underlying model.
  Stream<String> complete(List<ChatMsg> messages, GenParams params);

  /// Cancels any ongoing generation within ~1 second.
  Future<void> cancel();

  /// Unloads the model and frees native memory.
  Future<void> unload();

  /// Closes resources and releases any held streams.
  Future<void> dispose();
}
