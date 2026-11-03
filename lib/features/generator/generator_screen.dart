/// Generator screen with form for creating lesson plans.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generator_form_state.dart';
import 'grade_input_card.dart';
import 'generation_controller.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/core/models/lesson_plan.dart';
import 'package:ai_lesson_planner/core/providers.dart';
import 'package:ai_lesson_planner/services/database/plan_repository.dart';

GradeInput emptyGradeInput() => GradeInput(
    gradeLabel: 'Grade 2', male: 0, female: 0, subTheme: '', competency: '');

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});
  static const List<String> _multigradeModels = [
    'STDT',
    'Peer Leader',
    'Buddy Reading'
  ];

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  late final TextEditingController _schoolCtrl,
      _teacherCtrl,
      _learningAreaCtrl,
      _dateCtrl,
      _termCtrl,
      _sessionsCtrl,
      _minutesCtrl,
      _sharedSubThemeCtrl;

  @override
  void initState() {
    super.initState();
    _schoolCtrl = TextEditingController();
    _teacherCtrl = TextEditingController();
    _learningAreaCtrl = TextEditingController();
    _dateCtrl = TextEditingController();
    _termCtrl = TextEditingController();
    _sessionsCtrl = TextEditingController(text: '1');
    _minutesCtrl = TextEditingController(text: '90');
    _sharedSubThemeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _schoolCtrl.dispose();
    _teacherCtrl.dispose();
    _learningAreaCtrl.dispose();
    _dateCtrl.dispose();
    _termCtrl.dispose();
    _sessionsCtrl.dispose();
    _minutesCtrl.dispose();
    _sharedSubThemeCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(GeneratorFormState state) {
    if (_schoolCtrl.text != state.school) _schoolCtrl.text = state.school;
    if (_teacherCtrl.text != state.teacher) _teacherCtrl.text = state.teacher;
    if (_learningAreaCtrl.text != state.learningArea)
      _learningAreaCtrl.text = state.learningArea;
    if (_dateCtrl.text != state.date) _dateCtrl.text = state.date;
    if (_termCtrl.text != state.term) _termCtrl.text = state.term;
    if (_sessionsCtrl.text != state.sessions.toString())
      _sessionsCtrl.text = state.sessions.toString();
    if (_minutesCtrl.text != state.sessionMinutes.toString())
      _minutesCtrl.text = state.sessionMinutes.toString();
    if (_sharedSubThemeCtrl.text != state.sharedSubTheme)
      _sharedSubThemeCtrl.text = state.sharedSubTheme;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(generatorFormProvider);
    final formNotifier = ref.read(generatorFormProvider.notifier);
    final genState = ref.watch(generationControllerProvider);
    final genController = ref.read(generationControllerProvider.notifier);
    final generatedPlan = ref.watch(generatedPlanProvider);

    _syncControllers(formState);

    if (generatedPlan != null) {
      return _buildPlanView(context, generatedPlan);
    }
    if (genState.isGenerating)
      return _buildProgressView(context, genState, genController);
    if (genState.errorMessage != null)
      return _buildErrorView(context, genState.errorMessage!, formNotifier);

    return _buildFormView(context, formState, formNotifier);
  }

  Widget _buildPlanView(BuildContext context, LessonPlan plan) {
    final repository = ref.read(planRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Lesson Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Plan',
            onPressed: () => _savePlan(context, repository, plan),
          ),
        ],
      ),
      body: IlawPlanView(plan: plan),
    );
  }

  void _savePlan(
      BuildContext context, PlanRepository repository, LessonPlan plan) {
    repository.savePlan(plan).then((id) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved successfully!')),
      );
    }).catchError((error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    });
  }

  Widget _buildFormView(BuildContext context, GeneratorFormState formState,
      GeneratorFormNotifier formNotifier) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Generator'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: () => formNotifier.reset()),
      ]),
      body: SizedBox(
          width: 1024,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeaderSection(formState, formNotifier),
              const SizedBox(height: 24),
              _buildSessionDetails(formState, formNotifier),
              const SizedBox(height: 16),
              _buildOutputOptions(formState, formNotifier),
              const SizedBox(height: 24),
              _buildGradesSection(formState, formNotifier),
              const SizedBox(height: 16),
              _buildGenerateButton(textTheme, formState),
            ]),
          )),
    );
  }

  Widget _buildHeaderSection(
      GeneratorFormState state, GeneratorFormNotifier notifier) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lesson Plan Details',
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      TextFormField(
          controller: _schoolCtrl,
          decoration: InputDecoration(
              labelText: '* School',
              border: const OutlineInputBorder(),
              errorText: state.school.isEmpty ? 'Required' : null),
          onChanged: notifier.updateSchool),
      const SizedBox(height: 16),
      TextFormField(
          controller: _teacherCtrl,
          decoration: InputDecoration(
              labelText: '* Teacher',
              border: const OutlineInputBorder(),
              errorText: state.teacher.isEmpty ? 'Required' : null),
          onChanged: notifier.updateTeacher),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child: TextFormField(
                controller: _learningAreaCtrl,
                decoration: InputDecoration(
                    labelText: '* Learning Area',
                    border: const OutlineInputBorder(),
                    errorText: state.learningArea.isEmpty ? 'Required' : null),
                onChanged: notifier.updateLearningArea)),
        const SizedBox(width: 8),
        Expanded(
            child: TextFormField(
                controller: _dateCtrl,
                decoration: InputDecoration(
                    labelText: '* Date',
                    border: const OutlineInputBorder(),
                    errorText: state.date.isEmpty ? 'Required' : null),
                readOnly: true,
                onTap: () async {
                  final DateTime? selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (selected != null) {
                    final formatted =
                        '${selected.day}/${selected.month}/${selected.year}';
                    _dateCtrl.text = formatted;
                    notifier.updateDate(formatted);
                  }
                })),
      ]),
      const SizedBox(height: 16),
      TextFormField(
          controller: _termCtrl,
          decoration: InputDecoration(
              labelText: '* Term',
              border: const OutlineInputBorder(),
              errorText: state.term.isEmpty ? 'Required' : null),
          onChanged: notifier.updateTerm),
    ]);
  }

  Widget _buildSessionDetails(
      GeneratorFormState state, GeneratorFormNotifier notifier) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Session Details', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: TextFormField(
                controller: _sessionsCtrl,
                decoration: InputDecoration(
                    labelText: '* Sessions',
                    border: const OutlineInputBorder(),
                    errorText: state.sessions <= 0 ? 'Required' : null),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  if (v.isNotEmpty) notifier.updateSessions(int.parse(v));
                })),
        const SizedBox(width: 8),
        Expanded(
            child: TextFormField(
                controller: _minutesCtrl,
                decoration: InputDecoration(
                    labelText: '* Session Minutes',
                    border: const OutlineInputBorder(),
                    errorText: state.sessionMinutes <= 0 ? 'Required' : null),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  if (v.isNotEmpty) notifier.updateSessionMinutes(int.parse(v));
                })),
      ]),
    ]);
  }

  Widget _buildOutputOptions(
      GeneratorFormState state, GeneratorFormNotifier notifier) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Output Options', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextFormField(
          controller: _sharedSubThemeCtrl,
          decoration: InputDecoration(
              labelText: '* Shared Sub-theme',
              border: const OutlineInputBorder(),
              errorText: state.sharedSubTheme.isEmpty ? 'Required' : null),
          onChanged: notifier.updateSharedSubTheme),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
          initialValue: state.multigradeModel,
          decoration: const InputDecoration(
              labelText: 'Multigrade Model', border: OutlineInputBorder()),
          items: GeneratorScreen._multigradeModels
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => notifier.updateMultigradeModel(v ?? '')),
      const SizedBox(height: 16),
      DropdownButtonFormField<OutputLanguage>(
          initialValue: state.outputLanguage,
          decoration: const InputDecoration(
              labelText: 'Output Language', border: OutlineInputBorder()),
          items: OutputLanguage.values
              .map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(
                      l == OutputLanguage.filipino ? 'Filipino' : 'English')))
              .toList(),
          onChanged: (v) =>
              notifier.updateOutputLanguage(v ?? OutputLanguage.filipino)),
    ]);
  }

  Widget _buildGradesSection(
      GeneratorFormState state, GeneratorFormNotifier notifier) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Grades (${state.grades.length} of 2-6)',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (var i = 0; i < state.grades.length; i++)
        GradeInputCard(
            index: i,
            grade: state.grades[i],
            onChanged: (u) => notifier.updateGrade(i, u),
            onRemove: () => notifier.removeGrade(i)),
      TextButton.icon(
          onPressed: state.grades.length >= 6
              ? null
              : () => notifier.addGrade(emptyGradeInput()),
          icon: const Icon(Icons.add),
          label: const Text('Add Grade')),
    ]);
  }

  Widget _buildGenerateButton(TextTheme textTheme, GeneratorFormState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!state.canGenerate && state.grades.length >= 2)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Please fill all required fields to enable Generate.',
                style: textTheme.bodySmall?.copyWith(color: Colors.red))),
      SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: state.canGenerate
                  ? () {
                      ref
                          .read(generationControllerProvider.notifier)
                          .startGeneration(state.buildGenerationRequest());
                    }
                  : null,
              child: const Text('Generate'))),
    ]);
  }

  Widget _buildProgressView(BuildContext context, GenerationState genState,
      GenerationController genController) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Generator'),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: genController.cancel,
                tooltip: 'Cancel')),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(genState.currentSection ?? 'Generating...',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                          onPressed: genController.cancel,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'))
                    ]))));
  }

  Widget _buildErrorView(BuildContext context, String errorMessage,
      GeneratorFormNotifier notifier) {
    return Scaffold(
        appBar: AppBar(title: const Text('Generator'), actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Form',
              onPressed: () => notifier.reset())
        ]),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(errorMessage,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                          onPressed: () => notifier.reset(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'))
                    ]))));
  }
}
