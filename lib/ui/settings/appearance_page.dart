import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_provider.dart';

/// Appearance settings page: choose the color mode (light / dark / system).
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('深色模式')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('浅色'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('深色'),
                ),
                ButtonSegment<AppThemeMode>(
                  value: AppThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('跟随系统'),
                ),
              ],
              selected: {themeProvider.mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  themeProvider.setMode(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}