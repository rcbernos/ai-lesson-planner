// Widget smoke test for AI Lesson Planner
// Verifies that the app builds with NavigationRail shell
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_lesson_planner/main.dart';
import 'package:ai_lesson_planner/features/shell/app_shell.dart';

void main() {
  testWidgets('App displays NavigationRail on startup',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    // Verify that the AppShell with NavigationRail is displayed.
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    // Verify that the MaterialApp is properly configured.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify the center content shows default page (Library)
    expect(find.text('Library'), findsNWidgets(2));
  });

  testWidgets('NavigationRail has multiple destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    // Verify the NavigationRail widget exists.
    expect(find.byType(NavigationRail), findsOneWidget);

    // Verify Library, Assistant, Settings destination labels are present.
    expect(find.text('Library'), findsNWidgets(2));
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Generator is NOT in the NavigationRail anymore
    expect(find.text('Generator'), findsNothing);
  });
}
