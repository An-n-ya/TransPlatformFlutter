import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'ui/auth/splash_page.dart';

/// Default entry: runs in local mode (no backend needed).
///
/// To switch to remote mode, use:
/// ```bash
/// flutter run --target lib/main_remote.dart
/// ```
void main() {
  runApp(
    MultiProvider(
      providers: providersLocal,
      child: const MainApp(),
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
    return const MaterialApp(home: SplashPage());
  }
}
