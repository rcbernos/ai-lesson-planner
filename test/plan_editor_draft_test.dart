import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/core/drafts/draft_store.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/features/plan_editor/plan_editor_state.dart';

import 'fixtures/sample_plan.dart';

class _FakeStore extends DraftStore {
  _FakeStore() : super(() async => Directory.systemTemp);

  final List<int?> writes = [];
  int clears = 0;

  @override
  Future<void> write(LessonPlan plan, {int? savedId}) async =>
      writes.add(savedId);

  @override
  Future<void> clear() async => clears++;
}

Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  late _FakeStore store;
  late PlanEditorNotifier notifier;

  setUp(() {
    store = _FakeStore();
    notifier = PlanEditorNotifier(
      drafts: store,
      draftDelay: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => notifier.dispose());

  test('an edit to a saved plan writes a draft after the delay', () async {
    notifier.load(createSamplePlan(), savedId: 3);
    store.clears = 0;

    notifier.update((p) => p.copyWith(learnerContext: 'edited'));
    expect(store.writes, isEmpty); // debounced
    await _wait();

    expect(store.writes, [3]);
  });

  test('a freshly generated, never-saved plan gets a draft', () async {
    notifier.load(createSamplePlan());
    await _wait();

    expect(store.writes, [null]);
  });

  test('markSaved clears the draft and stops writing', () async {
    notifier.load(createSamplePlan());
    notifier.markSaved(5);
    await _wait();

    expect(store.writes, isEmpty);
    expect(store.clears, greaterThan(0));
  });

  test('loading a clean saved plan writes nothing', () async {
    notifier.load(createSamplePlan(), savedId: 9);
    await _wait();

    expect(store.writes, isEmpty);
  });

  test('flushDraft writes immediately', () async {
    notifier.load(createSamplePlan(), savedId: 3);
    notifier.update((p) => p.copyWith(learnerContext: 'edited'));
    await notifier.flushDraft();

    expect(store.writes, [3]);
  });

  test('restoring with dirty: true marks the plan unsaved', () {
    notifier.load(createSamplePlan(), savedId: 3, dirty: true);

    expect(notifier.state!.dirty, isTrue);
    expect(notifier.state!.savedId, 3);
  });

  test('a notifier without a store behaves as before', () {
    final plain = PlanEditorNotifier();
    plain.load(createSamplePlan());
    plain.update((p) => p.copyWith(learnerContext: 'x'));

    expect(plain.state!.dirty, isTrue);
    plain.dispose();
  });
}
