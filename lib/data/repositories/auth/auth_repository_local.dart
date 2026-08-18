import '../../../domain/models/auth_response.dart';
import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import 'auth_repository.dart';

/// Local implementation of [AuthRepository] — skips real auth.
class AuthRepositoryLocal implements AuthRepository {
  @override
  Future<Result<AuthResponse>> register({
    required String username,
    required String nickname,
    required String password,
    required String invitationCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Result.ok(
      AuthResponse(
        accessToken: 'local-dev-token',
        refreshToken: 'local-dev-refresh',
        tokenType: 'Bearer',
        expiresIn: 86400,
        user: User(
          id: 1,
          username: username,
          nickname: nickname,
          avatar: 'assets/images/avatar.jpg',
        ),
      ),
    );
  }

  @override
  Future<Result<AuthResponse>> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Result.ok(
      AuthResponse(
        accessToken: 'local-dev-token',
        refreshToken: 'local-dev-refresh',
        tokenType: 'Bearer',
        expiresIn: 86400,
        user: User(
          id: 1,
          username: username,
          nickname: username,
          avatar: 'assets/images/avatar.jpg',
        ),
      ),
    );
  }

  @override
  Future<Result<AuthResponse>> refreshToken(String refreshToken) async {
    return Result.ok(
      AuthResponse(
        accessToken: 'local-dev-token-refreshed',
        refreshToken: refreshToken,
        tokenType: 'Bearer',
        expiresIn: 86400,
        user: const User(
          id: 1,
          username: 'local',
          nickname: 'Local Dev',
          avatar: 'assets/images/avatar.jpg',
        ),
      ),
    );
  }

  @override
  Future<Result<void>> sendPasswordResetCode({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Result.ok(null);
  }
}
