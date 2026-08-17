import 'package:flutter/material.dart';

import '../../domain/models/topic.dart';
import '../posts/topic_detail_page.dart';

/// Primary-container pill with a tag icon and the topic name.
///
/// Tapping the chip (by default) opens the topic detail page.
class TopicChip extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;

  const TopicChip({super.key, required this.topic, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TopicDetailPage(topic: topic),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEADDFF),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 10, color: cs.primary),
            const SizedBox(width: 2),
            Text(
              topic.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
