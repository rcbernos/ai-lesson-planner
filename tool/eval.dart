#!/usr/bin/env dart

// Evaluation harness for T5.9
import 'dart:convert';
import 'dart:io';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/llm_lesson_generator.dart';
import 'package:ai_lesson_planner/core/generation/section_runner.dart';
import 'package:ai_lesson_planner/core/llm/fake_engine.dart';
import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/validation/plan_validator.dart';

Future<void> main(List<String> args) async {
  final endpoint = args.isNotEmpty && args[0] == '--endpoint' && args.length > 1
      ? args[1]
      : null;
  stdout.writeln('=== Evaluation Harness T5.9 ===\n');
  stdout.writeln('Endpoint: ${endpoint ?? 'FakeEngine'}');
  stdout.writeln('Seed: 42\n');

  final requests = await _loadRequests();
  final results = <_EvalResult>[];

  for (final req in requests) {
    stdout.writeln('Running: ${req.name}...');
    final result = await _runRequest(req, endpoint);
    results.add(result);
    stdout.writeln(
      '  ${result.status == EvalStatus.pass ? 'PASS' : 'FAIL'} '
      '(${result.passRate}%, ${result.errorCount} errors)',
    );
  }

  _printResultsTable(results);
  _writeResultsMd(results);
  stdout.writeln('\nResults written to working_docs/eval_results.md');
}

Future<List<_EvalRequest>> _loadRequests() async {
  final file = File('test/eval/requests.json');
  if (!file.existsSync()) {
    stderr.writeln('ERROR: test/eval/requests.json not found');
    exit(1);
  }
  final content = await file.readAsString();
  final List<dynamic> json = jsonDecode(content);
  return json.map((j) => _EvalRequest.fromJson(j)).toList();
}

Future<_EvalResult> _runRequest(_EvalRequest req, String? endpoint) async {
  late LlmLessonGenerator generator;
  if (endpoint != null) {
    stderr.writeln(
      'ERROR: HttpLlmEngine not implemented. Use FakeEngine mode.',
    );
    exit(1);
  }
  final engine = FakeEngine(
    useFullKey: true,
    tokenSequences: _buildTokenSequences(req.request!),
  );
  await engine.load(
    ModelSpec(path: '/fake/model.gguf', contextSize: 2048, threads: 4),
  );
  generator = LlmLessonGenerator(engine: engine, seed: 42);
  try {
    final request = _buildGenerationRequest(req.request!);
    final events = <GenerationEvent>[];
    await for (final event in generator.generate(request)) {
      events.add(event);
    }
    final completed = events.whereType<GenerationCompleted>().firstOrNull;
    if (completed == null) {
      return _EvalResult(
        requestId: req.id,
        name: req.name,
        status: EvalStatus.fail,
        errorCount: 1,
        errorCodes: ['GENERATION_FAILED'],
        passRate: 0,
      );
    }
    final issues = PlanValidator().validate(completed.plan);
    final errorCodes = issues
        .where((i) => i.severity.name == 'error')
        .map((e) => e.code)
        .toSet()
        .toList();
    final errorCount = errorCodes.length;
    return _EvalResult(
      requestId: req.id,
      name: req.name,
      status: errorCount == 0 ? EvalStatus.pass : EvalStatus.fail,
      errorCount: errorCount,
      errorCodes: errorCodes,
      passRate: ((issues.length - errorCount) / issues.length * 100).round(),
    );
  } catch (e) {
    return _EvalResult(
      requestId: req.id,
      name: req.name,
      status: EvalStatus.fail,
      errorCount: 1,
      errorCodes: ['EXCEPTION: $e'],
      passRate: 0,
    );
  } finally {
    await engine.dispose();
  }
}

GenerationRequest _buildGenerationRequest(Map<String, dynamic> data) {
  final headerData = data['header'] as Map<String, dynamic>;
  final gradesData = (data['grades'] as List).cast<Map<String, dynamic>>();
  final grades = gradesData
      .map(
        (g) => GradeInput(
          gradeLabel: g['gradeLabel'] as String,
          male: g['male'] as int,
          female: g['female'] as int,
          subTheme: g['subTheme'] as String,
          competency: g['competency'] as String,
        ),
      )
      .toList();
  return GenerationRequest(
    header: PlanHeader(
      school: headerData['school'] as String,
      teacher: headerData['teacher'] as String,
      learningArea: headerData['learningArea'] as String,
      date: headerData['date'] as String,
      term: headerData['term'] as String,
      sessions: headerData['sessions'] as int,
      sessionMinutes: headerData['sessionMinutes'] as int,
      multigradeModel: headerData['multigradeModel'] as String,
      gradeLevels: headerData['gradeLevels'] as String,
    ),
    grades: grades,
    sharedSubTheme: data['sharedSubTheme'] as String,
    language: (data['language'] as String) == 'filipino'
        ? OutputLanguage.filipino
        : OutputLanguage.english,
  );
}

void _printResultsTable(List<_EvalResult> results) {
  stdout.writeln('\n--- Results Table ---\n');
  stdout.writeln('| ID | Name | Status | Errors | Pass Rate |');
  stdout.writeln('|----|------|--------|--------|-------------|');
  for (final r in results) {
    final status = r.status == EvalStatus.pass ? 'PASS' : 'FAIL';
    stdout.writeln(
      '| ${r.requestId} | ${r.name} | $status | ${r.errorCount} | ${r.passRate}% |',
    );
  }
  final passCount = results.where((r) => r.status == EvalStatus.pass).length;
  stdout.writeln('\n**Summary: $passCount / ${results.length} passed\n');
}

void _writeResultsMd(List<_EvalResult> results) {
  final passCount = results.where((r) => r.status == EvalStatus.pass).length;
  final buffer = StringBuffer()
    ..writeln('# Evaluation Results T5.9')
    ..writeln('')
    ..writeln('**Date:** ${DateTime.now().toIso8601String().split('T').first}')
    ..writeln('**Engine:** FakeEngine (testing mode)')
    ..writeln('**Seed:** 42')
    ..writeln('')
    ..writeln('## Summary')
    ..writeln('- Total requests: ${results.length}')
    ..writeln('- Passed: $passCount')
    ..writeln('- Failed: ${results.length - passCount}')
    ..writeln('')
    ..writeln('## Results Table')
    ..writeln('')
    ..writeln('| ID | Name | Status | Errors | Error Codes |')
    ..writeln('|----|------|--------|--------|-------------|');

  for (final r in results) {
    final status = r.status == EvalStatus.pass ? 'PASS' : 'FAIL';
    final codes = r.errorCodes.isEmpty ? '-' : r.errorCodes.join(', ');
    buffer.writeln(
      '| ${r.requestId} | ${r.name} | $status | ${r.errorCount} | $codes |',
    );
  }

  File('working_docs/eval_results.md')
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
}

/// Builds token sequences for FakeEngine to replay valid responses.
Map<String, FakeTokenSequence> _buildTokenSequences(
  Map<String, dynamic> requestData,
) {
  final request = _buildGenerationRequest(requestData);
  final sequences = <String, FakeTokenSequence>{};

  // Intentions section
  final intentionsPrompt = buildIntentionsPrompt(request);
  sequences['system:$intentionsPrompt;'] = FakeTokenSequence(
    tokens: [_goodIntentionsJson()],
    delayMs: 5,
  );

  // Learner context
  final learnerContextPrompt = buildLearnerContextPrompt(request);
  sequences['system:$learnerContextPrompt;'] = FakeTokenSequence(
    tokens: [_goodLearnerContextJson()],
    delayMs: 5,
  );

  // Materials
  final materialsPrompt = buildMaterialsPrompt(request);
  sequences['system:$materialsPrompt;'] = FakeTokenSequence(
    tokens: [_goodMaterialsJson()],
    delayMs: 5,
  );

  // Flow
  final flowPrompt = buildFlowPrompt(request);
  sequences['system:$flowPrompt;'] = FakeTokenSequence(
    tokens: [_goodFlowJson(request)],
    delayMs: 5,
  );

  // Assessment
  final assessmentPrompt = buildAssessmentPrompt(request);
  sequences['system:$assessmentPrompt;'] = FakeTokenSequence(
    tokens: [_goodAssessmentJson(request)],
    delayMs: 5,
  );

  // Ways forward
  final waysForwardPrompt = buildWaysForwardPrompt(request);
  sequences['system:$waysForwardPrompt;'] = FakeTokenSequence(
    tokens: [_goodWaysForwardJson(request)],
    delayMs: 5,
  );

  return sequences;
}

/// Valid intentions JSON for test responses
String _goodIntentionsJson() => json.encode({
  'sharedSubTheme': 'Mga salita na naglalarawan',
  'grades': [
    {
      'gradeLabel': 'Grade 3',
      'subTheme': 'Pag-iisa-isa at paglalarawan',
      'objectives': [
        'Natutukoy ang mga salitang naglalarawan',
        'Nakapagbibigay ng payak na paglalarawan',
      ],
    },
    {
      'gradeLabel': 'Grade 4',
      'subTheme': 'Pangatnig sa teksto',
      'objectives': [
        'Natutukoy ang pangunahing ideya',
        'Nakagagamit ang pangatnig',
      ],
    },
  ],
  'bothGradesObjective':
      'Nauunawaan ang mga salita at nakapagpapahayag ng ideya',
});

String _goodLearnerContextJson() =>
    '{"learnerContext": "Ang mga mag-aaral ay mabisa sa pagbago at may interes sa paglalarawan."}';

String _goodMaterialsJson() =>
    '{"materials": {"items": ["Mga larawan", "Activity sheet", "Chalk"], "references": ["DepEd Curriculum Guide", "Learner Module"]}}';

String _goodFlowJson(GenerationRequest request) {
  final totalMinutes = request.header.sessionMinutes;
  final grades = request.grades;

  // Calculate minutes to match total exactly
  // Using the same algorithm as the default flow generator
  final m = (totalMinutes ~/ 6).clamp(1, totalMinutes - 5);
  final d = (totalMinutes ~/ 4).clamp(1, totalMinutes - m - 3);
  final p = (totalMinutes ~/ 4).clamp(1, totalMinutes - m - d - 2);
  final a = (totalMinutes ~/ 3).clamp(1, totalMinutes - m - d - p);
  final w = totalMinutes - m - d - p - a;

  // Adjust to ensure we hit the exact total
  var adjustedM = m;
  var adjustedD = d;
  var adjustedP = p;
  var adjustedA = a;
  var adjustedW = w;

  // If sum is less than total, add to wrap-up
  final currentTotal =
      adjustedM + adjustedD + adjustedP + adjustedA + adjustedW;
  final diff = totalMinutes - currentTotal;
  if (diff > 0) {
    adjustedW += diff;
  }

  // Ensure minimums
  adjustedM = adjustedM.clamp(5, totalMinutes - 10);
  adjustedD = adjustedD.clamp(5, totalMinutes - 10);
  adjustedP = adjustedP.clamp(5, totalMinutes - 10);
  adjustedA = adjustedA.clamp(5, totalMinutes - 15);
  adjustedW = adjustedW.clamp(5, totalMinutes - 10);

  // Final recalculation to hit exact total
  final sum = adjustedM + adjustedD + adjustedP + adjustedA + adjustedW;
  if (sum != totalMinutes) {
    adjustedW = totalMinutes - adjustedM - adjustedD - adjustedP - adjustedA;
    if (adjustedW < 5) {
      adjustedW = 5;
    }
  }

  // Build competency index mapping
  final compIdxByGrade = <String, int>{};
  for (var i = 0; i < grades.length; i++) {
    final grade = grades[i];
    final competencies = grade.competency
        .split('; ')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (competencies.isNotEmpty) {
      compIdxByGrade[grade.gradeLabel] = 0;
    }
  }

  return json.encode({
    'flow': [
      {
        'minutes': adjustedM,
        'stage': 'Whole-Class Motivation',
        'wholeClass': true,
        'wholeClassActivity': 'Ipakita ang larawan.',
        'activityByGrade': {},
        'competencyIndexByGrade': {},
      },
      {
        'minutes': adjustedD,
        'stage': 'Direct Teaching',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': Map.fromEntries(
          grades.map((g) => MapEntry(g.gradeLabel, 'Paliwanagang guro.')),
        ),
        'competencyIndexByGrade': compIdxByGrade,
      },
      {
        'minutes': adjustedP,
        'stage': 'Practice',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': Map.fromEntries(
          grades.map(
            (g) => MapEntry(g.gradeLabel, 'Gawain para sa bawat klase.'),
          ),
        ),
        'competencyIndexByGrade': compIdxByGrade,
      },
      {
        'minutes': adjustedA,
        'stage': 'Activity',
        'wholeClass': false,
        'wholeClassActivity': '',
        'activityByGrade': Map.fromEntries(
          grades.map((g) => MapEntry(g.gradeLabel, 'Gumawing gawa.')),
        ),
        'competencyIndexByGrade': compIdxByGrade,
      },
      {
        'minutes': adjustedW,
        'stage': 'Whole-Class Wrap-up',
        'wholeClass': true,
        'wholeClassActivity': 'Ipagpakita ang huling gawa.',
        'activityByGrade': {},
        'competencyIndexByGrade': {},
      },
    ],
  });
}

String _goodAssessmentJson(GenerationRequest request) {
  return json.encode({
    'assessments': request.grades
        .map(
          (g) => {
            'gradeLabel': g.gradeLabel,
            'formative': 'Obserbahan ang pakikilahok.',
            'exitTask': 'Isulat ang paglalarawan.',
            'successCriteria': 'Nakapagpapahayag ng tamang ideya.',
            'competencyIndex':
                g.competency
                    .split('; ')
                    .where((s) => s.trim().isNotEmpty)
                    .isNotEmpty
                ? 0
                : null,
          },
        )
        .toList(),
  });
}

String _goodWaysForwardJson(GenerationRequest request) {
  final gradeReflections = request.grades
      .map(
        (g) => <String, Object?>{
          'gradeLabel': g.gradeLabel,
          'text': 'Ano ang natutuhan?',
        },
      )
      .toList();
  gradeReflections.add(<String, Object?>{
    'gradeLabel': null,
    'text': 'Kumusta ang aralin?',
  });
  return json.encode({
    'waysForward': request.grades
        .map(
          (g) => {
            'gradeLabel': g.gradeLabel,
            'remediation': 'Muling basahin ang lesson.',
            'enrichment': 'Maghanap ng iba pang halimbawa.',
          },
        )
        .toList(),
    'reflectionQuestions': gradeReflections,
    'notesNextSession': 'Ipagpatuloy sa susunod na session.',
  });
}

enum EvalStatus { pass, fail }

class _EvalRequest {
  final String id;
  final String name;
  final Map<String, dynamic>? request;
  _EvalRequest({required this.id, required this.name, this.request});
  factory _EvalRequest.fromJson(Map<String, dynamic> json) => _EvalRequest(
    id: json['id'] as String,
    name: json['name'] as String,
    request: json['request'] as Map<String, dynamic>?,
  );
}

class _EvalResult {
  final String requestId;
  final String name;
  final EvalStatus status;
  final int errorCount;
  final List<String> errorCodes;
  final int passRate;
  _EvalResult({
    required this.requestId,
    required this.name,
    required this.status,
    required this.errorCount,
    required this.errorCodes,
    required this.passRate,
  });
}
