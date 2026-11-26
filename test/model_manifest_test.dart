import 'package:test/test.dart';

import 'package:ai_lesson_planner/services/llm/model_manifest.dart';

void main() {
  group('ModelManifest', () {
    group('DefaultManifest', () {
      test('defaultManifest has correct values', () {
        final manifest = ModelManifest.defaultManifest;
        expect(manifest.version, equals('1'));
        expect(manifest.model, equals('Gemma-SEA-LION-v4-4B-VL-Q4_K_M.gguf'));
      });
    });

    group('Serialization', () {
      test('toJson includes all fields', () {
        final manifest = ModelManifest(
          version: '1',
          model: 'test-model.gguf',
          fileName: 'model.gguf',
          size: 2500000000,
          checksum: 'abc123',
          url: 'https://example.com/model.gguf',
        );

        final json = manifest.toJson();

        expect(json['version'], equals('1'));
        expect(json['model'], equals('test-model.gguf'));
        expect(json['fileName'], equals('model.gguf'));
        expect(json['size'], equals(2500000000));
        expect(json['checksum'], equals('abc123'));
        expect(json['url'], equals('https://example.com/model.gguf'));
      });

      test('toJson omits null values', () {
        final manifest = ModelManifest(version: '1', model: 'test-model.gguf');

        final json = manifest.toJson();

        expect(json.containsKey('fileName'), isFalse);
        expect(json.containsKey('size'), isFalse);
        expect(json.containsKey('checksum'), isFalse);
        expect(json.containsKey('url'), isFalse);
      });

      test('fromJson creates correct instance', () {
        final json = {
          'version': '1',
          'model': 'test-model.gguf',
          'fileName': 'model.gguf',
        };

        final manifest = ModelManifest.fromJson(json);

        expect(manifest.version, equals('1'));
        expect(manifest.model, equals('test-model.gguf'));
        expect(manifest.fileName, equals('model.gguf'));
      });

      test('fromJson provides defaults for missing fields', () {
        final json = {'model': 'minimal-model.gguf'};

        final manifest = ModelManifest.fromJson(json);

        expect(manifest.version, equals('1')); // default
        expect(manifest.model, equals('minimal-model.gguf'));
        expect(manifest.fileName, isNull);
      });

      test('toJson and fromJson round-trip', () {
        final original = ModelManifest(
          version: '2',
          model: 'round-trip-model.gguf',
          url: 'https://example.com/model.gguf',
        );

        final json = original.toJson();
        final parsed = ModelManifest.fromJson(json);

        expect(parsed.version, equals(original.version));
        expect(parsed.model, equals(original.model));
        expect(parsed.url, equals(original.url));
      });
    });

    group('Equality', () {
      test('identical manifests are equal', () {
        final m1 = ModelManifest(version: '1', model: 'test.gguf');
        final m2 = ModelManifest(version: '1', model: 'test.gguf');

        expect(m1 == m2, isTrue);
      });

      test('manifests with different versions are not equal', () {
        final m1 = ModelManifest(version: '1', model: 'test.gguf');
        final m2 = ModelManifest(version: '2', model: 'test.gguf');

        expect(m1 == m2, isFalse);
      });

      test('manifests with different models are not equal', () {
        final m1 = ModelManifest(version: '1', model: 'model1.gguf');
        final m2 = ModelManifest(version: '1', model: 'model2.gguf');

        expect(m1 == m2, isFalse);
      });
    });

    group('defaultFileName', () {
      test('returns fileName when set', () {
        final manifest = ModelManifest(
          version: '1',
          model: 'test-model.gguf',
          fileName: 'custom-model.gguf',
        );

        expect(manifest.defaultFileName, equals('custom-model.gguf'));
      });

      test('returns model when fileName is not set', () {
        final manifest = ModelManifest(version: '1', model: 'test-model.gguf');

        expect(manifest.defaultFileName, equals('test-model.gguf'));
      });
    });
  });
}
