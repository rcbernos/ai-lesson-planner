part of 'lesson_plan.dart';

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
    bool clearGradeLabel = false,
  }) =>
      ReflectionQuestion(
        gradeLabel: clearGradeLabel ? null : (gradeLabel ?? this.gradeLabel),
        text: text ?? this.text,
      );
}
