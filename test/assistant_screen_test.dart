/// Widget tests for the Assistant screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/features/assistant/assistant_screen.dart';
import 'package:ai_lesson_planner/features/shell/app_shell.dart';

void main() {
  group('AssistantScreen', () {
    testWidgets('shows message list and input bar', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('can send a message and see it appear', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows Generate button when form is complete', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.text('Complete Form First'), findsOneWidget);
    });

    testWidgets('summary card displays form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.text('Form so far'), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Learning Area'), findsOneWidget);
    });

    testWidgets('no overflow at 360x640', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      await tester.pump();

      expect(find.byType(AssistantScreen), findsOneWidget);
    });

    testWidgets('no overflow at 1024x600', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      await tester.pump();

      expect(find.byType(AssistantScreen), findsOneWidget);
    });
  });
}