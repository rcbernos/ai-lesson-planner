/// Generator screen with form for creating lesson plans.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generator_form_state.dart';
import 'grade_input_card.dart';
import 'generation_controller.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/features/plan_view/ilaw_plan_view.dart';
import 'package:ai_lesson_planner/core/providers.dart';

/// Default grade input with placeholder values.
GradeInput emptyGradeInput() => GradeInput(
      gradeLabel: 'Grade 2',
      male: 0,
      female: 0,
      subTheme: '',
      competency: '',
    );

class GeneratorScreen extends ConsumerWidget {
  const GeneratorScreen({super.key});

  static const List<String> _multigradeModels = [
    'STDT',
    'Peer Leader',
    'Buddy Reading',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(generatorFormProvider);
    final formNotifier = ref.read(generatorFormProvider.notifier);
    final genState = ref.watch(generationControllerProvider);
    final genController = ref.read(generationControllerProvider.notifier);
    final generatedPlan = ref.watch(generatedPlanProvider);

    // If a plan was generated, show it in the IlawPlanView
    if (generatedPlan != null) {
      return IlawPlanView(plan: generatedPlan);
    }

    // If generation is in progress, show progress area
    if (genState.isGenerating) {
      return _buildGenerationInProgress(context, genState, genController);
    }

    // Show error message if there was an error
    if (genState.errorMessage != null) {
      return _buildErrorView(context, genState.errorMessage!, formNotifier);
    }

    // Show the form
    return _buildFormView(context, formState, formNotifier, ref);
  }

  Widget _buildFormView(BuildContext context, GeneratorFormState formState,
      GeneratorFormNotifier formNotifier, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: () => formNotifier.reset(),
          ),
        ],
      ),
      body: SizedBox(
        width: 1024,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(textTheme, formState, formNotifier),
              const SizedBox(height: 24),
              _buildSessionDetails(textTheme, formState, formNotifier),
              const SizedBox(height: 16),
              _buildOutputOptions(textTheme, formState, formNotifier),
              const SizedBox(height: 24),
              _buildGradesSection(context, textTheme, formState, formNotifier),
              const SizedBox(height: 16),
              _buildGenerateButton(context, textTheme, formState, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationInProgress(BuildContext context,
      GenerationState genState, GenerationController genController) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: genController.cancel,
          tooltip: 'Cancel',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                genState.currentSection ?? 'Generating...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: genController.cancel,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage,
      GeneratorFormNotifier notifier) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: () => notifier.reset(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(TextTheme textTheme, GeneratorFormState state,
      GeneratorFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lesson Plan Details', style: textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
              labelText: 'School', border: OutlineInputBorder()),
          initialValue: state.school,
          onChanged: notifier.updateSchool,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
              labelText: 'Teacher', border: OutlineInputBorder()),
          initialValue: state.teacher,
          onChanged: notifier.updateTeacher,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Learning Area', border: OutlineInputBorder()),
                initialValue: state.learningArea,
                onChanged: notifier.updateLearningArea,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Date', border: OutlineInputBorder()),
                initialValue: state.date,
                onTap: () async {
                  // Date picker would be implemented here
                },
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
              labelText: 'Term', border: OutlineInputBorder()),
          initialValue: state.term,
          onChanged: notifier.updateTerm,
        ),
      ],
    );
  }

  Widget _buildSessionDetails(TextTheme textTheme, GeneratorFormState state,
      GeneratorFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Session Details', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Sessions', border: OutlineInputBorder()),
                initialValue: state.sessions.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) return;
                  notifier.updateSessions(int.parse(value));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Minutes per Session',
                    border: OutlineInputBorder()),
                initialValue: state.sessionMinutes.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) return;
                  notifier.updateSessionMinutes(int.parse(value));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutputOptions(TextTheme textTheme, GeneratorFormState state,
      GeneratorFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Output Options', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Shared Sub-theme',
            border: OutlineInputBorder(),
          ),
          initialValue: state.sharedSubTheme,
          onChanged: notifier.updateSharedSubTheme,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: state.multigradeModel,
          decoration: const InputDecoration(
            labelText: 'Multigrade Model',
            border: OutlineInputBorder(),
          ),
          items: _multigradeModels
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (value) => notifier.updateMultigradeModel(value ?? ''),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<OutputLanguage>(
          initialValue: state.outputLanguage,
          decoration: const InputDecoration(
            labelText: 'Output Language',
            border: OutlineInputBorder(),
          ),
          items: OutputLanguage.values
              .map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(
                      l == OutputLanguage.filipino ? 'Filipino' : 'English')))
              .toList(),
          onChanged: (value) =>
              notifier.updateOutputLanguage(value ?? OutputLanguage.filipino),
        ),
      ],
    );
  }

  Widget _buildGradesSection(BuildContext context, TextTheme textTheme,
      GeneratorFormState state, GeneratorFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grades (${state.grades.length} of 2-6)',
            style: textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < state.grades.length; i++)
          GradeInputCard(
            index: i,
            grade: state.grades[i],
            onChanged: (updated) => notifier.updateGrade(i, updated),
            onRemove: () => notifier.removeGrade(i),
          ),
        TextButton.icon(
          onPressed: state.grades.length >= 6
              ? null
              : () => notifier.addGrade(emptyGradeInput()),
          icon: const Icon(Icons.add),
          label: const Text('Add Grade'),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, TextTheme textTheme,
      GeneratorFormState state, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.canGenerate && state.grades.length >= 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Please fill all required fields to enable Generate.',
              style: textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.canGenerate
                ? () {
                    final request = state.buildGenerationRequest();
                    ref
                        .read(generationControllerProvider.notifier)
                        .startGeneration(request);
                  }
                : null,
            child: const Text('Generate'),
          ),
        ),
      ],
    );
  }
}
