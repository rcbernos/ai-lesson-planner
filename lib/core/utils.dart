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
  
  /// Interpolate template placeholders with actual values
  /// 
  /// [template] is the ILAW template string with placeholders like ____,
  /// [values] is a map of placeholder names to their replacement values
  /// 
  /// Example:
  /// ```dart
  /// final lessonPlan = AppUtils.interpolateTemplate(
  ///   AppConfig.ilawFormat,
  ///   {
  ///     'GRADE LEVEL': 'Grade 3',
  ///     'LEARNING AREA': 'FILIPINO',
  ///     'Time': '5 min',
  ///   },
  /// );
  /// ```
  static String interpolateTemplate(String template, Map<String, String> values) {
    var result = template;
    for (final entry in values.entries) {
      final placeholder = entry.key;
      final value = entry.value;
      result = result.replaceAll(placeholder, value);
    }
    return result;
  }
}
