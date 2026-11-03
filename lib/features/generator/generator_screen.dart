/// Generator screen with form for creating lesson plans.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generator_form_state.dart';
import 'grade_input_card.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';

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
    final state = ref.watch(generatorFormProvider);
    final notifier = ref.read(generatorFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

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
      body: SizedBox(
        width: 1024,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(textTheme, state, notifier),
              const SizedBox(height: 24),
              _buildSessionDetails(textTheme, state, notifier),
              const SizedBox(height: 16),
              _buildOutputOptions(textTheme, state, notifier),
              const SizedBox(height: 24),
              _buildGradesSection(context, textTheme, state, notifier),
              const SizedBox(height: 16),
              _buildGenerateButton(context, textTheme, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
      TextTheme textTheme, GeneratorFormState state, GeneratorFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lesson Plan Details', style: textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          decoration:
              const InputDecoration(labelText: 'School', border: OutlineInputBorder()),
          initialValue: state.school,
          onChanged: notifier.updateSchool,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration:
              const InputDecoration(labelText: 'Teacher', border: OutlineInputBorder()),
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
          decoration:
              const InputDecoration(labelText: 'Term', border: OutlineInputBorder()),
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
                    labelText: 'Minutes per Session', border: OutlineInputBorder()),
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

  Widget _buildOutputOptions(
      TextTheme textTheme, GeneratorFormState state, GeneratorFormNotifier notifier) {
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
                  value: l, child: Text(l == OutputLanguage.filipino ? 'Filipino' : 'English')))
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
        Text('Grades (${state.grades.length} of 2-6)', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < state.grades.length; i++)
          GradeInputCard(
            index: i,
            grade: state.grades[i],
            onChanged: (updated) => notifier.updateGrade(i, updated),
            onRemove: () => notifier.removeGrade(i),
          ),
        TextButton.icon(
          onPressed:
              state.grades.length >= 6 ? null : () => notifier.addGrade(emptyGradeInput()),
          icon: const Icon(Icons.add),
          label: const Text('Add Grade'),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, TextTheme textTheme,
      GeneratorFormState state, GeneratorFormNotifier notifier) {
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
                    // TODO: Trigger generation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Generate pressed! (not yet wired)')),
                    );
                  }
                : null,
            child: const Text('Generate'),
          ),
        ),
      ],
    );
  }
}
