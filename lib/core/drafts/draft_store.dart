/// Crash-safe storage for one unsaved plan draft.
///
/// File: lib/core/drafts/draft_store.dart
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// A plan recovered from disk.
class PlanDraft {
  const PlanDraft({
    required this.plan,
    required this.savedId,
    required this.savedAt,
  });

  final LessonPlan plan;

  /// Database row the draft was editing, or null for a never-saved plan.
  final int? savedId;
  final DateTime savedAt;
}

/// Stores a single draft as `current_draft.json`.
///
/// Writes go to a temp file and are renamed into place, so a process kill in
/// the middle of a write leaves the previous draft intact. All operations run
/// one after another, so a late write can never undo a clear().
class DraftStore {
  DraftStore(this._resolveDir);

  /// The real store: `<app support dir>/drafts`. App-private on Android.
  factory DraftStore.inSupportDir() => DraftStore(() async {
        final base = await getApplicationSupportDirectory();
        return Directory(p.join(base.path, 'drafts'));
      });

  static const String _fileName = 'current_draft.json';

  final Future<Directory> Function() _resolveDir;
  Future<void> _chain = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() op) {
    final result = _chain.then((_) => op());
    _chain = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<File> _file() async {
    final dir = await _resolveDir();
    return File(p.join(dir.path, _fileName));
  }

  Future<void> write(LessonPlan plan, {int? savedId}) => _enqueue(() async {
        final file = await _file();
        await file.parent.create(recursive: true);
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(
          jsonEncode({
            'savedId': savedId,
            'savedAt': DateTime.now().toUtc().toIso8601String(),
            'plan': plan.toJson(),
          }),
          flush: true,
        );
        await tmp.rename(file.path);
      });

  /// Returns the draft, or null if there is none or it cannot be read.
  /// An unreadable draft is deleted so it does not block the next launch.
  Future<PlanDraft?> read() => _enqueue(() async {
        final file = await _file();
        if (!await file.exists()) return null;
        try {
          final map =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          return PlanDraft(
            plan: LessonPlan.fromJson(map['plan'] as Map<String, dynamic>),
            savedId: map['savedId'] as int?,
            savedAt: DateTime.parse(map['savedAt'] as String),
          );
        } catch (_) {
          await _deleteQuietly(file);
          return null;
        }
      });

  Future<void> clear() => _enqueue(() async {
        final file = await _file();
        await _deleteQuietly(file);
        await _deleteQuietly(File('${file.path}.tmp'));
      });

  Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Nothing useful to do; a stale draft is harmless.
    }
  }
}
