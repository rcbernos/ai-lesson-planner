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

  /// Model file path (relative to application data directory)
  static const String modelFileName = 'sea-liongguf-q4_0.gguf';
  
  /// Model download URL (HuggingFace/primary source)
  static const String modelDownloadUrl = 'https://huggingface.co/codellama/sea-lion-7b-gguf/resolve/main/sealion-7b-q4_0.gguf';
  
  /// Expected model file size in bytes (for verification)
  static const int modelFileSize = 4000000000; // Example: 4GB
  
  /// SHA256 checksum of the model file for integrity verification
  static const String modelChecksum = 'your-sha256-checksum-here';
  
  /// Default export directory
  static const String defaultExportDir = '/LMS_Data/Exports/';
}
