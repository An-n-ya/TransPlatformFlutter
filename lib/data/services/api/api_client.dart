import 'dart:async';
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
  final Duration _timeout;
  String? _accessToken;
  String? _refreshToken;

  ApiClient({
    this.baseUrl = 'http://localhost:8081',
    http.Client? httpClient,
    String? accessToken,
    String? refreshToken,
    Duration? timeout,
  })  : _httpClient = httpClient ?? http.Client(),
        _accessToken = accessToken,
        _refreshToken = refreshToken,
        _timeout = timeout ?? const Duration(seconds: 15);

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

  /// GET request, returns parsed [ApiResponse] data.
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

  /// GET request expecting a [PageResult] — single HTTP call.
  Future<Result<PageResult<T>>> getPage<T>(
    String path, {
    Map<String, String>? queryParams,
    required T Function(dynamic) fromItem,
  }) async {
    return _request(
      () => _httpClient.get(
        _buildUri(path, queryParams),
        headers: _headers,
      ),
      (data) => PageResult.fromJson(data as Map<String, dynamic>, fromItem),
    );
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

  /// Core request handler.
  ///
  /// 1. Makes the HTTP call with timeout
  /// 2. Checks HTTP status code
  /// 3. Parses the unified [ApiResponse] wrapper
  /// 4. Extracts data via [fromData] callback
  Future<Result<T>> _request<T>(
    Future<http.Response> Function() requestFn,
    T Function(dynamic)? fromData,
  ) async {
    try {
      final response = await requestFn().timeout(_timeout);

      // ---- Non-2xx: try to parse error body, fall back to status code ----
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

      // ---- Empty body (e.g. DELETE 200 with no content) ----
      if (response.body.isEmpty) {
        return Result.ok(null as T);
      }

      // ---- Parse the unified ApiResponse wrapper ----
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(body, fromData);

      if (apiResponse.isSuccess) {
        return Result.ok(apiResponse.data as T);
      } else {
        return Result.error(
          ApiException(apiResponse.code, apiResponse.message),
        );
      }
    } on TimeoutException catch (e) {
      return Result.error(
        ApiException(0, '请求超时: $e'),
      );
    } on http.ClientException catch (e) {
      return Result.error(e);
    } on FormatException catch (e) {
      return Result.error(e);
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
