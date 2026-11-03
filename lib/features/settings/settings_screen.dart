/// Settings screen for configuring application preferences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/features/generator/generator_form_state.dart';

/// Settings screen displaying configuration options.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LanguageSection(),
            SizedBox(height: 24),
            _DataFolderSection(),
            SizedBox(height: 24),
            _AIStatusSection(),
          ],
        ),
      ),
    );
  }
}

/// Section for output language selection.
class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(generatorFormProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Language',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<OutputLanguage>(
              initialValue: formState.outputLanguage,
              decoration: const InputDecoration(
                labelText: 'Select language',
                border: OutlineInputBorder(),
              ),
              items: OutputLanguage.values
                  .map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(generatorFormProvider.notifier)
                      .updateOutputLanguage(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Section showing the data folder path.
class _DataFolderSection extends StatefulWidget {
  const _DataFolderSection();

  @override
  State<_DataFolderSection> createState() => _DataFolderSectionState();
}

class _DataFolderSectionState extends State<_DataFolderSection> {
  String? _dataFolderPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFolderPath();
  }

  Future<void> _loadDataFolderPath() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      setState(() {
        _dataFolderPath = '${docsDir.path}/LMS_Data/';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dataFolderPath = 'Unable to determine';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Folder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const LinearProgressIndicator()
                : SelectableText(
                    _dataFolderPath ?? 'Loading...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      backgroundColor: Colors.grey,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Section showing AI model status.
class _AIStatusSection extends StatelessWidget {
  const _AIStatusSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: ListTile(
          leading: Icon(Icons.data_object, color: Colors.orange),
          title: Text('AI Status'),
          subtitle: Text('Demo mode: no model installed'),
        ),
      ),
    );
  }
}
