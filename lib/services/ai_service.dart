/// AI Service for LLM model operations and inference
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../core/app_config.dart';
import 'downloads.dart'; // Same directory - no path needed

/// Simple logging function - replaces Flutter's debugPrint for cross-platform compatibility
void log(String message) {
  // ignore: avoid_print
  print(message);
}

/// Result message for isolate communication
class _IsolateResult<T> {
  final T value;
  final Object? error;

  _IsolateResult.success(this.value) : error = null;
  _IsolateResult.error(this.error) : value = null as T;
}

/// Pure Dart implementation of Flutter's compute() function
/// Runs a function in a separate isolate and returns the result
Future<T> computeDart<Q, T>(FutureOr<T> Function(Q) function, Q message) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_isolateEntryPoint, [receivePort.sendPort, message, function]);
  final result = await receivePort.first as _IsolateResult<T>;
  receivePort.close();
  
  if (result.error != null) {
    throw result.error!;
  }
  return result.value;
}

/// Entry point for isolate spawning
void _isolateEntryPoint(List<dynamic> args) {
  final SendPort sendPort = args[0] as SendPort;
  final dynamic message = args[1];
  final Function function = args[2];
  
  try {
    final result = function(message);
    sendPort.send(_IsolateResult.success(result));
  } catch (e) {
    sendPort.send(_IsolateResult.error(e));
  }
}

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

  /// Generate lesson plan text using LLM
  /// This runs in a background isolate using computeDart()
  static Future<String> generateLessonPlanInIsolate(
    Map<String, dynamic> params,
  ) async {
    return await computeDart(_generateLessonPlanInIsolate, params);
  }

  /// Actual lesson plan generation logic that runs in a background isolate.
  /// This function is designed to run in a separate isolate using computeDart().
  /// It loads the LLM model and generates text. The model is loaded fresh
  /// within the isolate because LLM models cannot be shared across isolates.
  /// 
  /// Parameters:
  /// - modelPath: Absolute path to the GGUF model file
  /// - topic: The learning topic for the lesson plan
  /// - gradeLevel: Grade level for the lesson plan
  /// - learningArea: Subject/area for the lesson plan
  static String _generateLessonPlanInIsolate(Map<String, dynamic> params) {
    try {
      // Extract parameters from the map
      final modelPath = params['modelPath'] as String?;
      final topic = params['topic'] ?? 'General Lesson';
      final gradeLevel = params['gradeLevel'] ?? 'Grade 1';
      final learningArea = params['learningArea'] ?? 'Filipino';
      
      // If no model path provided, return simulated response
      if (modelPath == null || modelPath.isEmpty) {
        log('LLM: No model path provided, returning simulated response');
        return generateSimulatedLessonPlan(
          topic: topic,
          gradeLevel: gradeLevel,
          learningArea: learningArea,
        );
      }
      
      // Check if model file exists
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        log('LLM: Model file not found at $modelPath, returning simulated response');
        return generateSimulatedLessonPlan(
          topic: topic,
          gradeLevel: gradeLevel,
          learningArea: learningArea,
        );
      }
      
      // Run actual LLM inference
      log('LLM: Running inference with model at: $modelPath');
      return _runLLMInference(modelPath, topic, gradeLevel, learningArea);
    } catch (e, stackTrace) {
      // Log error and return fallback
      log('LLM Inference error in isolate: $e');
      log('Stack trace: $stackTrace');
      
      final topic = params['topic'] ?? 'General Lesson';
      final gradeLevel = params['gradeLevel'] ?? 'Grade 1';
      final learningArea = params['learningArea'] ?? 'Filipino';
      
      return generateSimulatedLessonPlan(
        topic: topic,
        gradeLevel: gradeLevel,
        learningArea: learningArea,
      );
    }
  }

  /// Generate a simulated lesson plan (fallback when no model is available)
  /// Made public for testing purposes
  static String generateSimulatedLessonPlan({
    required String topic,
    required String gradeLevel,
    required String learningArea,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('I INTENTIONS');
    buffer.writeln('============');
    buffer.writeln('Topic: $topic');
    buffer.writeln('Grade Level: $gradeLevel');
    buffer.writeln('Learning Area: $learningArea');
    buffer.writeln('');
    buffer.writeln('L LEARNING EXPERIENCES');
    buffer.writeln('======================');
    buffer.writeln('[Generated lesson plan content for $topic]');
    buffer.writeln('');
    buffer.writeln('A ASSESSMENT');
    buffer.writeln('============');
    buffer.writeln('[Assessment activities]');
    buffer.writeln('');
    buffer.writeln('W WAYS FORWARD');
    buffer.writeln('==============');
    buffer.writeln('[Reflection and extension activities]');
    
    return buffer.toString();
  }

  /// Run LLM inference using llama_cpp_dart
  /// This runs within the isolate and cannot be mocked
  /// 
  /// Parameters:
  /// - modelPath: Absolute path to the GGUF model file
  /// - topic: The learning topic
  /// - gradeLevel: Grade level for the lesson plan
  /// - learningArea: Subject/area for the lesson plan
  static String _runLLMInference(
    String modelPath, 
    String topic, 
    String gradeLevel, 
    String learningArea,
  ) {
    try {
      // Build the prompt using ILAW format template
      final prompt = buildLessonPlanPrompt(
        topic: topic,
        gradeLevel: gradeLevel,
        learningArea: learningArea,
      );
      
      // Configure model parameters
      final modelParams = ModelParams()
        ..vocabOnly = false
        ..useMemorymap = true
        ..useMemoryLock = false
        ..checkTensors = false;
      
      // Configure context parameters
      final contextParams = ContextParams()
        ..nCtx = 2048 // Context window size
        ..nBatch = 512
        ..nThreads = Platform.isWindows ? 2 : 4
        ..nPredict = 512; // Max tokens to generate
      
      final samplingParams = SamplerParams()
        ..temp = 0.7
        ..topK = 40
        ..topP = 0.9
        ..seed = 42; // For reproducibility
      
      // Initialize the Llama model
      log('LLM: Loading model from: $modelPath');
      final llama = Llama(
        modelPath,
        modelParams: modelParams,
        contextParams: contextParams,
        samplerParams: samplingParams,
        verbose: false,
      );
      
      log('LLM: Model loaded successfully');
      
      // Generate text
      final generatedText = StringBuffer();
      llama.setPrompt(prompt);
      
      log('LLM: Starting text generation...');
      
      while (true) {
        final (token, done) = llama.getNext();
        generatedText.write(token);
        
        if (done) break;
        
        // Safety limit to prevent infinite generation
        if (generatedText.length > 8000) {
          log('LLM: Generation limit reached');
          break;
        }
      }
      
      // Clean up
      llama.dispose();
      log('LLM: Model disposed');
      
      if (generatedText.isEmpty) {
        log('LLM: Generated empty response, using fallback');
        return generateSimulatedLessonPlan(
          topic: topic,
          gradeLevel: gradeLevel,
          learningArea: learningArea,
        );
      }
      
      log('LLM: Generation completed (${generatedText.length} chars)');
      return generatedText.toString();
    } on LlamaException catch (e) {
      log('LlamaException during inference: ${e.message}');
      return generateSimulatedLessonPlan(
        topic: topic,
        gradeLevel: gradeLevel,
        learningArea: learningArea,
      );
    } catch (e) {
      log('Error during LLM inference: $e');
      return generateSimulatedLessonPlan(
        topic: topic,
        gradeLevel: gradeLevel,
        learningArea: learningArea,
      );
    }
  }

  /// Build a lesson plan prompt using the ILAW format
  static String buildLessonPlanPrompt({
    required String topic,
    required String gradeLevel,
    required String learningArea,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Generate a comprehensive lesson plan based on the ILAW format.');
    buffer.writeln('');
    buffer.writeln('TOPIC: $topic');
    buffer.writeln('GRADE LEVEL: $gradeLevel');
    buffer.writeln('LEARNING AREA: $learningArea');
    buffer.writeln('');
    buffer.writeln('ILAW FORMAT INSTRUCTIONS:');
    buffer.writeln('I INTENTIONS: Include Shared Sub-theme, Content Standard, Performance Standard, Learning Competencies, and Learning Objectives.');
    buffer.writeln('L LEARNING EXPERIENCES: Include Learner Context, Instructional Materials, and Flow of Lesson with time-activity table.');
    buffer.writeln('A ASSESSMENT: Include Formative Assessment, Exit Task, and Success Criteria.');
    buffer.writeln('W WAYS FORWARD: Include Reflection Questions, Remediation, and Enrichment.');
    buffer.writeln('');
    buffer.writeln('Please generate a detailed lesson plan following this format.');
    
    return buffer.toString();
  }

  /// Generate lesson plan (main entry point)
  /// Creates a copy of params with modelPath for the isolate
  Future<String> generateLessonPlan(Map<String, dynamic> params) async {
    final modelPath = await ensureModelAvailable();
    
    if (modelPath == null) {
      // If no model, return simulated response
      final topic = params['topic'] ?? 'General Lesson';
      final gradeLevel = params['gradeLevel'] ?? 'Grade 1';
      final learningArea = params['learningArea'] ?? 'Filipino';
      return generateSimulatedLessonPlan(
        topic: topic,
        gradeLevel: gradeLevel,
        learningArea: learningArea,
      );
    }
    
    if (!await File(modelPath).exists()) {
      throw Exception('Model not available: Cannot generate lesson plan');
    }

    // Prepare parameters for isolate with model path
    final isolateParams = {
      ...params,
      'modelPath': modelPath,
    };

    // Run generation in background isolate
    return await generateLessonPlanInIsolate(isolateParams);
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