import 'package:flutter/material.dart';

/// A horizontal divider with a centered label (e.g. "还没有账号?") bounded by
/// two [Divider]s. Colors resolve from the active [Theme].
class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}