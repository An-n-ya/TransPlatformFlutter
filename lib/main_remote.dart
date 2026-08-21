import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';
import 'providers/repository_providers.dart';

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
    ProviderScope(
      overrides: [
        repositoryModeProvider.overrideWithValue(RepositoryMode.remote),
      ],
      child: MultiProvider(
        providers: providersRemote,
        child: const MainApp(),
      ),
    ),
  );
}
