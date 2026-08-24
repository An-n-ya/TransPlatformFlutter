import 'package:flutter/material.dart';

/// Shared design metrics (spacing, radii, border widths) so visual rhythm stays
/// consistent across pages and is adjustable from a single location.
abstract final class AppSpacing {
  const AppSpacing._();

  /// Unit spacing scale.
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Corner radii.
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXl = 16;
  static const double radius2xl = 24;

  /// Fully rounded radius used for pill / capsule shapes.
  static const double radiusPill = 100;

  /// Border width of focused input fields.
  static const double borderFocused = 1.5;

  /// Standard height of text input fields.
  static const double inputHeight = 56;

  /// Standard compact action button height.
  static const double buttonHeightCompact = 40;

  /// Standard default action button height.
  static const double buttonHeight = 48;

  /// Default horizontal padding for form pages.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);
}

/// Convenience vertical/horizontal spacing helpers referenced across the app.
abstract final class AppGap {
  const AppGap._();

  static const SizedBox xs = SizedBox(height: AppSpacing.xs);
  static const SizedBox sm = SizedBox(height: AppSpacing.sm);
  static const SizedBox md = SizedBox(height: AppSpacing.md);
  static const SizedBox lg = SizedBox(height: AppSpacing.lg);
}