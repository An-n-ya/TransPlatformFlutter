import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'providers/snackbar_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'ui/auth/splash_page.dart';

/// Default entry: runs in local mode (no backend needed).
///
/// To switch to remote mode, use:
/// ```bash
/// flutter run --target lib/main_remote.dart
/// ```
void main() {
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: providersLocal,
        child: const MainApp(),
      ),
    ),
  );
}

/// Main app widget.
///
/// On start, shows [SplashPage] which checks for a saved session.
/// - Token cached → auto-navigate to [AppShell]
/// - No token     → show [LoginPage]
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        title: 'YX',
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeProvider.mode.material,
        home: const SplashPage(),
      ),
    );
  }
}
