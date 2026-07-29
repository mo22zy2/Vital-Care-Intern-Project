import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'current_user';

  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
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
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.post(uri, headers: await _headers(), body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.patch(uri, headers: await _headers(), body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) {
        return {'data': body, 'count': body.length};
      }
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    final detail = body is Map ? (body['detail'] ?? 'Request failed') : 'Request failed';
    throw ApiException(response.statusCode, detail.toString());
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
