import 'dart:async';

import 'package:test/test.dart';
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/llm/fake_engine.dart';

void main() {
  group('FakeEngine', () {
    group('Lifecycle', () {
      test('initial state is unloaded', () {
        final engine = FakeEngine();
        expect(engine.currentState, equals(EngineState.unloaded));
        engine.dispose();
      });

      test('state stream emits correct sequence on load', () async {
        final engine = FakeEngine();
        final states = <EngineState>[];
        final subscription = engine.state.listen((s) => states.add(s));

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        // Allow microtasks to complete for stream delivery
        await Future.microtask(() {});

        expect(states, equals([EngineState.loading, EngineState.ready]));
        expect(engine.currentState, equals(EngineState.ready));

        await subscription.cancel();
        await engine.dispose();
      });
    });

    group('Load failure', () {
      test('throws EngineException on empty path', () async {
        final failEngine = FakeEngine();

        expect(
          () => failEngine.load(
            ModelSpec(path: '', contextSize: 2048, threads: 4),
          ),
          throwsA(isA<EngineException>()),
        );

        await failEngine.dispose();
      });

      test('throws EngineException when failOnLoad is true', () async {
        final failEngine = FakeEngine(failOnLoad: true);

        expect(
          () => failEngine.load(
            ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
          ),
          throwsA(isA<EngineException>()),
        );

        await failEngine.dispose();
      });
    });

    group('Token streaming', () {
      test('tokens arrive in order', () async {
        final engine = FakeEngine(
          tokenSequences: {
            'user:Hello;': FakeTokenSequence(
              tokens: ['Hello', ' ', 'world', '!'],
            ),
          },
        );

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final messages = [ChatMsg(role: 'user', content: 'Hello')];

        final tokens = <String>[];
        final completer = Completer<void>();

        final subscription = engine
            .complete(messages, GenParams(temperature: 0.3, maxTokens: 100))
            .listen(
              (token) => tokens.add(token),
              onDone: () {
                completer.complete();
              },
            );

        await completer.future;
        await subscription.cancel();

        expect(tokens, equals(['Hello', ' ', 'world', '!']));

        await engine.dispose();
      });

      test('cancel() stops the stream', () async {
        final engine = FakeEngine(
          tokenSequences: {
            'user:Generate;': FakeTokenSequence(
              tokens: List.generate(100, (i) => 'token$i'),
              delayMs: 50,
            ),
          },
        );

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final messages = [ChatMsg(role: 'user', content: 'Generate')];

        final tokens = <String>[];
        final subscription = engine
            .complete(messages, GenParams(temperature: 0.3, maxTokens: 100))
            .listen((token) => tokens.add(token));

        await Future.delayed(const Duration(milliseconds: 150));
        await engine.cancel();

        expect(tokens.length, lessThan(100));

        await subscription.cancel();
        await engine.dispose();
      });

      test('returns error event when engine not loaded', () async {
        final engine = FakeEngine();

        final stream = engine.complete([
          ChatMsg(role: 'user', content: 'test'),
        ], GenParams(temperature: 0.3, maxTokens: 100));

        // The error is delivered asynchronously when not loaded
        final errors = <Object>[];
        final errorsComplete = Completer<void>();

        final sub = stream.listen(
          (token) {},
          onError: (e) {
            errors.add(e);
            if (errors.length == 1 && !errorsComplete.isCompleted) {
              errorsComplete.complete();
            }
          },
          onDone: () {
            if (!errorsComplete.isCompleted) {
              errorsComplete.complete();
            }
          },
        );

        // Wait for the error to be delivered
        await errorsComplete.future.timeout(const Duration(seconds: 1));

        expect(errors.length, equals(1));
        expect(errors.first, isA<EngineException>());

        await sub.cancel();
        await engine.dispose();
      });
    });

    group('Key computation', () {
      test('key is derived from messages', () async {
        final engine = FakeEngine(
          tokenSequences: {
            'user:Generate a plan for ;': FakeTokenSequence(tokens: ['done']),
          },
        );

        await engine.load(
          ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
        );

        final messages = [
          ChatMsg(role: 'user', content: 'Generate a plan for Grade 3'),
        ];

        final tokens = <String>[];
        final completer = Completer<void>();

        final subscription = engine
            .complete(messages, GenParams(temperature: 0.3, maxTokens: 100))
            .listen(
              (token) => tokens.add(token),
              onDone: () => completer.complete(),
            );

        await completer.future;
        await subscription.cancel();

        expect(tokens, equals(['done']));

        await engine.dispose();
      });
    });

    group('ModelSpec', () {
      test('copyWith creates new instance with updated values', () {
        final spec = ModelSpec(
          path: '/model.gguf',
          contextSize: 2048,
          threads: 4,
        );
        final updated = spec.copyWith(contextSize: 4096);

        expect(updated.path, equals('/model.gguf'));
        expect(updated.contextSize, equals(4096));
        expect(updated.threads, equals(4));
      });

      test('toJson and fromJson round-trip', () {
        final spec = ModelSpec(
          path: '/model.gguf',
          contextSize: 2048,
          threads: 4,
        );
        final json = spec.toJson();
        final parsed = ModelSpec.fromJson(json);

        expect(parsed.path, equals(spec.path));
        expect(parsed.contextSize, equals(spec.contextSize));
        expect(parsed.threads, equals(spec.threads));
      });
    });

    group('ChatMsg', () {
      test('toJson and fromJson round-trip', () {
        final msg = ChatMsg(role: 'user', content: 'Hello world');
        final json = msg.toJson();
        final parsed = ChatMsg.fromJson(json);

        expect(parsed.role, equals('user'));
        expect(parsed.content, equals('Hello world'));
      });
    });

    group('GenParams', () {
      test('toJson includes all fields', () {
        final params = GenParams(
          temperature: 0.7,
          maxTokens: 512,
          seed: 42,
          stop: ['STOP'],
        );

        final json = params.toJson();

        expect(json['temperature'], equals(0.7));
        expect(json['maxTokens'], equals(512));
        expect(json['seed'], equals(42));
        expect(json['stop'], equals(['STOP']));
      });

      test('toJson omits null values', () {
        final params = GenParams(temperature: 0.3, maxTokens: 100);

        final json = params.toJson();

        expect(json.containsKey('seed'), isFalse);
        expect(json.containsKey('jsonSchema'), isFalse);
        expect(json.containsKey('grammar'), isFalse);
      });
    });
  });
}
