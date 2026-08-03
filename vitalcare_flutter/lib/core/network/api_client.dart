import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'current_user';

  static String? _token;
  static String? _refreshToken;
  static Map<String, dynamic>? _currentUser;
  static late final Dio _dio;

  static Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final retried = error.requestOptions.extra['retried'] == true;
          if (status == 401 && !retried && _refreshToken != null && _refreshToken!.isNotEmpty) {
            try {
              final ok = await _refreshSession();
              if (ok) {
                final opts = error.requestOptions;
                opts.extra['retried'] = true;
                opts.headers['Authorization'] = 'Bearer $_token';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (_) {
              // fall through to the original error
            }
          }
          handler.next(error);
        },
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
    }
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get token => _token;

  static String get userRole => _currentUser?['role'] as String? ?? '';
  static String get userId => _currentUser?['id'] as String? ?? '';
  static String get userEmail => _currentUser?['email'] as String? ?? '';
  static String get userFirstName => _currentUser?['first_name'] as String? ?? '';
  static String get userLastName => _currentUser?['last_name'] as String? ?? '';
  static String get userFullName => '$userFirstName $userLastName'.trim();

  static Future<void> setSession(Map<String, dynamic> user, Map<String, dynamic> session) async {
    _token = session['access_token'] as String?;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
    _refreshToken = session['refresh_token'] as String?;
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> _refreshSession() async {
    final res = await _dio.post('/auth/refresh', data: {'refresh_token': _refreshToken});
    final data = res.data;
    if (data is! Map || data['session'] is! Map) return false;
    final session = (data['session'] as Map).cast<String, dynamic>();
    _token = session['access_token'] as String?;
    final newRefresh = session['refresh_token'] as String?;
    if (newRefresh != null && newRefresh.isNotEmpty) {
      _refreshToken = newRefresh;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, newRefresh);
    }
    if (data['user'] is Map) {
      _currentUser = (data['user'] as Map).cast<String, dynamic>();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!));
    }
    return _token != null && _token!.isNotEmpty;
  }

  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post<dynamic>(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch<dynamic>(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.put<dynamic>(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete<dynamic>(endpoint);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    var message = 'Connection failed. Check your server.';
    if (data is Map) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          message = first['msg'].toString().replaceFirst('Value error, ', '');
        }
      } else if (detail != null) {
        message = detail.toString();
      }
    }
    return ApiException(status, message);
  }

  static Map<String, dynamic> _handleResponse(Response<dynamic> response) {
    final data = response.data;
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      if (data is List) {
        return {'data': data, 'count': data.length};
      }
      return data is Map<String, dynamic> ? data : {'data': data};
    }
    throw ApiException(response.statusCode ?? 0, 'Request failed');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
