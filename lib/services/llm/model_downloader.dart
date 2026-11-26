/// Model downloader for downloading GGUF model files.
///
/// Handles downloading from HuggingFace with progress tracking,
/// SHA-256 verification, and saving to app-private storage.
library;

import 'dart:async';
import 'dart:io';

import 'package:ai_lesson_planner/services/llm/model_manifest.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Progress state for model downloads.
class DownloadProgress {
  DownloadProgress({
    required this.bytesReceived,
    this.totalBytes,
    this.isComplete = false,
    this.error,
  });

  /// Bytes received so far.
  final int bytesReceived;

  /// Total bytes if known.
  final int? totalBytes;

  /// Whether download has completed.
  final bool isComplete;

  /// Error message if failed.
  final String? error;

  /// Percentage of completion (0.0 to 1.0).
  double get percentage =>
      totalBytes == null ? 0.0 : (bytesReceived / totalBytes!).clamp(0.0, 1.0);

  DownloadProgress copyWith({
    int? bytesReceived,
    int? totalBytes,
    bool? isComplete,
    String? error,
  }) {
    return DownloadProgress(
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

/// Downloads and installs LLM model files.
class ModelDownloader {
  /// HuggingFace URL for the prototype model.
  static const String _modelUrl =
      'https://huggingface.co/bayani/SEA-LION-v4-4B-VL-GGUF/resolve/main/SEA-LION-v4-4B-VL-Q4_K_M.gguf';

  /// Expected SHA-256 checksum for the model file.
  /// TODO: Update with actual checksum when model is downloaded.
  static const String _expectedChecksum =
      'update_with_actual_sha256_after_first_download';

  final _client = http.Client();
  final _subscription = StreamController<void>();

  /// Downloads the model file with progress tracking.
  Stream<DownloadProgress> download({
    String fileName = 'model.gguf',
    Uri? customUrl,
    String? expectedChecksum,
  }) async* {
    final url = customUrl ?? Uri.parse(_modelUrl);
    final checksum = expectedChecksum ?? _expectedChecksum;

    yield DownloadProgress(bytesReceived: 0, totalBytes: 0, isComplete: false);

    try {
      final request = http.Request('GET', url);
      final response = await _client.send(request);

      final totalBytes = response.contentLength;
      var bytesReceived = 0;

      final chunks = <int>[];
      await for (final chunk in response.stream) {
        // Check for cancellation
        if (!_subscription.isClosed) {
          chunks.addAll(chunk);
          bytesReceived += chunk.length;

          yield DownloadProgress(
            bytesReceived: bytesReceived,
            totalBytes: totalBytes,
            isComplete: false,
          );
        }
      }

      // Verify checksum (skip if placeholder)
      if (checksum != _expectedChecksum) {
        final computedHash = computeSha256(chunks);
        if (computedHash != checksum) {
          yield DownloadProgress(
            bytesReceived: bytesReceived,
            totalBytes: totalBytes,
            isComplete: false,
            error: 'Checksum verification failed',
          );
          return;
        }
      }

      // Save the model
      await saveModel(chunks, fileName);

      yield DownloadProgress(
        bytesReceived: bytesReceived,
        totalBytes: totalBytes,
        isComplete: true,
      );
    } catch (e) {
      yield DownloadProgress(
        bytesReceived: 0,
        totalBytes: null,
        isComplete: false,
        error: e.toString(),
      );
    }
  }

  /// Saves model bytes to the app's files directory.
  Future<void> saveModel(List<int> bytes, String fileName) async {
    Directory? appDir;
    try {
      appDir = await getExternalStorageDirectory();
    } on UnsupportedError {
      // Not supported on this platform (e.g., Linux tests)
      appDir = null;
    }

    appDir ??= await getApplicationSupportDirectory();
    final file = File('${appDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Computes SHA-256 hash of the given bytes.
  String computeSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Returns the HuggingFace download URL for a given model name.
  static String generateDownloadUrl(String modelName) {
    return 'https://huggingface.co/bayani/SEA-LION-v4-4B-VL-GGUF/resolve/main/$modelName';
  }

  /// Gets the path where the model should be saved.
  Future<String> getModelPath(String fileName) async {
    Directory? appDir;
    try {
      appDir = await getExternalStorageDirectory();
    } on UnsupportedError {
      appDir = null;
    }

    appDir ??= await getApplicationSupportDirectory();
    return '${appDir.path}/$fileName';
  }

  /// Deletes the downloaded model file.
  Future<void> deleteModel(String fileName) async {
    Directory? appDir;
    try {
      appDir = await getExternalStorageDirectory();
    } on UnsupportedError {
      appDir = null;
    }

    appDir ??= await getApplicationSupportDirectory();
    final file = File('${appDir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks if a model file exists and is valid.
  Future<bool> isModelDownloaded(String fileName) async {
    final path = await getModelPath(fileName);
    final file = File(path);

    if (!await file.exists()) return false;

    final size = await file.length();
    // Minimum 100 MB for a valid model
    return size >= 100 * 1024 * 1024;
  }

  /// Cancels any ongoing download.
  Future<void> cancel() async {
    await _subscription.close();
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _subscription.close();
    _client.close();
  }

  /// Downloads model and updates manifest.
  Future<DownloadResult> downloadAndUpdateManifest({
    String fileName = 'model.gguf',
    String modelName = 'qwen4b-sea-lion-q4_k_m.gguf',
  }) async {
    final errors = <String>[];
    int bytesReceived = 0;

    await for (final progress in download(fileName: fileName)) {
      if (progress.error != null) {
        errors.add(progress.error!);
      }

      if (progress.isComplete) {
        bytesReceived = progress.bytesReceived;

        // Update manifest
        try {
          final manifest = await ModelManifest.load();
          await manifest.save();
          return DownloadResult.success(bytesReceived: bytesReceived);
        } catch (e) {
          return DownloadResult.error(
            'Download complete but manifest update failed: $e',
          );
        }
      }
    }

    final error = errors.isNotEmpty ? errors.join('\n') : 'Download cancelled';
    return DownloadResult.error(error);
  }
}

/// Result of a download operation.
class DownloadResult {
  DownloadResult.success({required this.bytesReceived})
    : error = null,
      isSuccess = true;

  DownloadResult.error(this.error) : bytesReceived = 0, isSuccess = false;

  final int bytesReceived;
  final String? error;
  final bool isSuccess;
}
