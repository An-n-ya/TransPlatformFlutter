import 'package:flutter/material.dart';

/// Brand palette: single source of truth for brand-specific appearance tokens.
///
/// Pages and widgets should obtain most colors from the currently active
/// [ColorScheme] (see `color_schemes.dart`) so they resolve correctly in both
/// light and dark themes. Reach into this palette only for values that have no
/// semantic slot in [ColorScheme] (brand accents, gradients, logo surfaces).
abstract final class AppPalette {
  const AppPalette._();

  /// Seed used to derive both light and dark color schemes.
  ///
  /// Matches the previous hard-coded brand primary `0xFF6750A4`.
  // static const Color seed = Color(0xFF6750A4);
  static const Color seed = Color(0xFFFCF16E);

  /// Pure-white used for on-primary foregrounds where the M3 scheme does not
  /// already guarantee high contrast.
  static const Color onPrimaryWhite = Colors.white;

  /// Neutral placeholder for image placeholders and empty states.
  static const Color scaffoldPlaceholder = Color(0xFFE9EDF1);
}