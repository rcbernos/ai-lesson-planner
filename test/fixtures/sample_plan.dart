/// Sample lesson plan fixture for testing.
/// Uses fictional names per project guidelines.
library;

import 'package:ai_lesson_planner/core/models/lesson_plan.dart';

/// Creates a sample LessonPlan fixture based on a Grade 3/4 Filipino DLP.
/// All names and content are fictional.
LessonPlan createSamplePlan() => LessonPlan(
      header: PlanHeader(
        school: 'Sampaguita Elementary School',
        teacher: 'Maria Santos',
        learningArea: 'FILIPINO',
        date: '2026-08-04',
        term: 'Term 1',
        sessions: 1,
        sessionMinutes: 90,
        multigradeModel: 'Same Theme, Different Task (STDT)',
      ),
      grades: [
        GradeBlock(
          gradeLabel: 'Grade 3',
          learnersMale: 3,
          learnersFemale: 3,
          subTheme: 'Pag-iisa-isa at paglalarawan',
          contentStandard: 'Naipamamalas ng mag-aaral unawa sa teksto.',
          performanceStandard: 'Nagagamit ang mga salitang naglalarawan.',
          competencies: [
            'Natutukoy ang mga salitang naglalarawan',
            'Nakapagpapahayag ng ideya gamit paglalarawan',
          ],
          objectives: [
            'Natutukoy ang mga salitang naglalarawan.',
            'Nakapagbibigay ng payak na paglalarawan.',
          ],
        ),
        GradeBlock(
          gradeLabel: 'Grade 4',
          learnersMale: 1,
          learnersFemale: 0,
          subTheme: 'Pangatnig sa teksto',
          contentStandard: 'Naipamamalas unawa sa teksto at gramar.',
          performanceStandard: 'Nagagamit ang pangatnig sa pagsulat.',
          competencies: [
            'Nakikilala ang pangunahing ideya',
            'Nagagamit ang pangatnig',
          ],
          objectives: [
            'Natutukoy ang pangunahing ideya.',
            'Nakagagamit ang pangatnig.',
          ],
        ),
      ],
      sharedSubTheme: 'Ulat-panahon at paghahanda sa sakuna',
      bothGradesObjective:
          'Nauunawaan ang ulat-panahon at nakapagpapahayag ng ideya.',
      learnerContext:
          'Ang mga mag-aaral ay nakatira sa pamayanang daanan ng bagyo.',
      materials: [
        'Mga larawan ng panahon',
        'Activity sheet',
      ],
      references: ['DepEd Curriculum Guide'],
      flow: [
        FlowStage(
          minutes: 10,
          stage: 'Motivation',
          wholeClass: true,
          activityByGrade: {},
          wholeClassActivity: 'Ipakita ang larawan ng ulan.',
        ),
        FlowStage(
          minutes: 15,
          stage: 'Direct Teaching',
          wholeClass: false,
          activityByGrade: {
            'Grade 3': 'Basahin at ilarawan ang panahon.',
            'Grade 4': 'Bilugan ang mga pangatnig.',
          },
          wholeClassActivity: '',
        ),
        FlowStage(
          minutes: 10,
          stage: 'Practice',
          wholeClass: false,
          activityByGrade: {
            'Grade 3': 'Magbighani ng paglalarawan.',
            'Grade 4': 'Isulat ang liham.',
          },
          wholeClassActivity: '',
        ),
        FlowStage(
          minutes: 20,
          stage: 'Activity',
          wholeClass: false,
          activityByGrade: {
            'Grade 3': 'Gawin ang activity sheet.',
            'Grade 4': 'Punan ang patlang.',
          },
          wholeClassActivity: '',
        ),
        FlowStage(
          minutes: 25,
          stage: 'Application',
          wholeClass: false,
          activityByGrade: {
            'Grade 3': 'Iguhit ang larawan.',
            'Grade 4': 'Gamitin ang pangatnig.',
          },
          wholeClassActivity: '',
        ),
        FlowStage(
          minutes: 10,
          stage: 'Wrap-up',
          wholeClass: true,
          activityByGrade: {},
          wholeClassActivity: 'Ipagpakita ang huling larawan.',
        ),
      ],
      assessments: [
        GradeAssessment(
          gradeLabel: 'Grade 3',
          formative: 'Obserbahan ang pakikilahok.',
          exitTask: 'Isulat ang paglalarawan.',
          successCriteria: 'Nailalarawan ang panahon.',
        ),
        GradeAssessment(
          gradeLabel: 'Grade 4',
          formative: 'Obserbahan ang pangatnig.',
          exitTask: 'Punan ang patlang.',
          successCriteria: 'Nakagagamit ang pangatnig.',
        ),
      ],
      reflectionQuestions: [
        ReflectionQuestion(
          gradeLabel: 'Grade 3',
          text: 'Ano ang inilalarawan mo?',
        ),
        ReflectionQuestion(
          gradeLabel: 'Grade 4',
          text: 'Anong pangatnig?',
        ),
        ReflectionQuestion(
          gradeLabel: null,
          text: 'Kumusta ang aralin?',
        ),
      ],
      waysForward: [
        GradeWaysForward(
          gradeLabel: 'Grade 3',
          remediation: 'Muling basahin.',
          enrichment: 'Maghanap ng iba.',
        ),
        GradeWaysForward(
          gradeLabel: 'Grade 4',
          remediation: 'Magsanay.',
          enrichment: 'Gamitin nang higit.',
        ),
      ],
      notesNextSession: 'Ipagpatuloy sa susunod.',
      preparedBy: 'Maria Santos',
      checkedBy: 'Juan Dela Cruz',
      aiUseDeclaration: defaultAiUseDeclaration,
    );
