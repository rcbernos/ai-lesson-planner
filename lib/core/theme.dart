/// App-wide theme configuration.
/// Provides light and dark themes using Material 3 with Noto Sans fonts.
library;

import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    scaffoldBackgroundColor: Colors.grey[100],
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}
