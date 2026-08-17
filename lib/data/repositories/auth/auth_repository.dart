import '../../../domain/models/auth_response.dart';
import '../../../utils/result.dart';

/// Data source for authentication (register / login / refresh).
abstract class AuthRepository {
  /// Register a new user.
  Future<Result<AuthResponse>> register({
    required String username,
    required String nickname,
    required String password,
    required String invitationCode,
  });

  /// Log in with username and password.
  Future<Result<AuthResponse>> login({
    required String username,
    required String password,
  });

  /// Refresh the access token using a refresh token.
  Future<Result<AuthResponse>> refreshToken(String refreshToken);
}
