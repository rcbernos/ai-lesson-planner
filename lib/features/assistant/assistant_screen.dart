/// Assistant screen for guided slot-filling chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_lesson_planner/core/chat/chat_session.dart';
import 'package:ai_lesson_planner/features/assistant/chat_bubble.dart';

/// Provider for the chat session state.
final chatSessionProvider =
    StateProvider<ChatSession>((ref) => ChatSession());

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(chatSessionProvider);
    _controller.clear();

    final updatedSession = session.addMessage(
      ChatMessage(role: 'user', content: text),
    );
    ref.read(chatSessionProvider.notifier).state = updatedSession;

    final assistantSession = ref.read(chatSessionProvider);
    final finalSession = assistantSession.addMessage(
      ChatMessage(role: 'assistant', content: 'Got it!'),
    );
    ref.read(chatSessionProvider.notifier).state = finalSession;
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(chatSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: session.messages.length,
              itemBuilder: (context, index) {
                final message = session.messages[index];
                return ChatBubble(
                  role: message.role,
                  content: message.content,
                  isMe: message.role == 'user',
                );
              },
            ),
          ),
          _buildSummaryCard(session),
        ],
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  Widget _buildSummaryCard(ChatSession session) {
    final canGenerate = session.canGenerate;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form so far', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSummaryRow('School', session.header.school, 
                session.header.school.isEmpty ? 'tap to edit' : null),
            _buildSummaryRow('Teacher', session.header.teacher,
                session.header.teacher.isEmpty ? 'tap to edit' : null),
            _buildSummaryRow('Learning Area', session.header.learningArea,
                session.header.learningArea.isEmpty ? 'tap to edit' : null),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canGenerate ? _openInForm : null,
                child: Text(canGenerate ? 'Generate from Chat' : 'Complete Form First'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [String? hint]) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      subtitle: value.isEmpty || hint != null
          ? Text(hint ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)))
          : SelectableText(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
      trailing: value.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // TODO: Show edit dialog for this field
              },
            )
          : null,
    );
  }

  void _openInForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature: Open in form would pre-fill the generator from chat')),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Describe your class...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}