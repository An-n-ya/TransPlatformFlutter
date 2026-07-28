/// Environment configuration for the app.
///
/// Tweak these values to match your setup.
class Env {
  Env._();

  /// Backend API base URL.
  static const String apiBaseUrl = 'http://localhost:8081';

  /// JWT access token for remote mode.
  ///
  /// Since login isn't implemented yet, set a token obtained from
  /// the backend (e.g. via Swagger UI or login endpoint).
  ///
  /// To get a fresh token for user "bob":
  /// ```bash
  /// curl -X POST http://localhost:8081/api/v1/auth/login \
  ///   -H "Content-Type: application/json" \
  ///   -d '{"username":"bob","password":"bob123"}'
  /// ```
  static const String? accessToken =
      'eyJhbGciOiJIUzM4NCJ9.eyJzdWIiOiIyIiwidXNlcm5hbWUiOiJib2IiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzg1MTYxNDg4LCJleHAiOjE3ODUyNDc4ODh9.h_Aq8o1Ejx1X_4Iscg7xhIyOpnMMsGyLL9PrV5N1dlJpijTUmTulXe9I7C4Z5Nhi';

  /// Refresh token (optional, for token refresh).
  static const String? refreshToken = null; // ignore: unnecessary_nullable_for_final_variable_declarations
}
