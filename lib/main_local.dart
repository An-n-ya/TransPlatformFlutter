import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

/// Local data mode entry point.
///
/// Runs the app with hardcoded sample data — no backend needed.
/// Default development mode.
/// Launch with:
/// ```bash
/// flutter run --target lib/main_local.dart
/// ```
void main() {
  runApp(
    MultiProvider(
      providers: providersLocal,
      child: const MainApp(),
    ),
  );
}
