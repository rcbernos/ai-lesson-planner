/// Application configuration constants
class AppConfig {
  static const String appName = 'AI Lesson Plan Assistant';
  static const String version = '1.0.0';
  
  /// ILAW Format - Official DepEd Daily Lesson Plan Template
  /// Based on official DepEd DLP format for Grades 1-4
  static const String ilawFormat = '''
ILAW FORMAT - OFFICIAL DEPED LESSON PLAN TEMPLATE

I INTENTIONS
=============
PHASE: Term ____, Quarter ____
GRADE LEVEL: ____
LEARNING AREA: ____
SHARED SUB-THEME: 

Pamantayang Pangnilalamaan:
__________________________________________________________
What should learners know, understand, or be able to do?
(e.g., Natutuhan, Naipamamalas, Natutukoy ang ...)

Pamantayan sa Pagganap:
__________________________________________________________
What should learners be able to do at the end of the lesson?
(e.g., Nagagamit, Nakagagawa, Nakapagpapahayag ng ...)

Mga Kasanayan at Layuning Pampagkatuto:
__________________________________________________________
List the specific learning competencies (with codes if available):
- ________________________________
- ________________________________

LEARNING OBJECTIVES:
__________________________________________________________
By the end of the lesson, learners will be able to:
- Natutukoy ang...
- Nakapagpapahayag ng...
- Makapagbabahagi ng...

L LEARNING EXPERIENCES
=====================
LEARNER CONTEXT:
__________________________________________________________
Describe the learners and their relevant background:
(e.g., Ang mga mag-aaral ay may iba't ibang karanasan...)

INSTRUCTIONAL MATERIALS:
__________________________________________________________
- ________________________________
- ________________________________
- ________________________________

FLOW OF LESSON:
| Time | Stage | Activities |
|------|-------|------------|
| ____ | Whole-Class Motivation | _______ |
| ____ | Direct Teaching | _______ |
| ____ | Guided/Collaborative Practice | _______ |
| ____ | Independent Practice | _______ |
| ____ | Whole-Class Wrap-Up | _______ |

ACTIVITY DETAILS:
- Motivation: ________________________________________________
- Direct Instruction: ________________________________________
- Guided Practice: ___________________________________________
- Independent Practice: ______________________________________
- Wrap-Up: _________________________________________________

A ASSESSMENT
============
FORMATIVE ASSESSMENT:
__________________________________________________________
How will the teacher check understanding during the lesson?
(e.g., Obserbahan, Tanong-Tanong, Oplan, ...)
- ________________________________________________

EXIT TASK:
__________________________________________________________
A short task at the end of the lesson to assess learning:
(e.g., Isulat, Sabihin, Magbigay, Tukuyin...)
- ________________________________________________

SUCCESS CRITERIA:
__________________________________________________________
How will we know if learners succeeded?
- Nailarawan/Natutukoy ang...
- Nakagagamit ang...
- Nakapagpapahayag ng...

W WAYS FORWARD
==============
REFLECTION QUESTIONS:
__________________________________________________________
- Ano ang natutuhan ngayon?
- Paano ko ito gagamitin sa susunod?
- Ano ang naging mahirap?

REMEDIATION (For learners who need more help):
__________________________________________________________
(e.g., Pangingil, Masusing magbahagi,...)
- ________________________________________________

ENRICHMENT (For learners who need extension):
__________________________________________________________
(e.e., Pagpapalawak, Pagpapakita,...)
- ________________________________________________

NOTES FOR NEXT SESSION:
__________________________________________________________
__________________________________________________________

PREPARED BY: _________________________
CHECKED BY: _________________________

---
AI Use Declaration:
This lesson plan was generated with the assistance of an AI language model.
Content has been reviewed and refined by the teacher.
''';

  /// Model file name
  static const String modelFileName = 'sea-liongguf-q4_0.gguf';
  
  /// Model download URL (HuggingFace/primary source)
  static const String modelDownloadUrl = 'https://huggingface.co/codellama/sea-lion-7b-gguf/resolve/main/sealion-7b-q4_0.gguf';
  
  /// Expected model file size in bytes (for verification)
  /// TODO: Update with actual model file size once downloaded
  static const int modelFileSize = 4000000000; // Example: 4GB
  
  /// SHA256 checksum of the model file for integrity verification
  /// TODO: Update with actual SHA256 checksum after first download
  static const String modelChecksum = 'placeholder-sha256-checksum-not-yet-verified';
  
  /// Default export directory
  static const String defaultExportDir = '/LMS_Data/Exports/';
  
  /// Download chunk size for streaming downloads (in bytes)
  static const int downloadChunkSize = 1048576; // 1MB chunks
  
  /// Timeout for model download (in seconds)
  static const int downloadTimeoutSeconds = 300; // 5 minutes
  
  /// Get the model download URL (can be overridden for testing)
  static String getModelDownloadUrl() => modelDownloadUrl;
  
  /// Check if the configuration has valid checksum
  static bool isChecksumVerified() {
    return !modelChecksum.startsWith('placeholder') && 
           modelChecksum.isNotEmpty &&
           modelChecksum.length == 64; // SHA256 is 64 hex chars
  }
  
  /// Get the expected model file size in MB
  static String getModelSizeFormatted() {
    final mb = modelFileSize / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }
}
