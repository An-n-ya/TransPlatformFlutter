import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/result.dart';
import 'api_response.dart';
import 'page_result.dart';

/// HTTP client wrapper for the backend API.
///
/// Manages base URL, JWT authentication, and unified
/// [ApiResponse] parsing.
class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  String? _accessToken;
  String? _refreshToken;

  ApiClient({
    // this.baseUrl = 'http://100.122.220.40:8081',
    this.baseUrl = 'http://localhost:8081',
    http.Client? httpClient,
    String? accessToken,
    String? refreshToken,
  })  : _httpClient = httpClient ?? http.Client(),
        _accessToken = accessToken,
        _refreshToken = refreshToken;

  // ---- Token management ----

  bool get isAuthenticated => _accessToken != null;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ---- HTTP methods ----

  /// GET request, returns parsed [ApiResponse].
  Future<Result<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromData,
  }) async {
    return _request(
      () => _httpClient.get(
        _buildUri(path, queryParams),
        headers: _headers,
      ),
      fromData,
    );
  }

  /// GET request expecting a [PageResult].
  Future<Result<PageResult<T>>> getPage<T>(
    String path, {
    Map<String, String>? queryParams,
    required T Function(dynamic) fromItem,
  }) async {
    final result = await get<List<dynamic>>(
      path,
      queryParams: queryParams,
      fromData: null, // we parse manually
    );
    switch (result) {
      case Ok<List<dynamic>>():
        // The ApiResponse's data is already the full page JSON object
        // But we need the raw map. Let's re-fetch.
        return _requestPage(path, queryParams, fromItem);
      case Error<List<dynamic>>():
        return Result.error(result.error);
    }
  }

  /// POST request with JSON body.
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromData,
  }) async {
    return _request(
      () => _httpClient.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      fromData,
    );
  }

  /// PUT request with JSON body.
  Future<Result<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromData,
  }) async {
    return _request(
      () => _httpClient.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      fromData,
    );
  }

  /// DELETE request.
  Future<Result<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromData,
  }) async {
    return _request(
      () => _httpClient.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      ),
      fromData,
    );
  }

  // ---- Internal helpers ----

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Result<T>> _request<T>(
    Future<http.Response> Function() requestFn,
    T Function(dynamic)? fromData,
  ) async {
    try {
      final response = await requestFn();

      // Handle non-2xx HTTP status codes (e.g. 403 with empty body)
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Try to parse error body, fall back to status code message
        if (response.body.isEmpty) {
          return Result.error(
            ApiException(response.statusCode, 'HTTP ${response.statusCode}'),
          );
        }
        try {
          final errBody = jsonDecode(response.body) as Map<String, dynamic>;
          return Result.error(
            ApiException(
              errBody['code'] as int? ?? response.statusCode,
              errBody['message'] as String? ?? 'Unknown error',
            ),
          );
        } catch (_) {
          return Result.error(
            ApiException(response.statusCode, 'HTTP ${response.statusCode}'),
          );
        }
      }

      // Handle empty success body (e.g. DELETE returns 200 with no content)
      if (response.body.isEmpty) {
        return Result.ok(null as T);
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(body, fromData);

      if (apiResponse.isSuccess) {
        return Result.ok(apiResponse.data as T);
      } else {
        return Result.error(
          ApiException(apiResponse.code, apiResponse.message),
        );
      }
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<PageResult<T>>> _requestPage<T>(
    String path,
    Map<String, String>? queryParams,
    T Function(dynamic) fromItem,
  ) async {
    try {
      final response = await _httpClient.get(
        _buildUri(path, queryParams),
        headers: _headers,
      );

      // Handle non-2xx HTTP status codes
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.body.isEmpty) {
          return Result.error(
            ApiException(response.statusCode, 'HTTP ${response.statusCode}'),
          );
        }
        try {
          final errBody = jsonDecode(response.body) as Map<String, dynamic>;
          return Result.error(
            ApiException(
              errBody['code'] as int? ?? response.statusCode,
              errBody['message'] as String? ?? 'Unknown error',
            ),
          );
        } catch (_) {
          return Result.error(
            ApiException(response.statusCode, 'HTTP ${response.statusCode}'),
          );
        }
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse =
          ApiResponse<PageResult<T>>.fromJson(body, (data) {
        return PageResult.fromJson(data as Map<String, dynamic>, fromItem);
      });

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return Result.ok(apiResponse.data!);
      } else {
        return Result.error(
          ApiException(apiResponse.code, apiResponse.message),
        );
      }
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}

/// Exception thrown when the API returns a non-200 code.
class ApiException implements Exception {
  final int code;
  final String message;

  const ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}
