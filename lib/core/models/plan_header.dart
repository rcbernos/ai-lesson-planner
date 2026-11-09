part of 'lesson_plan.dart';

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
    this.gradeLevels = '',
  });

  final String school;
  final String teacher;
  final String learningArea;
  final String date;
  final String term;
  final int sessions;
  final int sessionMinutes;
  final String multigradeModel;
  final String gradeLevels;

  Map<String, dynamic> toJson() => {
        'school': school,
        'teacher': teacher,
        'learningArea': learningArea,
        'date': date,
        'term': term,
        'sessions': sessions,
        'sessionMinutes': sessionMinutes,
        'multigradeModel': multigradeModel,
        'gradeLevels': gradeLevels,
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
        gradeLevels: json['gradeLevels'] as String? ?? '',
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
    String? gradeLevels,
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
        gradeLevels: gradeLevels ?? this.gradeLevels,
      );
}
