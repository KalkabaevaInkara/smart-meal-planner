import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

class ApiService {

  // ✅ ИСПРАВЛЕНО: Правильный IP
  static const String baseUrl = "http://172.20.10.5:8080";
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;
  
  static String? _token;
  static final List<String> _requestLog = [];

  // ==================== ЛОГИРОВАНИЕ ====================
  
  static void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    _requestLog.add(logEntry);
    if (_requestLog.length > 100) _requestLog.removeAt(0);
    print(logEntry);
  }

  static List<String> getRequestLog() => List.from(_requestLog);
  static void clearRequestLog() => _requestLog.clear();

  // ==================== RETRY ЛОГИКА ====================

  static Future<http.Response> _retryableRequest(
    Future<http.Response> Function() request, {
    int maxRetries = _maxRetries,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        _log('Попытка запроса ${attempts + 1}/$maxRetries');
        final response = await request().timeout(_timeout);
        _log('Запрос успешен: ${response.statusCode}');
        return response;
      } on TimeoutException {
        attempts++;
        if (attempts >= maxRetries) {
          _log('❌ Таймаут после $maxRetries попыток');
          throw Exception('Таймаут: сервер не ответил после $maxRetries попыток. Проверьте подключение.');
        }
        _log('⚠️ Таймаут, повторяю через 2 сек...');
        await Future.delayed(Duration(seconds: 2 * attempts));
      } on SocketException {
        attempts++;
        if (attempts >= maxRetries) {
          _log('❌ Ошибка сети после $maxRetries попыток');
          throw Exception('Ошибка сети: не удалось подключиться к серверу.');
        }
        _log('⚠️ Ошибка сети, повторяю через 2 сек...');
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    throw Exception('Неизвестная ошибка после $maxRetries попыток');
  }

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

  // ==================== ВАЛИДАЦИЯ ====================

  static String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email не может быть пустым';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(email)) return 'Некорректный формат email';
    return null;
  }

  static String? _validatePassword(String password) {
    if (password.isEmpty) return 'Пароль не может быть пустым';
    if (password.length < 8) return 'Пароль должен содержать минимум 8 символов';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Пароль должен содержать цифру';
    return null;
  }

  static String? _validateFullName(String name) {
    if (name.isEmpty) return 'Имя не может быть пустым';
    if (name.length < 2) return 'Имя должно содержать минимум 2 символа';
    return null;
  }

  // ==================== АВТОРИЗАЦИЯ ====================

  /// Регистрация нового пользователя
  static Future<Map<String, dynamic>> register(String email, String fullName, String password) async {
    _log('📤 Регистрация: $email');
    
    final emailErr = _validateEmail(email);
    if (emailErr != null) throw Exception(emailErr);
    
    final nameErr = _validateFullName(fullName);
    if (nameErr != null) throw Exception(nameErr);
    
    final passErr = _validatePassword(password);
    if (passErr != null) throw Exception(passErr);

    try {
      final response = await _retryableRequest(() => http.post(
        Uri.parse("$baseUrl/api/users/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "fullName": fullName,
          "password": password,
        }),
      ));

      final body = _handleResponse(response);
      await _persistAuth(body);
      _log('✅ Регистрация успешна');
      return body;
    } catch (e) {
      _log('❌ Ошибка регистрации: $e');
      rethrow;
    }
  }

  /// Авторизация пользователя
  static Future<Map<String, dynamic>> login(String email, String password) async {
    _log('📤 Вход: $email');
    
    final emailErr = _validateEmail(email);
    if (emailErr != null) throw Exception(emailErr);
    
    final passErr = _validatePassword(password);
    if (passErr != null) throw Exception(passErr);

    try {
      final response = await _retryableRequest(() => http.post(
        Uri.parse("$baseUrl/api/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ));

      final body = _handleResponse(response);
      await _persistAuth(body);
      _log('✅ Вход успешен');
      return body;
    } catch (e) {
      _log('❌ Ошибка входа: $e');
      rethrow;
    }
  }

  /// Получение профиля пользователя
  static Future<Map<String, dynamic>> getProfile() async {
    _log('📥 Получение профиля');
    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.get(Uri.parse("$baseUrl/api/users/profile"), headers: headers));
    _log('✅ Профиль получен');
    return _handleResponse(response);
  }

  /// Обновление профиля
  static Future<Map<String, dynamic>> updateProfile(String fullName) async {
    _log('📤 Обновление профиля: $fullName');
    
    final nameErr = _validateFullName(fullName);
    if (nameErr != null) throw Exception(nameErr);

    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.put(
      Uri.parse("$baseUrl/api/users/profile"),
      headers: headers,
      body: jsonEncode({"fullName": fullName}),
    ));
    _log('✅ Профиль обновлен');
    return _handleResponse(response);
  }

  /// Выход из системы
  static Future<void> logout() async {
    _log('🚪 Выход из системы');
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    _log('✅ Выход успешен');
  }

  /// Сброс пароля
  static Future<void> resetPassword(String email) async {
    _log('📧 Сброс пароля: $email');
    
    final emailErr = _validateEmail(email);
    if (emailErr != null) throw Exception(emailErr);

    final response = await _retryableRequest(() => http.post(
      Uri.parse('$baseUrl/api/users/forgot-password'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    ));
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      _log('❌ Ошибка сброса пароля');
      throw Exception('Ошибка при сбросе пароля');
    }
    _log('✅ Письмо отправлено');
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
    print('🔵 fetchRecipes вызвана');
    print('📍 URL: $baseUrl/api/recipes');
    
    _log('📥 Загрузка рецептов: search=$search, difficulty=$difficulty, sortBy=$sortBy');
    
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search.trim();
    if (difficulty != null && difficulty.isNotEmpty) params['difficulty'] = difficulty;
    if (minCalories != null && minCalories > 0) params['minCalories'] = minCalories.toString();
    if (maxCalories != null && maxCalories > 0) params['maxCalories'] = maxCalories.toString();
    if (maxCookingTime != null && maxCookingTime > 0) params['maxCookingTime'] = maxCookingTime.toString();
    params['sortBy'] = sortBy;

    final uri = Uri.parse('$baseUrl/api/recipes').replace(queryParameters: params);
    print('🔗 Полный URL: $uri');
    
    final response = await _retryableRequest(() => http.get(uri));

    print('📊 Статус ответа: ${response.statusCode}');
    print('📝 Тело ответа: ${response.body.substring(0, 100)}...');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('✅ Декодировано ${data.length} рецептов');
      _log('✅ Загружено ${data.length} рецептов');
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      print('❌ Ошибка: ${response.statusCode}');
      _log('❌ Ошибка загрузки рецептов: ${response.statusCode}');
      throw Exception('Ошибка при загрузке рецептов: ${response.statusCode}');
    }
  }
  
  /// Получение рецепта по ID
  static Future<Recipe> fetchRecipeById(int id) async {
    _log('📥 Загрузка рецепта ID=$id');
    
    if (id <= 0) throw Exception('ID рецепта должен быть больше 0');

    final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/recipes/$id')));

    if (response.statusCode == 200) {
      _log('✅ Рецепт загружен');
      return Recipe.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      _log('⚠️ Рецепт не найден');
      throw Exception('Рецепт не найден');
    } else {
      _log('❌ Ошибка загрузки рецепта: ${response.statusCode}');
      throw Exception('Ошибка при загрузке рецепта: ${response.statusCode}');
    }
  }

  /// Поиск рецептов
  static Future<List<Recipe>> searchRecipes(String query) async {
    if (query.isEmpty) return [];
    
    _log('🔍 Поиск рецептов: "$query"');
    final encoded = Uri.encodeQueryComponent(query.trim());
    final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/recipes/search?q=$encoded')));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _log('✅ Найдено ${data.length} рецептов');
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      _log('❌ Ошибка поиска: ${response.statusCode}');
      throw Exception('Ошибка поиска: ${response.statusCode}');
    }
  }

  /// Получение списка сложностей
  static Future<List<String>> fetchDifficulties() async {
    _log('📥 Загрузка сложностей');
    try {
      final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/recipes/difficulties')));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _log('✅ Загружены сложности');
        return data.cast<String>();
      }
    } catch (e) {
      _log('⚠️ Ошибка загрузки сложностей, используем fallback');
    }
    return ['Легко', 'Средне', 'Сложно'];
  }

  /// Статистика рецептов
  static Future<Map<String, dynamic>> fetchRecipeStats() async {
    _log('📥 Загрузка статистики');
    final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/recipes/stats')));
    _log('✅ Статистика загружена');
    return _handleResponse(response);
  }

  // ==================== ИНГРЕДИЕНТЫ ====================

  /// Получение всех ингредиентов
  static Future<List<Ingredient>> fetchIngredients() async {
    _log('📥 Загрузка ингредиентов');
    final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/ingredients')));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _log('✅ Загружено ${data.length} ингредиентов');
      return data.map((json) => Ingredient.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      _log('❌ Ошибка загрузки ингредиентов');
      throw Exception('Ошибка при загрузке ингредиентов');
    }
  }

  // ==================== ДИЕТЫ ====================

  /// Получение всех диет
  static Future<List<Map<String, dynamic>>> fetchDiets() async {
    _log('📥 Загрузка диет');
    final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/diets')));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _log('✅ Загружены диеты');
      return data.cast<Map<String, dynamic>>();
    } else {
      _log('❌ Ошибка загрузки диет');
      throw Exception('Ошибка при загрузке диет');
    }
  }

  /// Рецепты по типу диеты
  static Future<List<Recipe>> fetchRecipesByDiet(String dietName) async {
    if (dietName.isEmpty) throw Exception('Название диеты не может быть пустым');
    
    _log('📥 Загрузка рецептов по диете: $dietName');
    final response = await _retryableRequest(() => http.get(Uri.parse('$baseUrl/api/recipes/by-diet?diet=${Uri.encodeQueryComponent(dietName)}')));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _log('✅ Загружены рецепты по диете');
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      _log('❌ Ошибка загрузки рецептов по диете');
      throw Exception('Ошибка при загрузке рецептов по диете');
    }
  }

  // ==================== АДМИН-ФУНКЦИИ ====================

  /// Создание нового рецепта
  static Future<Recipe> createRecipe({
    required String title,
    required String description,
    required int calories,
    required double proteins,
    required double fats,
    required double carbs,
    required int cookingTime,
    required String difficulty,
    String? imageUrl,
  }) async {
    _log('📤 Создание рецепта: $title');
    
    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.post(
      Uri.parse('$baseUrl/api/recipes'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'calories': calories,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'cookingTime': cookingTime,
        'difficulty': difficulty,
        'imageUrl': imageUrl ?? '',
      }),
    ));

    if (response.statusCode == 201 || response.statusCode == 200) {
      _log('✅ Рецепт создан');
      return Recipe.fromJson(jsonDecode(response.body));
    } else {
      _log('❌ Ошибка создания рецепта: ${response.statusCode}');
      throw Exception('Ошибка при создании рецепта');
    }
  }

  /// Удаление рецепта
  static Future<void> deleteRecipe(int id) async {
    _log('🗑️ Удаление рецепта ID=$id');
    
    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.delete(
      Uri.parse('$baseUrl/api/recipes/$id'),
      headers: headers,
    ));

    if (response.statusCode == 200 || response.statusCode == 204) {
      _log('✅ Рецепт удалён');
    } else if (response.statusCode == 404) {
      _log('⚠️ Рецепт не найден');
      throw Exception('Рецепт не найден');
    } else {
      _log('❌ Ошибка удаления рецепта: ${response.statusCode}');
      throw Exception('Ошибка при удалении рецепта');
    }
  }

  /// Обновление рецепта
  static Future<Recipe> updateRecipe(
    int id, {
    String? title,
    String? description,
    int? calories,
    double? proteins,
    double? fats,
    double? carbs,
    int? cookingTime,
    String? difficulty,
  }) async {
    _log('📝 Обновление рецепта ID=$id');
    
    final headers = await _getHeaders(auth: true);
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (calories != null) body['calories'] = calories;
    if (proteins != null) body['proteins'] = proteins;
    if (fats != null) body['fats'] = fats;
    if (carbs != null) body['carbs'] = carbs;
    if (cookingTime != null) body['cookingTime'] = cookingTime;
    if (difficulty != null) body['difficulty'] = difficulty;

    final response = await _retryableRequest(() => http.put(
      Uri.parse('$baseUrl/api/recipes/$id'),
      headers: headers,
      body: jsonEncode(body),
    ));

    if (response.statusCode == 200) {
      _log('✅ Рецепт обновлён');
      return Recipe.fromJson(jsonDecode(response.body));
    } else {
      _log('❌ Ошибка обновления рецепта: ${response.statusCode}');
      throw Exception('Ошибка при обновлении рецепта');
    }
  }

  /// Получение списка всех пользователей (только для админов)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    _log('📥 Получение списка пользователей');
    
    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: headers,
    ));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _log('✅ Получен список ${data.length} пользователей');
      return data.cast<Map<String, dynamic>>();
    } else {
      _log('❌ Ошибка получения пользователей: ${response.statusCode}');
      throw Exception('Ошибка при получении пользователей');
    }
  }

  /// Удаление пользователя (только для админов)
  static Future<void> deleteUser(String email) async {
    _log('🗑️ Удаление пользователя: $email');
    
    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.delete(
      Uri.parse('$baseUrl/api/admin/users/${Uri.encodeQueryComponent(email)}'),
      headers: headers,
    ));

    if (response.statusCode == 200 || response.statusCode == 204) {
      _log('✅ Пользователь удалён');
    } else if (response.statusCode == 404) {
      _log('⚠️ Пользователь не найден');
      throw Exception('Пользователь не найден');
    } else {
      _log('❌ Ошибка удаления пользователя: ${response.statusCode}');
      throw Exception('Ошибка при удалении пользователя');
    }
  }

  /// Изменение роли пользователя (только для админов)
  static Future<void> updateUserRole(String email, String role) async {
    _log('👑 Изменение роли для: $email на $role');
    
    final headers = await _getHeaders(auth: true);
    final response = await _retryableRequest(() => http.put(
      Uri.parse('$baseUrl/api/admin/users/${Uri.encodeQueryComponent(email)}/role'),
      headers: headers,
      body: jsonEncode({'role': role}),
    ));

    if (response.statusCode == 200) {
      _log('✅ Роль пользователя обновлена');
    } else {
      _log('❌ Ошибка обновления роли: ${response.statusCode}');
      throw Exception('Ошибка при обновлении роли');
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
          errorMessage = body['error'] ?? body['message'] ?? body['detail'] ?? errorMessage;
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
