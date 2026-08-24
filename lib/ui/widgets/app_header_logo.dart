import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Rounded logo block followed by a heading and a subtitle (used on login and
/// welcome headers).
class AppHeaderLogo extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;

  const AppHeaderLogo({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            imageAsset,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.25,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}