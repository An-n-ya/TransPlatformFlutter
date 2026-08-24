import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trans_platform/theme/theme_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system mode', () {
    final provider = ThemeProvider();
    expect(provider.mode, AppThemeMode.system);
  });

  test('serialize maps AppThemeMode to ThemeMode', () {
    expect(AppThemeMode.system.material, ThemeMode.system);
    expect(AppThemeMode.light.material, ThemeMode.light);
    expect(AppThemeMode.dark.material, ThemeMode.dark);
  });

  test('load restores the persisted mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 2});
    final provider = ThemeProvider();
    await provider.load();
    expect(provider.mode, AppThemeMode.dark);
  });

  test('load ignores an out-of-range persisted value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 99});
    final provider = ThemeProvider();
    await provider.load();
    expect(provider.mode, AppThemeMode.system);
  });

  test('setMode notifies and persists the chosen mode', () async {
    final provider = ThemeProvider();
    var notified = false;
    provider.addListener(() => notified = true);

    await provider.setMode(AppThemeMode.light);

    expect(provider.mode, AppThemeMode.light);
    expect(notified, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theme_mode'), AppThemeMode.light.index);
  });
}