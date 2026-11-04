part of 'lesson_plan.dart';

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
