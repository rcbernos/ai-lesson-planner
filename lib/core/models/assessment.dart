part of 'lesson_plan.dart';

/// Assessment for one grade level
class GradeAssessment {
  GradeAssessment({
    required this.gradeLabel,
    required this.formative,
    required this.exitTask,
    required this.successCriteria,
    this.competencyIndex,
  });

  final String gradeLabel;
  final String formative;
  final String exitTask;
  final String successCriteria;
  final int? competencyIndex;

  Map<String, dynamic> toJson() => {
        'gradeLabel': gradeLabel,
        'formative': formative,
        'exitTask': exitTask,
        'successCriteria': successCriteria,
        'competencyIndex': competencyIndex,
      };

  factory GradeAssessment.fromJson(Map<String, dynamic> json) =>
      GradeAssessment(
        gradeLabel: json['gradeLabel'] as String,
        formative: json['formative'] as String,
        exitTask: json['exitTask'] as String,
        successCriteria: json['successCriteria'] as String,
        competencyIndex: json['competencyIndex'] as int?,
      );

  GradeAssessment copyWith({
    String? gradeLabel,
    String? formative,
    String? exitTask,
    String? successCriteria,
    int? competencyIndex,
  }) =>
      GradeAssessment(
        gradeLabel: gradeLabel ?? this.gradeLabel,
        formative: formative ?? this.formative,
        exitTask: exitTask ?? this.exitTask,
        successCriteria: successCriteria ?? this.successCriteria,
        competencyIndex: competencyIndex ?? this.competencyIndex,
      );
}
