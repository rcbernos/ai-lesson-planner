/// Utility functions for the application.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_config.dart';

class AppUtils {
  /// App-private support directory (database, models, drafts).
  static Future<String> getAppSupportDir() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  /// Absolute path for the GGUF model file.
  static Future<String> getModelFilePath() async {
    final appDir = await getAppSupportDir();
    return p.join(appDir, 'models', AppConfig.modelFileName);
  }

  /// Export folder: <documents>/LMS_Data/Exports.
  static Future<String> getExportDirPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'LMS_Data', 'Exports');
  }

  /// Ensure required directories exist (no-op if they already do).
  static Future<void> ensureDirectoriesExist() async {
    final modelDir = p.dirname(await getModelFilePath());
    await Directory(modelDir).create(recursive: true);
    await Directory(await getExportDirPath()).create(recursive: true);
  }

  /// Replace placeholder keys in [template] with the matching [values].
  static String interpolateTemplate(
      String template, Map<String, String> values) {
    var result = template;
    for (final entry in values.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
