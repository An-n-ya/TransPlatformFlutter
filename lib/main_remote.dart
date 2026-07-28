import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

/// Remote data mode entry point.
///
/// Connects to the backend API at [ApiClient.baseUrl]
/// (default http://localhost:8081).
///
/// The backend must be running for this mode to work.
///
/// Launch with:
/// ```bash
/// flutter run --target lib/main_remote.dart
/// ```
void main() {
  runApp(
    MultiProvider(
      providers: providersRemote,
      child: const MainApp(),
    ),
  );
}
