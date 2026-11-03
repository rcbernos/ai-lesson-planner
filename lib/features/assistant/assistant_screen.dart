/// Assistant screen placeholder - shows "Coming soon" with disabled input.
library;

import 'package:flutter/material.dart';

/// Placeholder screen for the AI Assistant feature.
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'The AI Assistant will help you refine lesson plans, '
              'answer questions about curriculum, and suggest improvements '
              'based on your specific context.\n\n'
              'This feature will be available in a future update.',
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Type your question here...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
