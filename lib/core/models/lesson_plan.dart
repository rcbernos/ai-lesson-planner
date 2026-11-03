/// Domain model for ILAW lesson plans.
/// Plain Dart data classes with hand-written JSON serialization.
library;

/// Headers for a lesson plan
class PlanHeader {
  PlanHeader({
    required this.school,
    required this.teacher,
    required this.learningArea,
    required this.date,
    required this.term,
    required this.sessions,
    required this.sessionMinutes,
    required this.multigradeModel,
  });

  final String school;
  final String teacher;
  final String learningArea;
  final String date;
  final String term;
  final int sessions;
  final int sessionMinutes;
  final String multigradeModel;

  Map<String, dynamic> toJson() => {
        'school': school,
        'teacher': teacher,
        'learningArea': learningArea,
        'date': date,
        'term': term,
        'sessions': sessions,
        'sessionMinutes': sessionMinutes,
        'multigradeModel': multigradeModel,
      };

  factory PlanHeader.fromJson(Map<String, dynamic> json) => PlanHeader(
        school: json['school'] as String,
        teacher: json['teacher'] as String,
        learningArea: json['learningArea'] as String,
        date: json['date'] as String,
        term: json['term'] as String,
        sessions: json['sessions'] as int,
        sessionMinutes: json['sessionMinutes'] as int,
        multigradeModel: json['multigradeModel'] as String,
      );

  PlanHeader copyWith({
    String? school,
    String? teacher,
    String? learningArea,
    String? date,
    String? term,
    int? sessions,
    int? sessionMinutes,
    String? multigradeModel,
  }) =>
      PlanHeader(
        school: school ?? this.school,
        teacher: teacher ?? this.teacher,
        learningArea: learningArea ?? this.learningArea,
        date: date ?? this.date,
        term: term ?? this.term,
        sessions: sessions ?? this.sessions,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
        multigradeModel: multigradeModel ?? this.multigradeModel,
      );
}

/// Grade block representing one grade level in a multigrade plan
class GradeBlock {
  GradeBlock({
    required this.gradeLabel,
    required this.learnersMale,
    required this.learnersFemale,
    required this.subTheme,
    required this.contentStandard,
    required this.performanceStandard,
    required this.competencies,
    required this.objectives,
  });

  final String gradeLabel;
  final int learnersMale;
  final int learnersFemale;
  final String subTheme;
  final String contentStandard;
  final String performanceStandard;
  final List<String> competencies;
  final List<String> objectives;

  Map<String, dynamic> toJson() => {
        'gradeLabel': gradeLabel,
        'learnersMale': learnersMale,
        'learnersFemale': learnersFemale,
        'subTheme': subTheme,
        'contentStandard': contentStandard,
        'performanceStandard': performanceStandard,
        'competencies': competencies,
        'objectives': objectives,
      };

  factory GradeBlock.fromJson(Map<String, dynamic> json) => GradeBlock(
        gradeLabel: json['gradeLabel'] as String,
        learnersMale: json['learnersMale'] as int,
        learnersFemale: json['learnersFemale'] as int,
        subTheme: json['subTheme'] as String,
        contentStandard: json['contentStandard'] as String,
        performanceStandard: json['performanceStandard'] as String,
        competencies: List<String>.from(json['competencies'] as List<dynamic>),
        objectives: List<String>.from(json['objectives'] as List<dynamic>),
      );

  GradeBlock copyWith({
    String? gradeLabel,
    int? learnersMale,
    int? learnersFemale,
    String? subTheme,
    String? contentStandard,
    String? performanceStandard,
    List<String>? competencies,
    List<String>? objectives,
  }) =>
      GradeBlock(
        gradeLabel: gradeLabel ?? this.gradeLabel,
        learnersMale: learnersMale ?? this.learnersMale,
        learnersFemale: learnersFemale ?? this.learnersFemale,
        subTheme: subTheme ?? this.subTheme,
        contentStandard: contentStandard ?? this.contentStandard,
        performanceStandard: performanceStandard ?? this.performanceStandard,
        competencies: competencies ?? this.competencies,
        objectives: objectives ?? this.objectives,
      );
}

/// A stage in the lesson flow
class FlowStage {
  FlowStage({
    required this.minutes,
    required this.stage,
    required this.wholeClass,
    required this.activityByGrade,
    required this.wholeClassActivity,
  });

  final int minutes;
  final String stage;
  final bool wholeClass;
  final Map<String, String> activityByGrade;
  final String wholeClassActivity;

  Map<String, dynamic> toJson() => {
        'minutes': minutes,
        'stage': stage,
        'wholeClass': wholeClass,
        'activityByGrade': activityByGrade,
        'wholeClassActivity': wholeClassActivity,
      };

  factory FlowStage.fromJson(Map<String, dynamic> json) => FlowStage(
        minutes: json['minutes'] as int,
        stage: json['stage'] as String,
        wholeClass: json['wholeClass'] as bool,
        activityByGrade: Map<String, String>.from(
            json['activityByGrade'] as Map<String, dynamic>),
        wholeClassActivity: json['wholeClassActivity'] as String,
      );

  FlowStage copyWith({
    int? minutes,
    String? stage,
    bool? wholeClass,
    Map<String, String>? activityByGrade,
    String? wholeClassActivity,
  }) =>
      FlowStage(
        minutes: minutes ?? this.minutes,
        stage: stage ?? this.stage,
        wholeClass: wholeClass ?? this.wholeClass,
        activityByGrade: activityByGrade ?? this.activityByGrade,
        wholeClassActivity: wholeClassActivity ?? this.wholeClassActivity,
      );
}

/// Assessment for one grade level
class GradeAssessment {
  GradeAssessment({
    required this.gradeLabel,
    required this.formative,
    required this.exitTask,
    required this.successCriteria,
  });

  final String gradeLabel;
  final String formative;
  final String exitTask;
  final String successCriteria;

  Map<String, dynamic> toJson() => {
        'gradeLabel': gradeLabel,
        'formative': formative,
        'exitTask': exitTask,
        'successCriteria': successCriteria,
      };

  factory GradeAssessment.fromJson(Map<String, dynamic> json) =>
      GradeAssessment(
        gradeLabel: json['gradeLabel'] as String,
        formative: json['formative'] as String,
        exitTask: json['exitTask'] as String,
        successCriteria: json['successCriteria'] as String,
      );

  GradeAssessment copyWith({
    String? gradeLabel,
    String? formative,
    String? exitTask,
    String? successCriteria,
  }) =>
      GradeAssessment(
        gradeLabel: gradeLabel ?? this.gradeLabel,
        formative: formative ?? this.formative,
        exitTask: exitTask ?? this.exitTask,
        successCriteria: successCriteria ?? this.successCriteria,
      );
}

/// Remediation and enrichment pathways for one grade
class GradeWaysForward {
  GradeWaysForward({
    required this.gradeLabel,
    required this.remediation,
    required this.enrichment,
  });

  final String gradeLabel;
  final String remediation;
  final String enrichment;

  Map<String, dynamic> toJson() => {
        'gradeLabel': gradeLabel,
        'remediation': remediation,
        'enrichment': enrichment,
      };

  factory GradeWaysForward.fromJson(Map<String, dynamic> json) =>
      GradeWaysForward(
        gradeLabel: json['gradeLabel'] as String,
        remediation: json['remediation'] as String,
        enrichment: json['enrichment'] as String,
      );

  GradeWaysForward copyWith({
    String? gradeLabel,
    String? remediation,
    String? enrichment,
  }) =>
      GradeWaysForward(
        gradeLabel: gradeLabel ?? this.gradeLabel,
        remediation: remediation ?? this.remediation,
        enrichment: enrichment ?? this.enrichment,
      );
}

/// A reflection question, optionally targeted to one grade
class ReflectionQuestion {
  ReflectionQuestion({
    required this.gradeLabel,
    required this.text,
  });

  final String? gradeLabel; // null means whole-class
  final String text;

  Map<String, dynamic> toJson() => {
        'gradeLabel': gradeLabel,
        'text': text,
      };

  factory ReflectionQuestion.fromJson(Map<String, dynamic> json) =>
      ReflectionQuestion(
        gradeLabel: json['gradeLabel'] as String?,
        text: json['text'] as String,
      );

  ReflectionQuestion copyWith({
    String? gradeLabel,
    String? text,
  }) =>
      ReflectionQuestion(
        gradeLabel: gradeLabel ?? this.gradeLabel,
        text: text ?? this.text,
      );
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
      };

  factory LessonPlan.fromJson(Map<String, dynamic> json) => LessonPlan(
        header: PlanHeader.fromJson(json['header'] as Map<String, dynamic>),
        grades: (json['grades'] as List<dynamic>)
            .map((g) => GradeBlock.fromJson(g as Map<String, dynamic>))
            .toList(),
        sharedSubTheme: json['sharedSubTheme'] as String,
        bothGradesObjective: json['bothGradesObjective'] as String,
        learnerContext: json['learnerContext'] as String,
        materials: List<String>.from(json['materials'] as List<dynamic>),
        references: List<String>.from(json['references'] as List<dynamic>),
        flow: (json['flow'] as List<dynamic>)
            .map((s) => FlowStage.fromJson(s as Map<String, dynamic>))
            .toList(),
        assessments: (json['assessments'] as List<dynamic>)
            .map((a) => GradeAssessment.fromJson(a as Map<String, dynamic>))
            .toList(),
        reflectionQuestions: (json['reflectionQuestions'] as List<dynamic>)
            .map((r) => ReflectionQuestion.fromJson(r as Map<String, dynamic>))
            .toList(),
        waysForward: (json['waysForward'] as List<dynamic>)
            .map((w) => GradeWaysForward.fromJson(w as Map<String, dynamic>))
            .toList(),
        notesNextSession: json['notesNextSession'] as String,
        preparedBy: json['preparedBy'] as String,
        checkedBy: json['checkedBy'] as String,
        aiUseDeclaration: json['aiUseDeclaration'] as String,
      );

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
