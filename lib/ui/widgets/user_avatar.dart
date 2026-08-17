import 'package:flutter/material.dart';

import '../../domain/models/user.dart';

/// Circular avatar with a letter fallback (40x40 by default).
class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({super.key, required this.user, this.radius = 20, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    ImageProvider? image;
    final avatar = user.avatar;
    if (avatar != null && avatar.isNotEmpty) {
      image = avatar.startsWith('http')
          ? NetworkImage(avatar)
          : AssetImage(avatar) as ImageProvider;
    }
    final widget = CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
    final onTap = this.onTap;
    if (onTap == null) return widget;
    return GestureDetector(onTap: onTap, child: widget);
  }
}
