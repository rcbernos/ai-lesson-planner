/// Utilities for checking model file paths and availability.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utility class for model file path operations.
class ModelPaths {
  /// Checks if a model file exists and meets minimum size requirements.
  /// Returns the model file path if valid, null otherwise.
  static Future<String?> checkModelInstalled() async {
    // Use external storage directory (app-specific external files dir)
    // On Android, this resolves to: getExternalFilesDir(null)
    // which is: /sdcard/Android/data/<package>/files/
    // No storage permission needed for this directory.
    // Falls back to application support directory on non-Android platforms.
    Directory? appDir;
    try {
      appDir = await getExternalStorageDirectory();
    } on UnsupportedError {
      // getExternalStorageDirectory is not supported on this platform (e.g., Linux tests)
      appDir = null;
    }

    appDir ??= await getApplicationSupportDirectory();

    final modelPath = p.join(appDir.path, 'model.gguf');
    final file = File(modelPath);

    if (!await file.exists()) return null;

    // Check minimum size (100 MB)
    final fileSize = await file.length();
    const int minSize = 100 * 1024 * 1024; // 100 MB

    if (fileSize < minSize) return null;

    return modelPath;
  }

  /// Gets the expected model file path for loading.
  static Future<String> getExpectedModelPath() async {
    Directory? appDir;
    try {
      appDir = await getExternalStorageDirectory();
    } on UnsupportedError {
      appDir = null;
    }

    appDir ??= await getApplicationSupportDirectory();

    return p.join(appDir.path, 'model.gguf');
  }

  /// Gets the file size of the installed model in bytes.
  /// Returns null if model doesn't exist.
  static Future<int?> getModelFileSize() async {
    final path = await checkModelInstalled();
    if (path == null) return null;
    return File(path).length();
  }

  /// Formats file size in human-readable format.
  static String formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes bytes';
  }
}
