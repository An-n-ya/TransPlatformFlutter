import '../../../domain/models/auth_response.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import 'auth_repository.dart';

/// Remote implementation of [AuthRepository].
///
/// After a successful login/register, the [ApiClient] is automatically
/// updated with the new access/refresh tokens.
class AuthRepositoryRemote implements AuthRepository {
  final ApiClient _api;

  AuthRepositoryRemote({required ApiClient apiClient}) : _api = apiClient;

  @override
  Future<Result<AuthResponse>> register({
    required String username,
    required String nickname,
    required String password,
  }) async {
    final result = await _api.post<AuthResponse>(
      '/api/v1/auth/register',
      body: {
        'username': username,
        'nickname': nickname,
        'password': password,
      },
      fromData: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
    if (result is Ok<AuthResponse>) {
      _api.setTokens(
        access: result.value.accessToken,
        refresh: result.value.refreshToken,
      );
    }
    return result;
  }

  @override
  Future<Result<AuthResponse>> login({
    required String username,
    required String password,
  }) async {
    final result = await _api.post<AuthResponse>(
      '/api/v1/auth/login',
      body: {
        'username': username,
        'password': password,
      },
      fromData: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
    if (result is Ok<AuthResponse>) {
      _api.setTokens(
        access: result.value.accessToken,
        refresh: result.value.refreshToken,
      );
    }
    return result;
  }

  @override
  Future<Result<AuthResponse>> refreshToken(String refreshToken) async {
    final result = await _api.post<AuthResponse>(
      '/api/v1/auth/refresh',
      body: {'refreshToken': refreshToken},
      fromData: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
    if (result is Ok<AuthResponse>) {
      _api.setTokens(
        access: result.value.accessToken,
        refresh: result.value.refreshToken,
      );
    }
    return result;
  }
}
