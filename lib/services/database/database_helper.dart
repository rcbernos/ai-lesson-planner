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
  }
}