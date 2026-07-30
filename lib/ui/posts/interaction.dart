
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Small helper for like / comment / collect buttons.
class PostActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const PostActionBtn({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // FIXME: 这个TextButton内部的`_InputPadding`太大了，能否把这个Padding去掉？
    // 如果不行，直接手写一个button也行
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: color ?? cs.onSurface),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class InteractionBar extends StatelessWidget {
  final bool liked;
  final bool collected;
  final int likesCount;
  final int collectionsCount;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onCollect;

  const InteractionBar({
    required this.liked,
    required this.collected,
    required this.likesCount,
    required this.collectionsCount,
    required this.commentsCount,
    required this.onLike,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PostActionBtn(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: '$likesCount',
          color: liked ? Colors.red : null,
          onPressed: onLike,
        ),
        const SizedBox(width: 8),
        PostActionBtn(
          icon: Icons.mode_comment_outlined,
          label: '$commentsCount',
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        PostActionBtn(
          icon: collected ? Icons.bookmark : Icons.bookmark_border,
          label: '$collectionsCount',
          color: collected ? Colors.amber : null,
          onPressed: onCollect,
        ),
      ],
    );
  }
}

