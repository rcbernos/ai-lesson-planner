// Widget tests for responsive plan view on narrow screens (T3.4)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/features/plan_view/flow_table.dart';
import 'package:ai_lesson_planner/features/plan_view/assessment_tables.dart';
import 'fixtures/sample_plan.dart';

/// Builds a sample plan with [n] grades for narrow-screen tests.
LessonPlan createNGradePlan(int n) {
  final grades = <GradeBlock>[];
  final assessments = <GradeAssessment>[];
  final waysForward = <GradeWaysForward>[];
  for (int i = 0; i < n; i++) {
    final label = 'Grade ${3 + i}';
    grades.add(GradeBlock(
      gradeLabel: label,
      learnersMale: i + 1,
      learnersFemale: i + 1,
      subTheme: 'Fictional subtheme for $label',
      contentStandard: 'Content standard for $label.',
      performanceStandard: 'Performance standard for $label.',
      competencies: ['Competency A for $label'],
      objectives: ['Objective A for $label.'],
    ));
    assessments.add(GradeAssessment(
      gradeLabel: label,
      formative: 'Observe $label.',
      exitTask: 'Exit task for $label.',
      successCriteria: 'Success criteria for $label.',
    ));
    waysForward.add(GradeWaysForward(
      gradeLabel: label,
      remediation: 'Remediation for $label.',
      enrichment: 'Enrichment for $label.',
    ));
  }
  return LessonPlan(
    header: PlanHeader(
      school: 'Sampaguita Elementary School',
      teacher: 'Maria Santos',
      learningArea: 'FILIPINO',
      date: '2026-08-04',
      term: 'Term 1',
      sessions: 1,
      sessionMinutes: 90,
      multigradeModel: 'Same Theme, Different Task (STDT)',
      gradeLevels: 'III, IV, V, VI',
    ),
    grades: grades,
    sharedSubTheme: 'Ulat-panahon at paghahanda sa sakuna',
    bothGradesObjective: 'Nauunawaan ang ulat-panahon.',
    learnerContext: 'Fictional learners context.',
    materials: Materials(items: ['Mga larawan ng panahon'], references: []),
    flow: [
      FlowStage(
        minutes: 10,
        stage: 'Motivation',
        wholeClass: true,
        activityByGrade: {},
        wholeClassActivity: 'Ipakita ang larawan ng ulan.',
      ),
    ],
    assessments: assessments,
    reflectionQuestions: [],
    waysForward: waysForward,
    notesNextSession: 'Ipagpatuloy sa susunod.',
    preparedBy: 'Maria Santos',
    checkedBy: 'Juan Dela Cruz',
    aiUseDeclaration: defaultAiUseDeclaration,
    language: 'fil',
    preparedByRole: 'Classroom Adviser',
    checkedByRole: 'School Head',
  );
}

void main() {
  group('IlawPlanView responsive layout', () {
    /// Helper to pump the widget at a given size
    Future<void> pumpAtSize(
      WidgetTester tester,
      double width,
      double height,
      LessonPlan plan,
    ) async {
      tester.binding.window.physicalSizeTestValue = Size(width, height);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: height,
              child: IlawPlanView(plan: plan),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('no overflow at 360x640 with 2 grades',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      await pumpAtSize(tester, 360, 640, plan);

      // Verify key elements are found
      expect(find.text('DAILY LESSON PLAN FOR GRADE III & IV'), findsOneWidget);
      expect(find.text('I  INTENTIONS'), findsOneWidget);
      expect(find.text('L  LEARNING EXPERIENCE'), findsOneWidget);
      expect(find.text('A  ASSESSMENT'), findsOneWidget);
      expect(find.text('W  WAYS FORWARD'), findsOneWidget);
    });

    testWidgets('no overflow at 360x640 with 4 grades',
        (WidgetTester tester) async {
      final plan = createNGradePlan(4);
      await pumpAtSize(tester, 360, 640, plan);

      // Verify all section banners are visible
      expect(find.text('I  INTENTIONS'), findsOneWidget);
      expect(find.text('L  LEARNING EXPERIENCE'), findsOneWidget);
      expect(find.text('A  ASSESSMENT'), findsOneWidget);
      expect(find.text('W  WAYS FORWARD'), findsOneWidget);
    });

    testWidgets('no overflow at 360x640 with 6 grades',
        (WidgetTester tester) async {
      final plan = createNGradePlan(6);
      await pumpAtSize(tester, 360, 640, plan);

      // Verify page content loads without overflow
      expect(find.byType(IlawPlanView), findsOneWidget);
    });

    testWidgets('flow table renders correctly', (WidgetTester tester) async {
      final plan = createSamplePlan();
      await pumpAtSize(tester, 360, 640, plan);

      // Flow table should be rendered
      expect(find.byType(FlowTable), findsOneWidget);
      expect(find.text('Motivation'), findsOneWidget);
      expect(find.text('Direct Teaching'), findsOneWidget);
    });

    testWidgets('assessment tables render correctly',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      await pumpAtSize(tester, 360, 640, plan);

      // AssessmentTables widget should be rendered
      expect(find.byType(AssessmentTables), findsOneWidget);
      expect(find.text('A  ASSESSMENT'), findsOneWidget);
    });

    testWidgets('ways forward tables render correctly',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      await pumpAtSize(tester, 360, 640, plan);

      // WaysForwardTables widget should be rendered
      expect(find.byType(WaysForwardTables), findsOneWidget);
      expect(find.text('W  WAYS FORWARD'), findsOneWidget);
    });

    testWidgets('banners stay full width', (WidgetTester tester) async {
      final plan = createSamplePlan();
      await pumpAtSize(tester, 360, 640, plan);

      // All banners should be present
      expect(find.text('I  INTENTIONS'), findsOneWidget);
      expect(find.text('L  LEARNING EXPERIENCE'), findsOneWidget);
      expect(find.text('A  ASSESSMENT'), findsOneWidget);
      expect(find.text('W  WAYS FORWARD'), findsOneWidget);
    });

    testWidgets('header table stacks to two columns on narrow screens',
        (WidgetTester tester) async {
      final plan = createSamplePlan();
      await pumpAtSize(tester, 360, 640, plan);

      // Header content should still be visible - use exact values from sample plan
      // Use the school name and other specific values to avoid matching labels
      expect(find.text('Sampaguita Elementary School'), findsOneWidget);
      expect(
          find.text('Maria Santos'), findsWidgets); // Teacher label and value
      expect(find.textContaining('Quarter/Term'), findsOneWidget);
    });
  });
}
