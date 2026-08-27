import 'package:flutter/foundation.dart';

/// Build flavor, injected at build time via:
/// ```bash
/// --dart-define=appFlavor=prod   # 生产
/// --dart-define=appFlavor=dev    # 开发（默认）
/// ```
/// Defaults to [kFlavorDev] so plain `flutter run` stays in dev mode.
const String kFlavorDev = 'dev';
const String kFlavorProd = 'prod';

const String appFlavor = String.fromEnvironment(
  'appFlavor',
  defaultValue: kFlavorDev,
);

/// 是否生产环境（兼容 'prod' / 'production' 两种写法）。
const bool isProduction = appFlavor == kFlavorProd || appFlavor == 'production';

/// Environment configuration for the app.
///
/// Tweak these values to match your setup.
class Env {
  Env._();

  /// Backend API base URL, selected by flavor.
  ///
  /// - prod → 生产服务器
  /// - dev  → 开发服务器（Android 模拟器经 10.0.2.2 访问宿主机）
  static String get apiBaseUrl {
    if (isProduction) {
      return 'https://yx.annya.work';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  /// JWT access token for remote mode.
  static const String? accessToken = null;

  /// Refresh token (optional, for token refresh).
  static const String? refreshToken = null;
}
