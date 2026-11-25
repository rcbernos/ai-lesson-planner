import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lesson_planner/features/debug/llm_debug_screen.dart';

void main() {
  group('LlmDebugScreen', () {
    testWidgets('renders without overflow at narrow screen (360x640)', (
      WidgetTester tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LlmDebugScreen())),
      );

      await tester.pumpAndSettle();

      // Should find all the key UI elements
      expect(find.text('LLM Debug'), findsOneWidget);
      expect(
        find.text('No model found. Import via file_picker.'),
        findsOneWidget,
      );
      expect(find.text('Filipino Test Prompt'), findsOneWidget);
      expect(find.text('Check Model'), findsOneWidget);
      expect(find.text('Download Model'), findsOneWidget);
      expect(find.text('Load Model'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);
    });

    testWidgets('renders without overflow at wide screen (1024x600)', (
      WidgetTester tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LlmDebugScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('LLM Debug'), findsOneWidget);
      expect(
        find.text('No model found. Import via file_picker.'),
        findsOneWidget,
      );
    });

    testWidgets('model status card shows correct state initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LlmDebugScreen())),
      );

      await tester.pumpAndSettle();

      // Initially should show "No model found. Import via file_picker."
      expect(
        find.text('No model found. Import via file_picker.'),
        findsOneWidget,
      );
      expect(find.byType(Card), findsAtLeast(1));
    });
  });
}
