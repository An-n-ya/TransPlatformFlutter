import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'main.dart';

/// Local data mode entry point.
///
/// Runs the app with hardcoded sample data — no backend needed.
/// 适合纯 UI 开发；需要连后端请用默认入口 lib/main.dart 或 lib/main_remote.dart。
///
/// Launch with:
/// ```bash
/// flutter run --target lib/main_local.dart
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
