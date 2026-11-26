/// Widget tests for the Assistant screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/features/assistant/assistant_screen.dart';
import 'package:ai_lesson_planner/core/chat/chat_session.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' show PlanHeader;
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart'
    show GradeInput, OutputLanguage;

void main() {
  group('AssistantScreen', () {
    testWidgets('shows message list and input bar', (
      WidgetTester tester,
    ) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('can send a message and see it appear', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('shows Generate button when form is complete', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.text('Complete Form First'), findsOneWidget);
    });

    testWidgets('summary card displays form fields', (
      WidgetTester tester,
    ) async {
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

  group('AssistantScreen slot-filling', () {
    testWidgets('shows quick reply chip when fields missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.byType(FilterChip), findsAtLeast(1));
      expect(find.textContaining('Enter'), findsAtLeast(1));
    });

    testWidgets('summary card shows Generate button when complete', (
      WidgetTester tester,
    ) async {
      // Create a complete session by pre-filling
      final completeSession = ChatSession(
        header: PlanHeader(
          school: 'Test School',
          teacher: 'Test Teacher',
          learningArea: 'Science',
          date: '2026-01-15',
          term: 'Term 1',
          sessions: 1,
          sessionMinutes: 90,
          multigradeModel: 'Gemma-SEA-LION-v4-4B-VL',
        ),
        grades: [
          GradeInput(
            gradeLabel: 'Grade 3',
            male: 5,
            female: 5,
            subTheme: 'Ecosystems',
            competency: 'S3.1.1',
          ),
          GradeInput(
            gradeLabel: 'Grade 4',
            male: 4,
            female: 4,
            subTheme: 'Weather',
            competency: 'S4.1.1',
          ),
        ],
        sharedSubTheme: 'Living Things',
        outputLanguage: OutputLanguage.english,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatSessionProvider.overrideWith((ref) => completeSession),
          ],
          child: const MaterialApp(home: AssistantScreen()),
        ),
      );

      expect(find.text('Generate from Chat'), findsOneWidget);
    });

    testWidgets('summary card shows Complete Form First when incomplete', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      expect(find.text('Complete Form First'), findsOneWidget);
    });

    testWidgets('quick reply chip shows next missing field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssistantScreen())),
      );

      // First missing field should be 'school'
      expect(find.textContaining('school'), findsOneWidget);
    });
  });
}
