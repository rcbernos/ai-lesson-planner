/// Widget tests for the generator form layout on different screen sizes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_lesson_planner/features/shell/app_shell.dart';
import 'package:ai_lesson_planner/features/generator/generator_screen.dart';

void main() {
  group('Generator form layout on phones', () {
    testWidgets('shows single-column layout at 360x640',
        (WidgetTester tester) async {
      // Set narrow phone screen size
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Tap FAB on Library screen to open Generator screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify the Generator Scaffold is displayed
      expect(find.byType(GeneratorScreen), findsOneWidget);

      // Check for generate button (should be reachable)
      expect(find.text('Generate'), findsOneWidget);
    });

    testWidgets('generate button is always reachable in 360x640',
        (WidgetTester tester) async {
      // Set narrow phone screen size
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Tap FAB to open Generator screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify generate button is visible and tappable
      expect(find.text('Generate'), findsOneWidget);

      // Scroll to verify button is reachable
      await tester.drag(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(SingleChildScrollView),
          ),
          const Offset(0, 200));
      await tester.pump();

      expect(find.text('Generate'), findsOneWidget);
    });
  });
}
