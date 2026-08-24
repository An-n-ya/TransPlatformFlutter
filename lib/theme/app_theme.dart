import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'app_spacing.dart';

/// Builds the [ThemeData] used by the whole app for a given brightness.
///
/// Centralizing component level defaults here (input borders, pill buttons,
/// navigation bar, app bar) means future visual adjustments only need to touch
/// this file / the color schemes instead of individual pages.
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final scheme =
      brightness == Brightness.light ? lightColorScheme : darkColorScheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    inputDecorationTheme: _inputDecorationTheme(scheme),
    filledButtonTheme: _filledButtonTheme(scheme),
    navigationBarTheme: _navigationBarTheme(scheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
  final radius = BorderRadius.circular(AppSpacing.radiusSmall);
  final defaultBorder = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: scheme.outline),
  );

  return InputDecorationTheme(
    border: defaultBorder,
    enabledBorder: defaultBorder,
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: scheme.primary,
        width: AppSpacing.borderFocused,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: scheme.error,
        width: AppSpacing.borderFocused,
      ),
    ),
    hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.sm,
    ),
  );
}

FilledButtonThemeData _filledButtonTheme(ColorScheme scheme) {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

NavigationBarThemeData _navigationBarTheme(ColorScheme scheme) {
  return NavigationBarThemeData(
    backgroundColor: scheme.surface,
    indicatorColor: scheme.primary,
  );
}