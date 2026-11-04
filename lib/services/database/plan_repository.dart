/// Repository for saving, loading, and deleting lesson plans.
/// Wraps Drift database operations with JSON serialization.
library;

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:drift/drift.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart' as lp;
import 'package:ai_lesson_planner/services/database/app_database.dart';
import 'package:ai_lesson_planner/services/database/database_helper.dart';

/// Metadata extracted from a saved plan for listing in the library.
class SavedPlanInfo {
  SavedPlanInfo({
    required this.id,
    required this.title,
    required this.date,
    required this.gradeLevels,
    required this.subject,
  });

  final int id;
  final String title;
  final String date;
  final String gradeLevels;
  final String subject;
}

/// Repository for persisting and retrieving lesson plans.
class PlanRepository {
  PlanRepository([AppDatabase? db]) : _db = db ?? DatabaseHelper.instance.db;
  final AppDatabase _db;

  /// Saves a lesson plan to the database.
  /// Generates a title from plan metadata.
  Future<int> savePlan(lp.LessonPlan plan) async {
    final title = _generateTitle(plan);
    final gradeLevel = _extractGradeLevel(plan);
    final subject = plan.header.learningArea;

    return await _db.insertLessonPlan(LessonPlansCompanion.insert(
      title: title,
      gradeLevel: Value(gradeLevel),
      subject: Value(subject),
      ilawContent: Value(jsonEncode(plan.toJson())),
      status: const Value('saved'),
    ));
  }

  /// Loads all saved plans with their metadata.
  Future<List<SavedPlanInfo>> getAllSavedPlans() async {
    final plans = await _db.getAllLessonPlans();
    return plans
        .map((plan) {
          final jsonStr = plan.ilawContent;
          if (jsonStr == null) {
            return null;
          }
          final decoded = lp.LessonPlan.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
          return SavedPlanInfo(
            id: plan.id,
            title: _generateTitle(decoded),
            date: plan.createdAt.toIso8601String().split('T').first,
            gradeLevels: _gradeLevelsToString(
                decoded.grades.map((g) => g.gradeLabel).toList()),
            subject: decoded.header.learningArea,
          );
        })
        .whereType<SavedPlanInfo>()
        .toList();
  }

  /// Retrieves a specific lesson plan by ID.
  Future<lp.LessonPlan?> getPlanById(int id) async {
    final plan = await _db.getLessonPlanById(id);
    if (plan == null) return null;

    final jsonStr = plan.ilawContent;
    if (jsonStr == null) return null;

    return lp.LessonPlan.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  /// Deletes a lesson plan by ID.
  Future<void> deletePlan(int id) async {
    await _db.deleteLessonPlan(id);
  }

  /// Updates an existing lesson plan in the database.
  /// Rewrites ilawContent and keeps title, gradeLevel, subject and updatedAt
  /// in step with the plan. Preserves original createdAt.
  Future<bool> update(int id, lp.LessonPlan plan) async {
    final title = _generateTitle(plan);
    final gradeLevel = _extractGradeLevel(plan);
    final subject = plan.header.learningArea;

    // Use update with companion to only update specified fields,
    // preserving createdAt from the original record
    final affectedRows = await (_db.update(_db.lessonPlans)
          ..where((t) => t.id.equals(id)))
        .write(
      LessonPlansCompanion(
        title: Value(title),
        gradeLevel: Value(gradeLevel),
        subject: Value(subject),
        ilawContent: Value(jsonEncode(plan.toJson())),
        status: const Value('saved'),
        updatedAt: Value(DateTime.now()),
        // createdAt is not set, so it's preserved
      ),
    );

    return affectedRows > 0;
  }

  /// Generates a title from plan metadata.
  /// Format: "Grades {min}-{max} {Subject} - {SubTheme}"
  String _generateTitle(lp.LessonPlan plan) {
    final grades = plan.grades.map((g) => g.gradeLabel).toList();
    final gradeLevels = _gradeLevelsToString(grades);
    final subTheme = _firstWord(plan.sharedSubTheme);
    final subject = plan.header.learningArea;

    return '$gradeLevels $subject - $subTheme';
  }

  /// Extracts the primary grade level from the plan.
  int _extractGradeLevel(lp.LessonPlan plan) {
    if (plan.grades.isEmpty) return 0;
    final firstGrade = plan.grades.first.gradeLabel;
    final match = RegExp(r'Grade\s+(\d+)').firstMatch(firstGrade);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Converts grade labels to a range string.
  String _gradeLevelsToString(List<String> grades) {
    if (grades.isEmpty) return 'Unknown';
    if (grades.length == 1) return grades.first.split(' ').last;

    final numbers = grades
        .map((g) => int.tryParse(g.split(' ').last) ?? 0)
        .toList()
      ..sort();

    if (numbers.length == 2 && numbers[1] - numbers[0] == 1) {
      return '${numbers.first} & ${numbers.last}';
    }

    return '${numbers.first}-${numbers.last}';
  }

  /// Returns the first word of a string.
  String _firstWord(String text) {
    return text.split(' ').first;
  }
}
