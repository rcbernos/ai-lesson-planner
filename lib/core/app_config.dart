/// Application configuration constants
class AppConfig {
  static const String appName = 'AI Lesson Plan Assistant';
  static const String version = '1.0.0';
  
  /// ILAW Format - Intentions, Learning Experiences, Assessing Learning, Ways Forward
  static const String ilawFormat = '''
ILAW FORMAT - Offline AI Lesson Plan Assistant

I - Intentions: 
- What is the overall purpose of this learning sequence?
- What should students know, understand, or be able to do by the end?

L - Learning Experiences:
- What activities will help students achieve the intentions?
- What resources and materials are needed?
- What differentiation strategies will be used?

A - Assessing Learning:
- How will you know if students have achieved the intentions?
- What evidence will you collect?
- What formative and summative assessments will you use?

W - Ways Forward:
- What steps will you take based on assessment results?
- How will you remediate or extend learning?
- What next steps are needed for continued progress?

---
AI Use Declaration:
This lesson plan was generated with the assistance of an AI language model.
Content has been reviewed and refined by the teacher.
''';

  /// Model file path (relative to application data directory)
  static const String modelFileName = 'sea-liongguf-q4_0.gguf';
  
  /// Default export directory
  static const String defaultExportDir = '/LMS_Data/Exports/';
}
