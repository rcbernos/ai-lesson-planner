import 'dart:async';
import 'dart:io';

import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/llm/local_llama_engine.dart';
import 'package:test/test.dart';

void main() {
  group('LocalLlamaEngine', () {
    group('Lifecycle (unit tests)', () {
      test('initial state is unloaded', () {
        final engine = LocalLlamaEngine();
        expect(engine.currentState, equals(EngineState.unloaded));
        engine.dispose();
      });

      test('state stream emits correct sequence on load failure', () async {
        final engine = LocalLlamaEngine();
        final states = <EngineState>[];
        final subscription = engine.state.listen((s) => states.add(s));

        await expectLater(
          engine.load(
            ModelSpec(
              path: '/nonexistent/model.gguf',
              contextSize: 2048,
              threads: 4,
            ),
          ),
          throwsA(isA<EngineException>()),
        );

        await Future.microtask(() {});

        expect(states, containsAll([EngineState.loading, EngineState.error]));
        expect(engine.currentState, equals(EngineState.error));

        await subscription.cancel();
        await engine.dispose();
      });
    });

    group('Cancel behavior', () {
      test('cancel() on unloaded engine does not throw', () async {
        final engine = LocalLlamaEngine();
        await engine.cancel(); // Should not throw
        await engine.dispose();
      });

      test('unload() on engine not loaded does not throw', () async {
        final engine = LocalLlamaEngine();
        await engine.unload(); // Should not throw
        await engine.dispose();
      });
    });

    final modelPath = Platform.environment['LMS_TEST_GGUF'];
    group('Integration tests (gated by LMS_TEST_GGUF)', () {
      test(
        'load and stream tokens from real model',
        () async {
          expect(File(modelPath!).existsSync(), isTrue);
          final engine = LocalLlamaEngine();
          final states = <EngineState>[];
          final stateSub = engine.state.listen((s) => states.add(s));
          final ready = engine.state.firstWhere(
            (state) => state == EngineState.ready,
          );

          try {
            await engine.load(
              ModelSpec(path: modelPath, contextSize: 2048, threads: 4),
            );

            await ready.timeout(const Duration(seconds: 10));
            expect(states, contains(EngineState.loading));
            expect(states, contains(EngineState.ready));

            final messages = [ChatMsg(role: 'user', content: 'Hello')];

            final tokens = <String>[];
            final completer = Completer<void>();

            final sub = engine
                .complete(messages, GenParams(temperature: 0.3, maxTokens: 16))
                .listen(
                  (token) => tokens.add(token),
                  onDone: () => completer.complete(),
                );

            await completer.future.timeout(const Duration(seconds: 10));
            await sub.cancel();

            expect(tokens.length, greaterThan(0));
            expect(tokens.join(), isNotEmpty);

            await engine.unload();
            expect(engine.currentState, equals(EngineState.unloaded));
          } finally {
            await stateSub.cancel();
            await engine.dispose();
          }
        },
        skip: modelPath == null
            ? 'Requires LMS_TEST_GGUF environment variable'
            : false,
      );

      test(
        'cancel stops generation',
        () async {
          expect(File(modelPath!).existsSync(), isTrue);
          final engine = LocalLlamaEngine();

          try {
            await engine.load(
              ModelSpec(path: modelPath, contextSize: 2048, threads: 4),
            );

            final messages = [
              ChatMsg(role: 'user', content: 'Write a very long response'),
            ];

            final tokens = <String>[];
            final sub = engine
                .complete(
                  messages,
                  GenParams(temperature: 0.3, maxTokens: 1000),
                )
                .listen((token) => tokens.add(token));
            final done = sub.asFuture<void>();

            // Cancel after a short delay
            await Future.delayed(const Duration(milliseconds: 100));
            await engine.cancel();
            await done.timeout(const Duration(seconds: 10));

            // Generation should have terminated and returned to ready state
            expect(engine.currentState, equals(EngineState.ready));
          } finally {
            await engine.dispose();
          }
        },
        skip: modelPath == null
            ? 'Requires LMS_TEST_GGUF environment variable'
            : false,
      );
    });
  });
}
