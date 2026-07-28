import 'user.dart';

/// Auth response from backend (login / register / refresh).
///
/// ```json
/// {
///   "accessToken": "...",
///   "refreshToken": "...",
///   "tokenType": "Bearer",
///   "expiresIn": 86400,
///   "user": { ... }
/// }
/// ```
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final User user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 86400,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
