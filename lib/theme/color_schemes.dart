import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Light color scheme generated from the brand [AppPalette.seed].
///
/// Migration reference (old hard-coded literal -> new scheme token, so phase 2
/// replacements remain faithful to the original Material 3 look):
/// - `0xFF6750A4`, `Colors.purple`      -> `primary`
/// - `0xFFEADDFF`                       -> `primaryContainer`
/// - `0xFFE8DEF8`, `0xFF1D192B`         -> `secondaryContainer` / `onSecondaryContainer`
/// - `0xFFFEF7FF`                       -> `surface`
/// - `0xFFECE6F0`, `0xFFE7E0EC`         -> `surfaceContainerHighest`
/// - `0xFF1C1B1F`, `0xFF1D1B20`         -> `onSurface`
/// - `0xFF49454F`                       -> `onSurfaceVariant`
/// - `0xFF79747E`                       -> `outline`
/// - `0xFFCAC4D0`                       -> `outlineVariant`
/// - `0xFFB3261E`, `Colors.red`         -> `error`
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppPalette.seed,
  primary: const Color(0xFFFCF16E),
  brightness: Brightness.light,
  dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
);

/// Dark color scheme derived from the same brand seed. Contrast is handled
/// automatically by Material tonal palettes.
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppPalette.seed,
  brightness: Brightness.dark,
  dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
);