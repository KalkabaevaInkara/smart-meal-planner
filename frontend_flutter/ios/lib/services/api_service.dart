import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class ApiService {
  // Конфигурация API
  // Для Android эмулятора: http://10.0.2.2:8080/api
  // Для iOS симулятора: http://localhost:8080/api
  // Для реального устройства: http://IP_ВАШЕГО_ПК:8080/api
  static const String baseUrl = "http://172.20.10.5:8080/api";

  // Таймаут для запросов
  static const Duration _timeout = Duration(seconds: 15);

  // Токен в памяти
  static String? _token;

  // ==================== АВТОРИЗАЦИЯ ====================

  /// Сохранение токена и данных пользователя
  static Future<void> _persistAuth(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (data['token'] != null) {
      _token = data['token'];
      await prefs.setString('auth_token', data['token']);
    }
    if (data['role'] != null) {
      await prefs.setString('user_role', data['role']);
    }
    if (data['fullName'] != null) {
      await prefs.setString('fullName', data['fullName']);
    }
    if (data['email'] != null) {
      await prefs.setString('email', data['email']);
    }
  }

  /// Получение сохранённого токена
  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  /// Получение заголовков с авторизацией
  static Future<Map<String, String>> _getHeaders({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Регистрация нового пользователя
  static Future<Map<String, dynamic>> register(String email, String fullName, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "fullName": fullName,
              "password": password,
            }),
          )
          .timeout(_timeout);

      final body = _handleResponse(response);
      await _persistAuth(body);
      return body;
    } on TimeoutException {
      throw Exception('Таймаут: сервер не ответил. Проверьте подключение.');
    } on SocketException {
      throw Exception('Ошибка сети: не удалось подключиться к серверу.');
    } catch (e) {
      rethrow;
    }
  }

  /// Авторизация пользователя
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(_timeout);

      final body = _handleResponse(response);
      await _persistAuth(body);
      return body;
    } on TimeoutException {
      throw Exception('Таймаут: сервер не ответил. Проверьте подключение.');
    } on SocketException {
      throw Exception('Ошибка сети: не удалось подключиться к серверу.');
    } catch (e) {
      rethrow;
    }
  }

  /// Получение профиля пользователя
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders(auth: true);
    final response = await http
        .get(Uri.parse("$baseUrl/users/profile"), headers: headers)
        .timeout(_timeout);
    return _handleResponse(response);
  }

  /// Обновление профиля
  static Future<Map<String, dynamic>> updateProfile(String fullName) async {
    final headers = await _getHeaders(auth: true);
    final response = await http
        .put(
          Uri.parse("$baseUrl/users/profile"),
          headers: headers,
          body: jsonEncode({"fullName": fullName}),
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  /// Выход из системы
  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }

  /// Сброс пароля
  static Future<void> resetPassword(String email) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/users/forgot-password'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email}),
        )
        .timeout(_timeout);
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка при сбросе пароля');
    }
  }

  // ==================== РЕЦЕПТЫ ====================

  /// Получение списка рецептов с фильтрацией
  static Future<List<Recipe>> fetchRecipes({
    String? search,
    String? difficulty,
    int? minCalories,
    int? maxCalories,
    int? maxCookingTime,
    String sortBy = 'title',
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (difficulty != null && difficulty.isNotEmpty) params['difficulty'] = difficulty;
    if (minCalories != null) params['minCalories'] = minCalories.toString();
    if (maxCalories != null) params['maxCalories'] = maxCalories.toString();
    if (maxCookingTime != null) params['maxCookingTime'] = maxCookingTime.toString();
    params['sortBy'] = sortBy;

    final uri = Uri.parse('$baseUrl/recipes').replace(queryParameters: params);
    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Ошибка при загрузке рецептов: ${response.statusCode}');
    }
  }

  /// Получение рецепта по ID
  static Future<Recipe> fetchRecipeById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/recipes/$id')).timeout(_timeout);

    if (response.statusCode == 200) {
      return Recipe.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Рецепт не найден');
    } else {
      throw Exception('Ошибка при загрузке рецепта: ${response.statusCode}');
    }
  }

  /// Поиск рецептов
  static Future<List<Recipe>> searchRecipes(String query) async {
    final response = await http
        .get(Uri.parse('$baseUrl/recipes/search?q=$query'))
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Ошибка поиска: ${response.statusCode}');
    }
  }

  /// Получение списка сложностей
  static Future<List<String>> fetchDifficulties() async {
    final response = await http.get(Uri.parse('$baseUrl/recipes/difficulties')).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      return ['Легко', 'Средне', 'Сложно']; // fallback
    }
  }

  /// Статистика рецептов
  static Future<Map<String, dynamic>> fetchRecipeStats() async {
    final response = await http.get(Uri.parse('$baseUrl/recipes/stats')).timeout(_timeout);
    return _handleResponse(response);
  }

  // ==================== ИНГРЕДИЕНТЫ ====================

  /// Получение всех ингредиентов
  static Future<List<Ingredient>> fetchIngredients() async {
    final response = await http.get(Uri.parse('$baseUrl/ingredients')).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Ingredient.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Ошибка при загрузке ингредиентов');
    }
  }

  // ==================== ДИЕТЫ ====================

  /// Получение всех диет
  static Future<List<Map<String, dynamic>>> fetchDiets() async {
    final response = await http.get(Uri.parse('$baseUrl/diets')).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Ошибка при загрузке диет');
    }
  }

  /// Рецепты по типу диеты
  static Future<List<Recipe>> fetchRecipesByDiet(String dietName) async {
    final response = await http
        .get(Uri.parse('$baseUrl/recipes/by-diet?diet=$dietName'))
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Ошибка при загрузке рецептов по диете');
    }
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Обработка ответа сервера
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Ошибка ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          errorMessage = body['error'] ?? body['message'] ?? errorMessage;
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  /// Получение сохранённой роли пользователя
  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  /// Синхронное получение токена (для совместимости)
  static String? getTokenSync() => _token;
}
