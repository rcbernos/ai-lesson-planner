/// Section patching extension for LessonPlan.
/// Allows replacing one section or a grade's slice from another plan during regeneration.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

extension PlanSectionPatch on LessonPlan {
  /// Returns a copy of this plan with the given section (or one grade's slice of it)
  /// taken from [source].
  ///
  /// Throws [ArgumentError] if [gradeLabel] is not in both this plan and source,
  /// or if a cell-level patch finds a different number of flow stages in [source].
  LessonPlan replaceSection(
    PlanSection section,
    LessonPlan source, {
    String? gradeLabel,
  }) {
    // Validate gradeLabel if provided
    if (gradeLabel != null) {
      final thisHasGrade = grades.any((g) => g.gradeLabel == gradeLabel);
      final sourceHasGrade =
          source.grades.any((g) => g.gradeLabel == gradeLabel);
      if (!thisHasGrade) {
        throw ArgumentError(
            'Grade label "$gradeLabel" not found in source plan');
      }
      if (!sourceHasGrade) {
        throw ArgumentError(
            'Grade label "$gradeLabel" not found in source plan');
      }
    }

    switch (section) {
      case PlanSection.header:
        return this; // Header is teacher input, never overwritten

      case PlanSection.intentions:
        return _replaceIntentions(source, gradeLabel: gradeLabel);

      case PlanSection.learningExperiences:
        return _replaceLearningExperiences(source, gradeLabel: gradeLabel);

      case PlanSection.assessment:
        return _replaceAssessment(source, gradeLabel: gradeLabel);

      case PlanSection.waysForward:
        return _replaceWaysForward(source, gradeLabel: gradeLabel);
    }
  }

  /// Replaces objectives from source, preserving grounded fields.
  LessonPlan _replaceIntentions(
    LessonPlan source, {
    String? gradeLabel,
  }) {
    final newGrades = gradeLabel == null
        ? _replaceIntentionsFull(source)
        : _replaceIntentionsSlice(source, gradeLabel: gradeLabel);

    return copyWith(
        grades: newGrades, bothGradesObjective: source.bothGradesObjective);
  }

  List<GradeBlock> _replaceIntentionsFull(LessonPlan source) {
    final sourceByLabel = {for (final g in source.grades) g.gradeLabel: g};
    return grades.map((g) {
      final sourceGrade = sourceByLabel[g.gradeLabel];
      final newObjectives = sourceGrade != null
          ? List<String>.from(sourceGrade.objectives)
          : List<String>.from(g.objectives);
      return GradeBlock(
        gradeLabel: g.gradeLabel,
        learnersMale: g.learnersMale,
        learnersFemale: g.learnersFemale,
        subTheme: g.subTheme,
        contentStandard: g.contentStandard,
        performanceStandard: g.performanceStandard,
        competencies: List<String>.from(g.competencies),
        objectives: newObjectives,
      );
    }).toList();
  }

  List<GradeBlock> _replaceIntentionsSlice(LessonPlan source,
      {required String gradeLabel}) {
    final sourceGrade =
        source.grades.firstWhere((g) => g.gradeLabel == gradeLabel);
    return grades.map((g) {
      final newObjectives = g.gradeLabel == gradeLabel
          ? List<String>.from(sourceGrade.objectives)
          : List<String>.from(g.objectives);
      return GradeBlock(
        gradeLabel: g.gradeLabel,
        learnersMale: g.learnersMale,
        learnersFemale: g.learnersFemale,
        subTheme: g.subTheme,
        contentStandard: g.contentStandard,
        performanceStandard: g.performanceStandard,
        competencies: List.from(g.competencies),
        objectives: newObjectives,
      );
    }).toList();
  }

  /// Replaces learning experiences from source.
  LessonPlan _replaceLearningExperiences(
    LessonPlan source, {
    String? gradeLabel,
  }) {
    if (gradeLabel == null) {
      return copyWith(
        learnerContext: source.learnerContext,
        materials: List.from(source.materials),
        flow: _cloneFlowStages(source.flow),
      );
    }
    // Grade slice: update only activityByGrade and competencyIndexByGrade
    if (source.flow.length != flow.length) {
      throw ArgumentError(
          'Source has ${source.flow.length} stages, expected ${flow.length}');
    }
    final newFlow = List<FlowStage>.from(
      flow.asMap().entries.map((e) {
        final i = e.key;
        final oldStage = e.value;
        final newStage = source.flow[i];
        final newActivityByGrade =
            Map<String, String>.from(oldStage.activityByGrade);
        newActivityByGrade[gradeLabel] =
            newStage.activityByGrade[gradeLabel] ?? '';
        final newCompetencyIndexByGrade =
            Map<String, int>.from(oldStage.competencyIndexByGrade);
        newCompetencyIndexByGrade[gradeLabel] =
            newStage.competencyIndexByGrade[gradeLabel] ?? 0;
        return FlowStage(
          minutes: oldStage.minutes,
          stage: oldStage.stage,
          wholeClass: oldStage.wholeClass,
          activityByGrade: newActivityByGrade,
          wholeClassActivity: oldStage.wholeClassActivity,
          competencyIndexByGrade: newCompetencyIndexByGrade,
        );
      }),
    );
    return copyWith(flow: newFlow);
  }

  /// Clones flow stages to avoid shared references.
  List<FlowStage> _cloneFlowStages(List<FlowStage> stages) {
    return stages
        .map((s) => FlowStage(
              minutes: s.minutes,
              stage: s.stage,
              wholeClass: s.wholeClass,
              activityByGrade: Map.from(s.activityByGrade),
              wholeClassActivity: s.wholeClassActivity,
              competencyIndexByGrade: Map.from(s.competencyIndexByGrade),
            ))
        .toList();
  }

  /// Replaces assessment from source.
  LessonPlan _replaceAssessment(
    LessonPlan source, {
    String? gradeLabel,
  }) {
    if (gradeLabel == null) {
      return copyWith(assessments: _cloneAssessments(source.assessments));
    }
    // Grade slice: replace or append the matching assessment
    final newAssessments = List<GradeAssessment>.from(assessments);
    final sourceAssessment = source.assessments.firstWhere(
      (a) => a.gradeLabel == gradeLabel,
      orElse: () => GradeAssessment(
        gradeLabel: gradeLabel,
        formative: '',
        exitTask: '',
        successCriteria: '',
      ),
    );
    final existingIndex =
        newAssessments.indexWhere((a) => a.gradeLabel == gradeLabel);
    if (existingIndex >= 0) {
      newAssessments[existingIndex] = _cloneAssessment(sourceAssessment);
    } else {
      newAssessments.add(_cloneAssessment(sourceAssessment));
    }
    return copyWith(assessments: newAssessments);
  }

  /// Clones assessments to avoid shared references.
  List<GradeAssessment> _cloneAssessments(List<GradeAssessment> assessments) {
    return assessments.map(_cloneAssessment).toList();
  }

  GradeAssessment _cloneAssessment(GradeAssessment a) => GradeAssessment(
        gradeLabel: a.gradeLabel,
        formative: a.formative,
        exitTask: a.exitTask,
        successCriteria: a.successCriteria,
        competencyIndex: a.competencyIndex,
      );

  /// Replaces ways forward from source.
  LessonPlan _replaceWaysForward(
    LessonPlan source, {
    String? gradeLabel,
  }) {
    if (gradeLabel == null) {
      return copyWith(
        waysForward: _cloneGradeWaysForward(source.waysForward),
        reflectionQuestions: List.from(source.reflectionQuestions),
        notesNextSession: source.notesNextSession,
      );
    }
    // Grade slice: keep whole-class reflection questions, replace grade-specific ones
    final sourceByLabel = {for (final w in source.waysForward) w.gradeLabel: w};
    final newWaysForward = grades.map((g) {
      final wf = sourceByLabel[g.gradeLabel];
      if (wf != null) {
        return GradeWaysForward(
          gradeLabel: wf.gradeLabel,
          remediation: wf.remediation,
          enrichment: wf.enrichment,
        );
      }
      // Keep existing if source lacks this grade
      return GradeWaysForward(
          gradeLabel: g.gradeLabel, remediation: '', enrichment: '');
    }).toList();
    // Keep whole-class questions from this, add source's questions for the grade
    final wholeClassQuestions =
        reflectionQuestions.where((q) => q.gradeLabel == null).toList();
    final sourceGradeQuestions = source.reflectionQuestions
        .where((q) => q.gradeLabel == gradeLabel)
        .toList();
    final newQuestions = [...wholeClassQuestions, ...sourceGradeQuestions];
    return copyWith(
      waysForward: newWaysForward,
      reflectionQuestions: newQuestions,
    );
  }

  /// Clones GradeWaysForward objects.
  List<GradeWaysForward> _cloneGradeWaysForward(List<GradeWaysForward> list) {
    return list
        .map((w) => GradeWaysForward(
              gradeLabel: w.gradeLabel,
              remediation: w.remediation,
              enrichment: w.enrichment,
            ))
        .toList();
  }
}
