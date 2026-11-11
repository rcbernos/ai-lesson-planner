/// Individual grade input card for the generator form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';

/// Displays a card for inputting grade-specific data.
/// Shows all fields: Grade label, student counts, sub-theme, and competency.
class GradeInputCard extends ConsumerStatefulWidget {
  const GradeInputCard({
    required this.index,
    required this.grade,
    required this.onChanged,
    required this.onRemove,
    this.isExpanded = true,
    super.key,
  });

  final int index;
  final GradeInput grade;
  final ValueChanged<GradeInput> onChanged;
  final VoidCallback onRemove;
  final bool isExpanded;

  @override
  ConsumerState<GradeInputCard> createState() => _GradeInputCardState();
}

class _GradeInputCardState extends ConsumerState<GradeInputCard> {
  late final TextEditingController _maleController;
  late final TextEditingController _femaleController;
  late final TextEditingController _subThemeController;
  late final TextEditingController _competencyController;
  late String _gradeLabel;

  @override
  void initState() {
    super.initState();
    _maleController = TextEditingController(text: widget.grade.male.toString());
    _femaleController =
        TextEditingController(text: widget.grade.female.toString());
    _subThemeController = TextEditingController(text: widget.grade.subTheme);
    _competencyController =
        TextEditingController(text: widget.grade.competency);
    _gradeLabel = widget.grade.gradeLabel;
  }

  @override
  void dispose() {
    _maleController.dispose();
    _femaleController.dispose();
    _subThemeController.dispose();
    _competencyController.dispose();
    super.dispose();
  }

  void _updateGrade() {
    final male = int.tryParse(_maleController.text) ?? 0;
    final female = int.tryParse(_femaleController.text) ?? 0;
    final subTheme = _subThemeController.text;
    final competency = _competencyController.text;

    widget.onChanged(GradeInput(
      gradeLabel: _gradeLabel,
      male: male,
      female: female,
      subTheme: subTheme,
      competency: competency,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grade ${widget.index + 1}',
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Grade label selector (full width)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _gradeLabel,
                decoration: const InputDecoration(
                  labelText: '* Grade',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  'Grade 1',
                  'Grade 2',
                  'Grade 3',
                  'Grade 4',
                  'Grade 5',
                  'Grade 6'
                ]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gradeLabel = value;
                    });
                    _updateGrade();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // Male and Female counts on separate line
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: TextFormField(
                      controller: _maleController,
                      decoration: const InputDecoration(
                        labelText: 'Male',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateGrade(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: TextFormField(
                      controller: _femaleController,
                      decoration: const InputDecoration(
                        labelText: 'Female',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateGrade(),
                    ),
                  ),
                ),
              ],
            ),
            // Always show sub-theme
            const SizedBox(height: 12),
            TextFormField(
              controller: _subThemeController,
              decoration: InputDecoration(
                labelText: '* Sub-theme',
                border: const OutlineInputBorder(),
                errorText: widget.grade.subTheme.isEmpty ? 'Required' : null,
              ),
              maxLines: 2,
              onChanged: (_) => _updateGrade(),
            ),
            // Competency always visible
            const SizedBox(height: 12),
            TextFormField(
              controller: _competencyController,
              decoration: InputDecoration(
                labelText: '* Competency',
                border: const OutlineInputBorder(),
                errorText: widget.grade.competency.isEmpty ? 'Required' : null,
              ),
              maxLines: 2,
              onChanged: (_) => _updateGrade(),
            ),
          ],
        ),
      ),
    );
  }
}
