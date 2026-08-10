/// Environment configuration for the app.
///
/// Tweak these values to match your setup.
class Env {
  Env._();

  /// Backend API base URL.
  ///
  /// ⚠️ 根据运行环境修改：
  /// - Android 模拟器 → http://10.0.2.2:8081
  /// - iOS 模拟器     → http://localhost:8081（默认即可）
  /// - 真机（同一 WiFi）→ http://192.168.1.14:8081
  /// - Web 浏览器     → http://localhost:8081
  /// - Tailscale 远程 → http://100.122.220.40:8081
  static const String apiBaseUrl = 'http://100.122.220.40:8081';
  // static const String apiBaseUrl = 'https://trans.annya.work';

  /// JWT access token for remote mode.
  static const String? accessToken = null;

  /// Refresh token (optional, for token refresh).
  static const String? refreshToken = null;
}
