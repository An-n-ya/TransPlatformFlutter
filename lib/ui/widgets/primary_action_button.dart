import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Pill-shaped primary/secondary action button used across the auth flows.
///
/// Shows a built-in loading spinner while [loading] is true and inherits its
/// colors (pill shape, foreground, background) from the active [Theme] by
/// default. Pass overrides to produce a secondary (container) variant.
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Color? foregroundColor;

  const PrimaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.height = AppSpacing.buttonHeightCompact,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = !loading && onPressed != null;

    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? cs.primary,
          disabledBackgroundColor:
              disabledBackgroundColor ?? cs.primary.withValues(alpha: 0.38),
          foregroundColor: foregroundColor ?? cs.onPrimary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor ?? cs.onPrimary,
                ),
              )
            : FittedBox(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }
}