import 'package:test/test.dart';

import 'package:ai_lesson_planner/services/ai_service.dart';
import 'package:ai_lesson_planner/services/downloads.dart';
import 'package:ai_lesson_planner/core/app_config.dart';

void main() {
  group('AI Service Tests', () {
    test('AI Service should be instantiable', () {
      final aiService = AIService();
      expect(aiService, isA<AIService>());
    });
    
    test('AI Service is a singleton', () {
      final aiService1 = AIService();
      final aiService2 = AIService();
      expect(identical(aiService1, aiService2), isTrue);
    });
    
    test('Model config should have valid URL', () {
      // Test that the model configuration is valid
      expect(AppConfig.modelDownloadUrl, isNotEmpty);
      expect(AppConfig.modelDownloadUrl.contains('http'), isTrue);
    });
    
    test('Model config should have model file name', () {
      expect(AppConfig.modelFileName, isNotEmpty);
      expect(AppConfig.modelFileName.endsWith('.gguf'), isTrue);
    });
    
    test('ILAW format should be non-empty', () {
      expect(AppConfig.ilawFormat, isNotEmpty);
      expect(AppConfig.ilawFormat.contains('I INTENTIONS'), isTrue);
      expect(AppConfig.ilawFormat.contains('L LEARNING EXPERIENCES'), isTrue);
      expect(AppConfig.ilawFormat.contains('A ASSESSMENT'), isTrue);
      expect(AppConfig.ilawFormat.contains('W WAYS FORWARD'), isTrue);
    });
    
    test('Download service should resolve model file path', () async {
      final downloadService = DownloadService();
      final modelPath = await downloadService.getModelFilePath();
      expect(modelPath, isNotEmpty);
      expect(modelPath.contains(AppConfig.modelFileName), isTrue);
    });
    
    test('Simulated lesson plan generation should work', () async {
      final result = AIService.generateSimulatedLessonPlan(
        topic: 'Math',
        gradeLevel: 'Grade 3',
        learningArea: 'Mathematics',
      );
      expect(result, isNotEmpty);
      expect(result.contains('I INTENTIONS'), isTrue);
      expect(result.contains('L LEARNING EXPERIENCES'), isTrue);
      expect(result.contains('A ASSESSMENT'), isTrue);
      expect(result.contains('W WAYS FORWARD'), isTrue);
    });
    
    test('Lesson plan prompt builder should work', () async {
      final prompt = AIService.buildLessonPlanPrompt(
        topic: 'Science',
        gradeLevel: 'Grade 4',
        learningArea: 'Science',
      );
      expect(prompt, isNotEmpty);
      expect(prompt.contains('TOPIC: Science'), isTrue);
      expect(prompt.contains('GRADE LEVEL: Grade 4'), isTrue);
      expect(prompt.contains('ILAW FORMAT INSTRUCTIONS'), isTrue);
    });
  });
  
  group('LLM Inference Tests', () {
    test('Compute isolate function should exist', () {
      // Test that the isolate function is defined
      expect(AIService.generateLessonPlanInIsolate, isA<Function>());
    });
    
    test('Model path resolution should work', () async {
      final aiService = AIService();
      final modelPath = await aiService.getModelPath();
      expect(modelPath, isA<String>());
    });
  });
}
