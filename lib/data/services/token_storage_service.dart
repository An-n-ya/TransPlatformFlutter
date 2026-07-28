import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT tokens to the device's secure storage
/// (Keychain on iOS, EncryptedSharedPreferences on Android).
class TokenStorageService {
  final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save both tokens after a successful login/register.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Read the stored access token. Returns null if not logged in.
  Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  /// Read the stored refresh token.
  Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  /// Check whether tokens exist (i.e. user is logged in).
  Future<bool> hasTokens() async {
    final token = await _storage.read(key: _keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored tokens (logout).
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }
}
