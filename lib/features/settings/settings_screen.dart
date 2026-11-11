/// Settings screen for configuring application preferences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ai_lesson_planner/core/utils.dart';

import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';
import 'package:ai_lesson_planner/features/generator/generator_form_state.dart';
import 'package:ai_lesson_planner/services/database/database_helper.dart';

/// Settings screen displaying configuration options.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _databasePath;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadDatabasePath();
  }

  Future<void> _loadDatabasePath() async {
    try {
      final path = await DatabaseHelper.instance.getDatabasePath();
      setState(() {
        _databasePath = path;
      });
    } catch (e) {
      setState(() {
        _databasePath = 'Unable to determine';
      });
    }
  }

  Future<void> _deleteDatabase() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Database'),
        content: const Text(
            'This will permanently delete all saved lesson plans and references. '
            'This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final deleted = await DatabaseHelper.instance.deleteDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleted
                ? 'Database deleted successfully'
                : 'Database file not found or could not be deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting database: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LanguageSection(),
            const SizedBox(height: 24),
            _DataFolderSection(),
            const SizedBox(height: 24),
            _DatabaseSection(
              databasePath: _databasePath,
              isDeleting: _isDeleting,
              onDelete: _deleteDatabase,
            ),
            const SizedBox(height: 24),
            const _AIStatusSection(),
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
      final exportDir = await AppUtils.getExportDirPath();
      setState(() {
        _dataFolderPath = p.dirname(exportDir); // .../LMS_Data
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

/// Section for database management.
class _DatabaseSection extends StatelessWidget {
  const _DatabaseSection({
    required this.databasePath,
    required this.isDeleting,
    required this.onDelete,
  });

  final String? databasePath;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (databasePath != null)
              SelectableText(
                databasePath!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete, color: Colors.red),
                label: Text(isDeleting ? 'Deleting...' : 'Delete Database'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
