import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/core/drafts/draft_store.dart';

import 'fixtures/sample_plan.dart';

void main() {
  late Directory dir;
  late DraftStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('draft_store_test');
    store = DraftStore(() async => dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('read returns null when no draft exists', () async {
    expect(await store.read(), isNull);
  });

  test('write then read round-trips the plan and savedId', () async {
    final plan = createSamplePlan();
    await store.write(plan, savedId: 7);

    final draft = await store.read();
    expect(draft, isNotNull);
    expect(draft!.savedId, 7);
    expect(draft.plan.toJson(), equals(plan.toJson()));
  });

  test('a never-saved draft keeps savedId null', () async {
    await store.write(createSamplePlan());
    expect((await store.read())!.savedId, isNull);
  });

  test('writing twice keeps only the latest and leaves no .tmp file', () async {
    final plan = createSamplePlan();
    await store.write(plan.copyWith(learnerContext: 'first'));
    await store.write(plan.copyWith(learnerContext: 'second'));

    expect((await store.read())!.plan.learnerContext, 'second');
    expect(dir.listSync().where((e) => e.path.endsWith('.tmp')), isEmpty);
  });

  test('a corrupt draft reads as null and is deleted', () async {
    File('${dir.path}/current_draft.json').writeAsStringSync('{not json');

    expect(await store.read(), isNull);
    expect(File('${dir.path}/current_draft.json').existsSync(), isFalse);
  });

  test('clear removes the draft', () async {
    await store.write(createSamplePlan());
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('a clear issued right after a write wins (operations are ordered)',
      () async {
    final plan = createSamplePlan();
    final w = store.write(plan);
    final c = store.clear();
    await Future.wait([w, c]);

    expect(await store.read(), isNull);
  });
}
