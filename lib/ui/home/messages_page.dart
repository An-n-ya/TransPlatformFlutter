import 'package:flutter/material.dart';

/// "我的" tab — a simple chat-style messages list.
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Align(
          alignment:
              index == 0 ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              index == 0 ? 'Hello' : 'Hi!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
