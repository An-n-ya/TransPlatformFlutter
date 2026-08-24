import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported appearance modes. `system` follows the OS setting.
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  /// Maps this app-level mode to the [ThemeMode] consumed by [MaterialApp].
  ThemeMode get material => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
}

/// Application-level theme preference.
///
/// Mirrors the existing app-level config pattern ([GlobalConfigProvider]) and
/// persists the selected [AppThemeMode] to local storage.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider();

  static const String _storageKey = 'theme_mode';

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  /// Loads the persisted mode from local storage (falls back to system).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_storageKey);
    if (raw != null && raw >= 0 && raw < AppThemeMode.values.length) {
      _mode = AppThemeMode.values[raw];
      notifyListeners();
    }
  }

  /// Applies and persists [mode].
  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, mode.index);
  }
}