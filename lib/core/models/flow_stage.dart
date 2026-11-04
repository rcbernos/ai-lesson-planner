part of 'lesson_plan.dart';

/// A stage in the lesson flow
class FlowStage {
  FlowStage({
    required this.minutes,
    required this.stage,
    required this.wholeClass,
    required this.activityByGrade,
    required this.wholeClassActivity,
    this.competencyIndexByGrade = const {},
  });

  final int minutes;
  final String stage;
  final bool wholeClass;
  final Map<String, String> activityByGrade;
  final String wholeClassActivity;
  final Map<String, int> competencyIndexByGrade;

  Map<String, dynamic> toJson() => {
        'minutes': minutes,
        'stage': stage,
        'wholeClass': wholeClass,
        'activityByGrade': activityByGrade,
        'wholeClassActivity': wholeClassActivity,
        'competencyIndexByGrade': competencyIndexByGrade,
      };

  factory FlowStage.fromJson(Map<String, dynamic> json) => FlowStage(
        minutes: json['minutes'] as int,
        stage: json['stage'] as String,
        wholeClass: json['wholeClass'] as bool,
        activityByGrade: Map<String, String>.from(
            json['activityByGrade'] as Map<String, dynamic>),
        wholeClassActivity: json['wholeClassActivity'] as String,
        competencyIndexByGrade: Map<String, int>.from(
            (json['competencyIndexByGrade'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as int)) ??
                const {}),
      );

  FlowStage copyWith({
    int? minutes,
    String? stage,
    bool? wholeClass,
    Map<String, String>? activityByGrade,
    String? wholeClassActivity,
    Map<String, int>? competencyIndexByGrade,
  }) =>
      FlowStage(
        minutes: minutes ?? this.minutes,
        stage: stage ?? this.stage,
        wholeClass: wholeClass ?? this.wholeClass,
        activityByGrade: activityByGrade ?? this.activityByGrade,
        wholeClassActivity: wholeClassActivity ?? this.wholeClassActivity,
        competencyIndexByGrade:
            competencyIndexByGrade ?? this.competencyIndexByGrade,
      );
}
