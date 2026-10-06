/// AI Service for LLM model operations and inference
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../core/app_config.dart';
import 'downloads.dart'; // Same directory - no path needed

/// Type aliases for callbacks
typedef ProgressCallback = void Function(int received, int total);
typedef ErrorCallback = void Function(String error);

/// AI Service for managing LLM operations
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Download service instance
  final downloadService = DownloadService();

  /// Check if model file exists locally
  Future<bool> isModelAvailable() async {
    return await downloadService.modelExists();
  }

  /// Get the absolute path to the GGUF model file
  Future<String> getModelPath() async {
    final file = await downloadService.getModelFile();
    return file.path;
  }

  /// Download model if not present
  Future<String?> ensureModelAvailable({
    ProgressCallback? onProgress,
    ErrorCallback? onError,
  }) async {
    final exists = await isModelAvailable();
    
    if (exists) {
      final path = await getModelPath();
      return path;
    }

    // Download the model
    return await downloadService.downloadModel(
      onProgress: onProgress,
      onError: onError,
    );
  }

  /// Generate lesson plan text using LLM (simulated for now)
  /// This runs in a background isolate using compute()
  static Future<String> generateLessonPlanInIsolate(
    Map<String, dynamic> params,
  ) async {
    return await compute(_generateLessonPlan, params);
  }

  /// Actual lesson plan generation logic (runs in isolate)
  static String _generateLessonPlan(Map<String, dynamic> params) {
    // Simulate LLM token generation
    // In real implementation, this would use llama_cpp_dart
    final topic = params['topic'] ?? 'General';
    final gradeLevel = params['gradeLevel'] ?? 'Grade 1';
    final learningArea = params['learningArea'] ?? 'Filipino';
    
    // Simulate processing time
    // In production, this would call the actual LLM
    final StringBuffer buffer = StringBuffer();
    
    // Generate ILAW format placeholder content
    buffer.writeln('I INTENTIONS');
    buffer.writeln('-----------');
    buffer.writeln('Learning Area: $learningArea');
    buffer.writeln('Grade Level: $gradeLevel');
    buffer.writeln('Topic: $topic');
    buffer.writeln('');
    buffer.writeln('L LEARNING EXPERIENCES');
    buffer.writeln('----------------------');
    buffer.writeln('[Generated lesson plan content]');
    buffer.writeln('');
    buffer.writeln('A ASSESSMENT');
    buffer.writeln('------------');
    buffer.writeln('[Assessment activities]');
    buffer.writeln('');
    buffer.writeln('W WAYS FORWARD');
    buffer.writeln('--------------');
    buffer.writeln('[Reflection and extension activities]');
    
    return buffer.toString();
  }

  /// Generate lesson plan (main entry point)
  Future<String> generateLessonPlan(Map<String, dynamic> params) async {
    final modelPath = await ensureModelAvailable();
    
    if (modelPath == null || !await File(modelPath).exists()) {
      throw Exception('Model not available: Cannot generate lesson plan');
    }

    // Run generation in background isolate
    return await generateLessonPlanInIsolate(params);
  }

  /// Initialize the AI service (download model if needed)
  Future<void> initialize({
    ProgressCallback? onProgress,
    final bool downloadOnDemand = true,
  }) async {
    try {
      final available = await ensureModelAvailable(
        onProgress: onProgress,
        onError: (error) => print('AI Service error: $error'),
      );
      
      if (available != null) {
        print('AI Service initialized with model at: $available');
      } else if (downloadOnDemand) {
        print('Model download required');
      }
    } catch (e) {
      print('AI Service initialization error: $e');
      rethrow;
    }
  }

  /// Check if the current configuration has a valid checksum
  bool isConfigurationValid() {
    return AppConfig.isChecksumVerified();
  }

  /// Force a checksum verification
  Future<bool> verifyCurrentModel() async {
    final modelPath = await getModelPath();
    return await downloadService.verifyChecksum(modelPath);
  }

  /// Cleanup - remove downloaded model if needed
  Future<void> cleanup() async {
    try {
      final modelPath = await getModelPath();
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Cleanup error: $e');
    }
  }
}