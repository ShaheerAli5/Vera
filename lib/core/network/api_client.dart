import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.config,
    http.Client? httpClient,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    String? initialAuthToken,
    String? initialRefreshToken,
  })  : _httpClient = httpClient ?? http.Client(),
        _authToken = initialAuthToken,
        _refreshToken = initialRefreshToken;

  static const _authTokenKey = 'vera_auth_token';
  static const _refreshTokenKey = 'vera_refresh_token';

  final AppConfig config;
  final http.Client _httpClient;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  String? _authToken;
  String? get authToken => _authToken;

  String? _refreshToken;
  String? get refreshToken => _refreshToken;

  Future<bool>? _ongoingRefresh;
  void Function()? onSessionExpired;

  Future<void> initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAuth = prefs.getString(_authTokenKey);
      final savedRefresh = prefs.getString(_refreshTokenKey);
      _authToken = (savedAuth != null && savedAuth.trim().isNotEmpty && savedAuth != 'null')
          ? savedAuth.trim()
          : null;
      _refreshToken = (savedRefresh != null && savedRefresh.trim().isNotEmpty && savedRefresh != 'null')
          ? savedRefresh.trim()
          : null;
    } catch (_) {}
  }

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    await _saveToken(_authTokenKey, token);
  }

  Future<void> setRefreshToken(String? token) async {
    _refreshToken = token;
    await _saveToken(_refreshTokenKey, token);
  }

  Future<void> setTokens({String? authToken, String? refreshToken}) async {
    _authToken = authToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _saveToken(_authTokenKey, authToken),
      _saveToken(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    _authToken = null;
    _refreshToken = null;
    await Future.wait([
      _removeToken(_authTokenKey),
      _removeToken(_refreshTokenKey),
    ]);
  }

  Future<void> _saveToken(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value != null && value.isNotEmpty) {
        await prefs.setString(key, value);
      } else {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  Future<void> _removeToken(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Rotates the refresh token and updates both access & refresh tokens.
  Future<bool> refreshSession({String? deviceName}) async {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }

    final completer = Completer<bool>();
    _ongoingRefresh = completer.future;

    try {
      final token = _refreshToken;
      if (token == null || token.isEmpty) {
        completer.complete(false);
        return false;
      }

      final uri = config.endpoint('/auth/refresh');
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (_authToken != null && _authToken!.isNotEmpty)
            'Authorization': 'Bearer $_authToken',
        })
        ..body = jsonEncode({
          'refreshToken': token,
          'deviceName': deviceName ?? 'Vera App',
        });

      final streamed = await _httpClient.send(request).timeout(connectTimeout);
      final response =
          await http.Response.fromStream(streamed).timeout(receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final dataObj = decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : null;

          final newAccessToken = decoded['accessToken']?.toString() ??
              decoded['token']?.toString() ??
              decoded['access_token']?.toString() ??
              dataObj?['accessToken']?.toString() ??
              dataObj?['token']?.toString() ??
              dataObj?['access_token']?.toString();

          final newRefreshToken = decoded['refreshToken']?.toString() ??
              decoded['refresh_token']?.toString() ??
              dataObj?['refreshToken']?.toString() ??
              dataObj?['refresh_token']?.toString();

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await setTokens(
              authToken: newAccessToken,
              refreshToken:
                  (newRefreshToken != null && newRefreshToken.isNotEmpty)
                      ? newRefreshToken
                      : token,
            );
            completer.complete(true);
            return true;
          }
        }
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await clearTokens();
        onSessionExpired?.call();
      }
      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _ongoingRefresh = null;
    }
  }

  Future<Object?> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String> headers = const {},
  }) => _send('GET', path, queryParameters: queryParameters, headers: headers);

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send('POST', path, body: body, headers: headers);

  Future<Object?> put(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send('PUT', path, body: body, headers: headers);

  Future<Object?> patch(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send('PATCH', path, body: body, headers: headers);

  Future<Object?> delete(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => _send('DELETE', path, body: body, headers: headers);

  Future<http.Response> getRaw(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String> headers = const {},
    bool isRetry = false,
  }) async {
    final uri = config.endpoint(path, queryParameters);
    final request = http.Request('GET', uri)
      ..headers.addAll({
        if (_authToken != null && _authToken!.isNotEmpty)
          'Authorization': 'Bearer $_authToken',
        ...headers,
      });

    try {
      final streamed = await _httpClient.send(request).timeout(connectTimeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(receiveTimeout);

      if (response.statusCode == 401 &&
          !isRetry &&
          !path.contains('/auth/refresh') &&
          _refreshToken != null &&
          _refreshToken!.isNotEmpty) {
        final refreshed = await refreshSession();
        if (refreshed) {
          return await getRaw(
            path,
            queryParameters: queryParameters,
            headers: headers,
            isRetry: true,
          );
        }
      }
      return response;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        code: 'timeout',
        message: 'The request timed out.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        code: 'network_error',
        message: error.message,
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        code: 'network_error',
        message: error.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
      );
    }
  }

  Future<Object?> postMultipart(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    Map<String, String>? queryParameters,
    Map<String, String> headers = const {},
  }) async {
    final uri = config.endpoint(path, queryParameters);
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json, image/*, */*',
        if (_authToken != null && _authToken!.isNotEmpty)
          'Authorization': 'Bearer $_authToken',
        ...headers,
      });
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);

    try {
      return await _executeRequest(request);
    } on ApiException catch (e) {
      if (e.statusCode == 401 &&
          !path.contains('/auth/refresh') &&
          _refreshToken != null &&
          _refreshToken!.isNotEmpty) {
        await refreshSession();
      }
      rethrow;
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String> headers = const {},
    bool isRetry = false,
  }) async {
    final uri = config.endpoint(path, queryParameters);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        if (_authToken != null && _authToken!.isNotEmpty)
          'Authorization': 'Bearer $_authToken',
        ...headers,
      });
    if (body != null) request.body = jsonEncode(body);

    try {
      return await _executeRequest(request);
    } on ApiException catch (e) {
      if (e.statusCode == 401 &&
          !isRetry &&
          !path.contains('/auth/refresh') &&
          !path.contains('/auth/login') &&
          !path.contains('/auth/register') &&
          _refreshToken != null &&
          _refreshToken!.isNotEmpty) {
        final refreshed = await refreshSession();
        if (refreshed) {
          return _send(
            method,
            path,
            body: body,
            queryParameters: queryParameters,
            headers: headers,
            isRetry: true,
          );
        }
      }
      rethrow;
    }
  }

  Future<Object?> _executeRequest(http.BaseRequest request) async {
    try {
      final streamed = await _httpClient.send(request).timeout(connectTimeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(receiveTimeout);
      final Object? decoded;
      try {
        decoded = _decode(response.body);
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.bodyBytes;
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'The request failed with status ${response.statusCode}.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toException(response.statusCode, decoded);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        code: 'timeout',
        message: 'The request timed out.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: 0,
        code: 'network_error',
        message: error.message,
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        code: 'invalid_response',
        message: 'The server returned invalid JSON.',
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        code: 'network_error',
        message: error.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
      );
    }
  }

  Object? _decode(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  ApiException _toException(int statusCode, Object? payload) {
    if (payload is Map<String, dynamic>) {
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        return ApiException(
          statusCode: statusCode,
          code: error['code']?.toString(),
          message: _extractMessage(error) ?? 'The request failed.',
          details: error['details'],
        );
      }
      return ApiException(
        statusCode: statusCode,
        code: payload['code']?.toString(),
        message: _extractMessage(payload) ?? 'The request failed.',
        details: payload['details'],
      );
    }
    return ApiException(
      statusCode: statusCode,
      message: 'The request failed with status $statusCode.',
    );
  }

  static String? _extractMessage(Map<String, dynamic> map) {
    final raw = map['message'];
    if (raw is List) {
      return raw.map((e) => e.toString()).join('\n');
    }
    return raw?.toString();
  }

  void close() => _httpClient.close();
}
