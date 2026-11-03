// Widget smoke test for AI Lesson Planner
// Verifies that the app builds and displays the main title
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_lesson_planner/main.dart';

void main() {
  testWidgets('App displays title on startup', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app title is displayed.
    expect(find.text('AI Lesson Plan Assistant'), findsOneWidget);

    // Verify that the MaterialApp is properly configured.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
