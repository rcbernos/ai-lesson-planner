/// Chat bubble widget for displaying messages in the assistant.
library;

import 'package:flutter/material.dart';

/// A chat bubble widget that displays a message from either the user or assistant.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.role,
    required this.content,
    this.isMe = false,
  });

  /// The role of the sender: 'user' or 'assistant'.
  final String role;

  /// The message content.
  final String content;

  /// Whether this bubble belongs to the current user.
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
            height: 1.4,
          ),
          softWrap: true,
        ),
      ),
    );
  }
}