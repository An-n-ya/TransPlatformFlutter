import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'ui/auth/login_page.dart';

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

/// Main app widget. Shows [LoginPage] on start.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginPage());
  }
}
