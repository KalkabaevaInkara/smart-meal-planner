import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'network_exceptions.dart';
import 'network_client.dart';
import 'navigation_service.dart';
import '../models/recipe.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Duration _timeout = const Duration(seconds: 15);
  static int _maxRetries = 3;

  static String? _token;

  // ================== AUTH ==================

  static Future<Map<String, dynamic>> register(
      String email,
      String fullName,
      String password) async {

    final uri = Uri.parse("$baseUrl/api/users/register");
    _logRequest('POST', uri.toString());

    final response = await _retryableRequest(() =>
        NetworkClient.instance.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email,
            "fullName": fullName,
            "password": password,
          }),
        ));

    final body = _handleResponse(response);

    // 🔥 гарантируем наличие данных
    body['email'] ??= email;
    body['fullName'] ??= fullName;

    await _persistAuth(body);

    return body;
  }

  static Future<Map<String, dynamic>> login(
      String email,
      String password) async {

    final uri = Uri.parse("$baseUrl/api/users/login");
    _logRequest('POST', uri.toString());

    final response = await _retryableRequest(() =>
        NetworkClient.instance.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email,
            "password": password,
          }),
        ));

    final body = _handleResponse(response);

    body['email'] ??= email;
    body['fullName'] ??= email;

    await _persistAuth(body);

    return body;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }

  // ================== TOKEN ==================

  static Future<void> _persistAuth(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data['token'] != null) {
      _token = data['token'];
      await prefs.setString('auth_token', data['token']);
    }

    if (data['role'] != null) {
      await prefs.setString('user_role', data['role']);
    }

    await prefs.setString(
        'email',
        data['email'] ?? ''
    );

    await prefs.setString(
        'fullName',
        data['fullName'] ?? data['email'] ?? 'Пользователь'
    );
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json'
    };

    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ================== RETRY ==================

  static Future<http.Response> _retryableRequest(
      Future<http.Response> Function() request) async {

    int attempts = 0;

    while (attempts < _maxRetries) {
      try {
        return await request().timeout(_timeout);
      } on TimeoutException {
        attempts++;
        if (attempts >= _maxRetries) {
          throw TimeoutNetworkException('Таймаут соединения');
        }
      } on SocketException {
        attempts++;
        if (attempts >= _maxRetries) {
          throw NetworkException('Ошибка сети');
        }
      }
    }

    throw NetworkException('Ошибка запроса');
  }

  // ================== RESPONSE ==================

  static Map<String, dynamic> _handleResponse(http.Response response) {

    if (response.statusCode >= 200 && response.statusCode < 300) {

      if (response.body.isEmpty) {
        return {};
      }

      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'raw': response.body};
      }

    } else {

      String errorMessage = 'Ошибка ${response.statusCode}';

      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          errorMessage =
              body['message'] ??
              body['error'] ??
              errorMessage;
        }
      } catch (_) {}

      if (response.statusCode == 401 ||
          response.statusCode == 403) {

        ApiService.logout();

        NavigationService.navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/login', (r) => false);

        throw AuthException(response.statusCode, errorMessage);
      }

      throw ApiException(response.statusCode, errorMessage);
    }
  }

  // ================== RECIPES ==================

  static Future<List<Recipe>> fetchRecipes() async {
    final uri = Uri.parse("$baseUrl/api/recipes");
    _logRequest('GET', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.get(uri, headers: headers));

    final body = _handleResponse(response);

    if (body['recipes'] is List) {
      return List<Map<String, dynamic>>.from(body['recipes']).map((r) => Recipe.fromJson(r)).toList();
    }

    return [];
  }

  static Future<Recipe> fetchRecipeById(int id) async {
    if (id <= 0) throw Exception('Invalid recipe ID');

    final uri = Uri.parse("$baseUrl/api/recipes/$id");
    _logRequest('GET', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.get(uri, headers: headers));

    final body = _handleResponse(response);
    return Recipe.fromJson(body);
  }

  static Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> recipeData) async {
    final uri = Uri.parse("$baseUrl/api/recipes");
    _logRequest('POST', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.post(uri,
            headers: headers,
            body: jsonEncode(recipeData)));

    return _handleResponse(response);
  }

  static Future<void> deleteRecipe(int id) async {
    final uri = Uri.parse("$baseUrl/api/recipes/$id");
    _logRequest('DELETE', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.delete(uri, headers: headers));

    _handleResponse(response);
  }

  static Future<List<Recipe>> searchRecipes(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse("$baseUrl/api/recipes/search").replace(queryParameters: {'q': query});
    _logRequest('GET', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.get(uri, headers: headers));

    final body = _handleResponse(response);

    if (body['recipes'] is List) {
      return List<Map<String, dynamic>>.from(body['recipes']).map((r) => Recipe.fromJson(r)).toList();
    }

    return [];
  }

  static Future<List<String>> fetchDifficulties() async {
    final uri = Uri.parse("$baseUrl/api/recipes/difficulties");
    _logRequest('GET', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.get(uri, headers: headers));

    final body = _handleResponse(response);

    if (body['difficulties'] is List) {
      return List<String>.from(body['difficulties']);
    }

    // Fallback
    return ['Легко', 'Средне', 'Сложно'];
  }

  // ================== PROFILE ==================

  static Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse("$baseUrl/api/users/profile");
    _logRequest('GET', uri.toString());

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() =>
        NetworkClient.instance.get(uri, headers: headers));

    return _handleResponse(response);
  }

  static Future<void> requestPasswordReset(String email) async {
    final uri = Uri.parse("$baseUrl/api/users/request-reset");
    _logRequest('POST', uri.toString());

    final response = await _retryableRequest(() =>
        NetworkClient.instance.post(uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email})));

    _handleResponse(response);
  }

  // ================== LOGGING ==================

  static final List<String> _requestLog = [];

  static void _logRequest(String method, String url) {
    _requestLog.add('$method $url');
  }

  static List<String> getRequestLog() {
    return List.from(_requestLog);
  }

  static void clearRequestLog() {
    _requestLog.clear();
  }

  // ================== TEST HELPERS ==================

  static String? getTokenSync() {
    return _token;
  }

  static void setTimeoutForTests(Duration? timeout) {
    if (timeout != null) {
      _timeout = timeout;
    }
  }

  static void setMaxRetriesForTests(int retries) {
    _maxRetries = retries;
  }
}