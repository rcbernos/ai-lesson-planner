/// Individual grade input card for the generator form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/generation/lesson_generator.dart';

/// Displays a card for inputting grade-specific data.
class GradeInputCard extends ConsumerStatefulWidget {
  const GradeInputCard({
    required this.index,
    required this.grade,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final GradeInput grade;
  final ValueChanged<GradeInput> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<GradeInputCard> createState() => _GradeInputCardState();
}

class _GradeInputCardState extends ConsumerState<GradeInputCard> {
  late final TextEditingController _maleController;
  late final TextEditingController _femaleController;
  late final TextEditingController _competencyController;
  late String _gradeLabel;

  @override
  void initState() {
    super.initState();
    _maleController = TextEditingController(text: widget.grade.male.toString());
    _femaleController = TextEditingController(text: widget.grade.female.toString());
    _competencyController = TextEditingController(text: widget.grade.competency);
    _gradeLabel = widget.grade.gradeLabel;
  }

  @override
  void dispose() {
    _maleController.dispose();
    _femaleController.dispose();
    _competencyController.dispose();
    super.dispose();
  }

  void _updateGrade() {
    final male = int.tryParse(_maleController.text) ?? 0;
    final female = int.tryParse(_femaleController.text) ?? 0;
    final competency = _competencyController.text;

    widget.onChanged(GradeInput(
      gradeLabel: _gradeLabel,
      male: male,
      female: female,
      subTheme: widget.grade.subTheme,
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
            Row(
              children: [
                // Grade Label Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gradeLabel,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6']
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
                const SizedBox(width: 8),
                // Male Count
                Expanded(
                  child: TextFormField(
                    controller: _maleController,
                    decoration: const InputDecoration(
                      labelText: 'Male',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateGrade(),
                  ),
                ),
                const SizedBox(width: 8),
                // Female Count
                Expanded(
                  child: TextFormField(
                    controller: _femaleController,
                    decoration: const InputDecoration(
                      labelText: 'Female',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateGrade(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sub-theme
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Sub-theme',
                border: OutlineInputBorder(),
              ),
              initialValue: widget.grade.subTheme,
              onChanged: (value) => _updateGrade(),
            ),
            const SizedBox(height: 12),
            // Competency
            TextFormField(
              controller: _competencyController,
              decoration: const InputDecoration(
                labelText: 'Competency',
                border: OutlineInputBorder(),
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
