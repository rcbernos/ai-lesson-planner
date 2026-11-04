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
class PlanEditorNotifier extends StateNotifier<PlanEditorState?> {
  PlanEditorNotifier() : super(null);

  static const int _maxHistory = 20;
  final List<PlanEditorState> _history = [];
  final PlanValidator _validator = PlanValidator();

  void load(LessonPlan plan, {int? savedId}) {
    final initialState = PlanEditorState(
      plan: plan,
      issues: const [],
      dirty: false,
      savedId: savedId,
      canUndo: false,
    );
    _history.clear();
    state = initialState;
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

    state = PlanEditorState(
      plan: newPlan,
      issues: newIssues,
      dirty: true,
      savedId: current.savedId,
      canUndo: _history.isNotEmpty,
    );
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

    state = PlanEditorState(
      plan: plan,
      issues: newIssues,
      dirty: true,
      savedId: current.savedId,
      canUndo: _history.isNotEmpty,
    );
  }

  void undo() {
    final current = state;
    if (current == null || _history.isEmpty) return;

    final previous = _history.removeLast();
    state = PlanEditorState(
      plan: previous.plan,
      issues: previous.issues,
      dirty: previous.dirty,
      savedId: previous.savedId,
      canUndo: _history.isNotEmpty,
    );
  }

  void markSaved(int id) {
    final current = state;
    if (current == null) return;

    state = PlanEditorState(
      plan: current.plan,
      issues: current.issues,
      dirty: false,
      savedId: id,
      canUndo: current.canUndo,
    );
  }

  void clear() {
    _history.clear();
    state = null;
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
