import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'app_database.dart';

/// Singleton access helper for the Drift database.
/// Provides a single shared [AppDatabase] instance across the app.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  AppDatabase? _db;

  /// The shared [AppDatabase] instance.
  /// Created lazily on first access to avoid initialization ordering issues.
  AppDatabase get db {
    _db ??= AppDatabase();
    return _db!;
  }

  /// Closes the underlying database.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Deletes the database file.
  /// This is useful for resetting the app state or troubleshooting.
  /// Returns true if the file was deleted, false if it didn't exist.
  Future<bool> deleteDatabase() async {
    await close();
    try {
      final dbFolder = await getApplicationSupportDirectory();
      final file = File(p.join(dbFolder.path, 'ai_lesson_planner.db'));
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // If we can't delete the file, return false
      return false;
    }
  }

  /// Gets the path to the database file.
  Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationSupportDirectory();
    return p.join(dbFolder.path, 'ai_lesson_planner.db');
  }
}
