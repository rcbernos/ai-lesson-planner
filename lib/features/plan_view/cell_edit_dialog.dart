// ignore_for_file: prefer_const_constructors

library;

import 'package:flutter/material.dart';

/// Shows an edit dialog for a cell value.
/// Returns the new value if confirmed, or null if cancelled.
/// For numeric input, rejects non-integer values.
Future<String?> showCellEditDialog(
  BuildContext context, {
  required String title,
  required String initial,
  int maxLines = 6,
  bool numeric = false,
}) async {
  final controller = TextEditingController(text: initial);
  String? error;

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.multiline,
        decoration: InputDecoration(
          errorText: error,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final value = controller.text.trim();
            if (numeric) {
              final int? parsed = int.tryParse(value);
              if (parsed == null) {
                // Don't close dialog, show error instead
                error = 'Please enter a valid integer';
                controller.value = controller.value.copyWith(
                  text: initial,
                  selection: TextSelection.collapsed(offset: initial.length),
                );
                return;
              }
            }
            Navigator.of(context).pop(value);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
