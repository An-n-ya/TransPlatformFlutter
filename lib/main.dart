import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'config/env.dart';
import 'providers/repository_providers.dart';
import 'providers/snackbar_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'ui/auth/splash_page.dart';

/// 默认入口：按 flavor 自动选择远程后端，后端地址由 [Env.apiBaseUrl] 决定。
///
/// - prod flavor → 远程数据源 + 生产后端（https://yx.annya.work）
/// - dev  flavor → 远程数据源 + 开发后端（Android 模拟器 http://10.0.2.2:8081）
///
/// 运行方式：
/// ```bash
/// flutter run --flavor dev                          # 开发
/// flutter run --flavor prod --dart-define=appFlavor=prod   # 生产
/// ```
///
/// 若想使用本地 mock 数据（不连后端），改用 lib/main_local.dart。
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
