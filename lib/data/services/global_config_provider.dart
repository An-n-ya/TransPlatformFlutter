import 'package:flutter/foundation.dart';

/// Global app configuration.
///
/// Central place for app-wide settings that should survive across
/// pages and sessions, e.g.:
/// - [debugMode]: toggles debug info display
/// - [apiBaseUrl]: which backend server to use (local / remote)
class GlobalConfigProvider extends ChangeNotifier {
  bool _debugMode = false;
  String _apiBaseUrl;

  GlobalConfigProvider({String initialBaseUrl = ''})
      : _apiBaseUrl = initialBaseUrl;

  bool get debugMode => _debugMode;
  String get apiBaseUrl => _apiBaseUrl;

  void setDebugMode(bool value) {
    _debugMode = value;
    notifyListeners();
  }

  void setApiBaseUrl(String url) {
    _apiBaseUrl = url;
    notifyListeners();
  }
}
