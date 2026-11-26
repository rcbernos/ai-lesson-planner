import 'package:ai_lesson_planner/services/llm/model_downloader.dart';
import 'package:test/test.dart';

void main() {
  group('ModelDownloader', () {
    group('DownloadProgress', () {
      test('copyWith creates modified copy', () {
        final original = DownloadProgress(
          bytesReceived: 100,
          totalBytes: 1000,
          isComplete: false,
        );

        final modified = original.copyWith(
          bytesReceived: 500,
          isComplete: true,
        );

        expect(modified.bytesReceived, equals(500));
        expect(modified.totalBytes, equals(1000));
        expect(modified.isComplete, isTrue);
        expect(original.bytesReceived, equals(100)); // original unchanged
      });
    });

    group('computeSha256', () {
      test('computes correct SHA-256 hash for empty input', () {
        final downloader = ModelDownloader();
        final bytes = <int>[];
        final hash = downloader.computeSha256(bytes);

        // SHA-256 of empty string
        expect(
          hash,
          equals(
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          ),
        );

        downloader.dispose();
      });

      test('computes correct SHA-256 for known input', () {
        final downloader = ModelDownloader();
        // "hello" has known SHA-256
        final bytes = 'hello'.codeUnits;
        final hash = downloader.computeSha256(bytes);

        expect(
          hash,
          equals(
            '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
          ),
        );

        downloader.dispose();
      });
    });

    group('generateDownloadUrl', () {
      test('generates correct HuggingFace URL', () {
        final url = ModelDownloader.generateDownloadUrl('test-model.gguf');

        expect(
          url,
          equals(
            'https://huggingface.co/bayani/SEA-LION-v4-4B-VL-GGUF/resolve/main/test-model.gguf',
          ),
        );
      });
    });

    group('percentage', () {
      test('returns 0 when totalBytes is null', () {
        final progress = DownloadProgress(bytesReceived: 100, totalBytes: null);
        expect(progress.percentage, equals(0.0));
      });

      test('returns correct percentage for partial download', () {
        final progress = DownloadProgress(bytesReceived: 500, totalBytes: 1000);
        expect(progress.percentage, equals(0.5));
      });

      test('returns 1.0 when complete', () {
        final progress = DownloadProgress(
          bytesReceived: 1000,
          totalBytes: 1000,
          isComplete: true,
        );
        expect(progress.percentage, equals(1.0));
      });
    });

    group('DownloadResult', () {
      test('success result has correct values', () {
        final result = DownloadResult.success(bytesReceived: 1024);

        expect(result.bytesReceived, equals(1024));
        expect(result.error, isNull);
        expect(result.isSuccess, isTrue);
      });

      test('error result has correct values', () {
        final result = DownloadResult.error('Download failed');

        expect(result.bytesReceived, equals(0));
        expect(result.error, equals('Download failed'));
        expect(result.isSuccess, isFalse);
      });
    });
  });
}
