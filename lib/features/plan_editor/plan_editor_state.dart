import 'dart:async';

import 'package:ai_lesson_planner/core/drafts/draft_store.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/validation/plan_validator.dart';
import 'package:ai_lesson_planner/core/validation/validation_issue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the plan editor.
class PlanEditorState {
  const PlanEditorState({
    required this.plan,
    required this.issues,
    required this.dirty,
    required this.savedId,
    required this.canUndo,
  });

  final LessonPlan plan;
  final List<ValidationIssue> issues;
  final bool dirty;
  final int? savedId;
  final bool canUndo;
}

/// State notifier for managing plan editor state with undo history.
///
/// When a [DraftStore] is given, the plan is also written to disk (debounced)
/// whenever it has unsaved edits or was never saved, so an Android process
/// kill does not lose it. The draft is removed once the plan is saved.
class PlanEditorNotifier extends StateNotifier<PlanEditorState?> {
  PlanEditorNotifier({
    DraftStore? drafts,
    Duration draftDelay = const Duration(seconds: 2),
  })  : _drafts = drafts,
        _draftDelay = draftDelay,
        super(null);

  static const int _maxHistory = 20;
  final List<PlanEditorState> _history = [];
  final PlanValidator _validator = PlanValidator();

  final DraftStore? _drafts;
  final Duration _draftDelay;
  Timer? _draftTimer;

  /// Loads a plan. Pass `dirty: true` when restoring a recovered draft, so the
  /// "Unsaved changes" chip shows and the draft keeps being kept up to date.
  void load(LessonPlan plan, {int? savedId, bool dirty = false}) {
    final initialState = PlanEditorState(
      plan: plan,
      issues: dirty ? _validator.validate(plan) : const [],
      dirty: dirty,
      savedId: savedId,
      canUndo: false,
    );
    _history.clear();
    _emit(initialState);
  }

  void update(LessonPlan Function(LessonPlan) change) {
    final current = state;
    if (current == null) return;

    final newPlan = change(current.plan);
    final newIssues = _validator.validate(newPlan);

    // Push current state to history if it's different
    if (!_isStateEqual(current.plan, newPlan) ||
        !_listEqual(current.issues, newIssues)) {
      if (_history.length >= _maxHistory) {
        _history.removeAt(0);
      }
      _history.add(current);
    }

    _emit(PlanEditorState(
      plan: newPlan,
      issues: newIssues,
      dirty: true,
      savedId: current.savedId,
      canUndo: _history.isNotEmpty,
    ));
  }

  void applyRegenerated(LessonPlan plan) {
    final current = state;
    if (current == null) return;

    final newIssues = _validator.validate(plan);

    // Push current state to history (one undo step)
    if (_history.length >= _maxHistory) {
      _history.removeAt(0);
    }
    _history.add(current);

    _emit(PlanEditorState(
      plan: plan,
      issues: newIssues,
      dirty: true,
      savedId: current.savedId,
      canUndo: _history.isNotEmpty,
    ));
  }

  void undo() {
    final current = state;
    if (current == null || _history.isEmpty) return;

    final previous = _history.removeLast();
    _emit(PlanEditorState(
      plan: previous.plan,
      issues: previous.issues,
      dirty: previous.dirty,
      savedId: previous.savedId,
      canUndo: _history.isNotEmpty,
    ));
  }

  void markSaved(int id) {
    final current = state;
    if (current == null) return;

    _emit(PlanEditorState(
      plan: current.plan,
      issues: current.issues,
      dirty: false,
      savedId: id,
      canUndo: current.canUndo,
    ));
  }

  void clear() {
    _history.clear();
    _emit(null);
  }

  /// Writes the draft now (called when the app goes to the background, because
  /// the debounce timer may never fire before Android kills the process).
  Future<void> flushDraft() async {
    _draftTimer?.cancel();
    _draftTimer = null;
    final store = _drafts;
    final s = state;
    if (store == null || s == null || !_needsDraft(s)) return;
    try {
      await store.write(s.plan, savedId: s.savedId);
    } catch (_) {
      // A failed draft write must never break editing.
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    super.dispose();
  }

  // A plan needs a draft when it has unsaved edits, or has never been saved
  // (for example a plan that just finished generating).
  bool _needsDraft(PlanEditorState s) => s.dirty || s.savedId == null;

  void _emit(PlanEditorState? next) {
    state = next;
    _syncDraft(next);
  }

  void _syncDraft(PlanEditorState? s) {
    final store = _drafts;
    if (store == null) return;
    _draftTimer?.cancel();
    _draftTimer = null;

    if (s == null || !_needsDraft(s)) {
      unawaited(store.clear().catchError((Object _) {}));
      return;
    }
    _draftTimer = Timer(_draftDelay, () => unawaited(flushDraft()));
  }

  bool _isStateEqual(LessonPlan a, LessonPlan b) {
    return a == b;
  }

  bool _listEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
