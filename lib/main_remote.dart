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
/// 等价于 flavor-aware 的 lib/main.dart（默认入口）。
/// 后端地址由 flavor 决定：
/// - `--dart-define=appFlavor=prod` → 生产后端
/// - 默认 dev → 开发后端（[Env.apiBaseUrl]）
///
/// The backend must be running for this mode to work.
///
/// Launch with:
/// ```bash
/// flutter run --flavor dev --target lib/main_remote.dart
/// flutter build apk --release --flavor prod --dart-define=appFlavor=prod --target lib/main_remote.dart
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
