/// Utility functions for the application
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_config.dart';

class AppUtils {
  /// Get the application support directory for storing model files and data
  static Future<String> getAppSupportDir() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }
  
  /// Get the absolute path for the GGUF model file
  static Future<String> getModelFilePath() async {
    final appDir = await getAppSupportDir();
    return '$appDir/models/${AppConfig.modelFileName}';
  }
  
  /// Ensure required directories exist
  static Future<void> ensureDirectoriesExist() async {
    final appDir = await getAppSupportDir();
    final modelDir = Directory('$appDir/models');
    final exportDir = Directory('/LMS_Data/Exports');
    
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
  }
}
