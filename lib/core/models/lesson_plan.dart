part 'plan_header.dart';
part 'grade_block.dart';
part 'flow_stage.dart';
part 'assessment.dart';
part 'ways_forward.dart';

/// Domain model for ILAW lesson plans.
/// Plain Dart data classes with hand-written JSON serialization.

/// Plan section enum for schema versioning and section tracking
enum PlanSection {
  header,
  intentions,
  learningExperiences,
  assessment,
  waysForward
}

extension PlanSectionName on PlanSection {
  String get eventName => switch (this) {
        PlanSection.header => '',
        PlanSection.intentions => 'Intentions',
        PlanSection.learningExperiences => 'Learning Experiences',
        PlanSection.assessment => 'Assessment',
        PlanSection.waysForward => 'Ways Forward',
      };
}

/// Exception thrown when a plan version is not supported
class PlanVersionException implements Exception {
  final int foundVersion;
  final int maxVersion;
  PlanVersionException(this.foundVersion, this.maxVersion);
  @override
  String toString() =>
      'Plan version \\$foundVersion is not supported (max: \\$maxVersion).';
}

/// Complete lesson plan following the ILAW DLP format
class LessonPlan {
  LessonPlan({
    required this.header,
    required this.grades,
    required this.sharedSubTheme,
    required this.bothGradesObjective,
    required this.learnerContext,
    required this.materials,
    required this.references,
    required this.flow,
    required this.assessments,
    required this.reflectionQuestions,
    required this.waysForward,
    required this.notesNextSession,
    required this.preparedBy,
    required this.checkedBy,
    required this.aiUseDeclaration,
  });

  final PlanHeader header;
  final List<GradeBlock> grades;
  final String sharedSubTheme;
  final String bothGradesObjective;
  final String learnerContext;
  final List<String> materials;
  final List<String> references;
  final List<FlowStage> flow;
  final List<GradeAssessment> assessments;
  final List<ReflectionQuestion> reflectionQuestions;
  final List<GradeWaysForward> waysForward;
  final String notesNextSession;
  final String preparedBy;
  final String checkedBy;
  final String aiUseDeclaration;

  /// The current schema version for this plan format
  static const int currentSchemaVersion = 2;

  /// Calculate total minutes from flow stages
  int get totalFlowMinutes =>
      flow.fold<int>(0, (sum, stage) => sum + stage.minutes);

  Map<String, dynamic> toJson() => {
        'header': header.toJson(),
        'grades': grades.map((g) => g.toJson()).toList(),
        'sharedSubTheme': sharedSubTheme,
        'bothGradesObjective': bothGradesObjective,
        'learnerContext': learnerContext,
        'materials': materials,
        'references': references,
        'flow': flow.map((s) => s.toJson()).toList(),
        'assessments': assessments.map((a) => a.toJson()).toList(),
        'reflectionQuestions':
            reflectionQuestions.map((r) => r.toJson()).toList(),
        'waysForward': waysForward.map((w) => w.toJson()).toList(),
        'notesNextSession': notesNextSession,
        'preparedBy': preparedBy,
        'checkedBy': checkedBy,
        'aiUseDeclaration': aiUseDeclaration,
        'schemaVersion': currentSchemaVersion,
      };

  factory LessonPlan.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    if (schemaVersion > currentSchemaVersion) {
      throw PlanVersionException(schemaVersion, currentSchemaVersion);
    }
    return LessonPlan(
      header: PlanHeader.fromJson(json['header'] as Map<String, dynamic>),
      grades: (json['grades'] as List<dynamic>)
          .map((g) => GradeBlock.fromJson(g as Map<String, dynamic>))
          .toList(),
      sharedSubTheme: json['sharedSubTheme'] as String,
      bothGradesObjective: json['bothGradesObjective'] as String,
      learnerContext: json['learnerContext'] as String,
      materials: List<String>.from(json['materials'] as List<dynamic>? ?? []),
      references: List<String>.from(json['references'] as List<dynamic>? ?? []),
      flow: (json['flow'] as List<dynamic>)
          .map((s) => FlowStage.fromJson(s as Map<String, dynamic>))
          .toList(),
      assessments: (json['assessments'] as List<dynamic>?)
              ?.map((a) => GradeAssessment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      reflectionQuestions: (json['reflectionQuestions'] as List<dynamic>?)
              ?.map(
                  (r) => ReflectionQuestion.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      waysForward: (json['waysForward'] as List<dynamic>?)
              ?.map((w) => GradeWaysForward.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      notesNextSession: json['notesNextSession'] as String,
      preparedBy: json['preparedBy'] as String,
      checkedBy: json['checkedBy'] as String,
      aiUseDeclaration: json['aiUseDeclaration'] as String,
    );
  }

  LessonPlan copyWith({
    PlanHeader? header,
    List<GradeBlock>? grades,
    String? sharedSubTheme,
    String? bothGradesObjective,
    String? learnerContext,
    List<String>? materials,
    List<String>? references,
    List<FlowStage>? flow,
    List<GradeAssessment>? assessments,
    List<ReflectionQuestion>? reflectionQuestions,
    List<GradeWaysForward>? waysForward,
    String? notesNextSession,
    String? preparedBy,
    String? checkedBy,
    String? aiUseDeclaration,
  }) =>
      LessonPlan(
        header: header ?? this.header,
        grades: grades ?? this.grades,
        sharedSubTheme: sharedSubTheme ?? this.sharedSubTheme,
        bothGradesObjective: bothGradesObjective ?? this.bothGradesObjective,
        learnerContext: learnerContext ?? this.learnerContext,
        materials: materials ?? this.materials,
        references: references ?? this.references,
        flow: flow ?? this.flow,
        assessments: assessments ?? this.assessments,
        reflectionQuestions: reflectionQuestions ?? this.reflectionQuestions,
        waysForward: waysForward ?? this.waysForward,
        notesNextSession: notesNextSession ?? this.notesNextSession,
        preparedBy: preparedBy ?? this.preparedBy,
        checkedBy: checkedBy ?? this.checkedBy,
        aiUseDeclaration: aiUseDeclaration ?? this.aiUseDeclaration,
      );
}

/// The default AI use declaration text
const String defaultAiUseDeclaration =
    'Ang planong ito ay burador na binuo ng AI. Dapat itong repasuhin at ayusin ng guro bago gamitin.';
