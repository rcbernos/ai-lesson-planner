/// Widget tests for the adaptive AppShell navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_lesson_planner/features/shell/app_shell.dart';

void main() {
  group('AppShell adaptive navigation', () {
    testWidgets('shows NavigationBar on narrow screens (360x640)',
        (WidgetTester tester) async {
      // Set the test window size
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Should find NavigationBar, not NavigationRail
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Should show destination labels in the navigation
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows NavigationRail on wide screens (1024x600)',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Should find NavigationRail, not NavigationBar
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Should show destination labels in the navigation
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping NavigationBar destinations changes view (narrow)',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Tap Assistant label in NavigationBar
      await tester.tap(find.text('Assistant'));
      await tester.pump(const Duration(milliseconds: 100));

      // Should show Assistant AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('tapping NavigationRail destinations changes view (wide)',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Tap Assistant in NavigationRail
      await tester.tap(find.text('Assistant'));
      await tester.pump(const Duration(milliseconds: 100));

      // Should show Assistant AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('uses correct navigation for boundary width (599dp)',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(599, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Should find NavigationBar for narrow screen
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('uses correct navigation for boundary width (600dp)',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(600, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Should find NavigationRail for wide screen (>= 600dp)
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('NavigationRail has correct destinations in order',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 600);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      // Find NavigationRail destinations
      final rail = find.byType(NavigationRail);
      expect(rail, findsOneWidget);

      // Verify all three destinations are present
      expect(find.text('Library'),
          findsAtLeast(2)); // NavigationRail label + AppBar
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
