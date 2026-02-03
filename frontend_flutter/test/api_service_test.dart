import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_eating_flutter/services/api_service.dart';

void main() {
  group('ApiService - Валидация', () {
    test('_validateEmail: пустой email вызывает ошибку', () async {
      expect(
        () async => await ApiService.register('', 'John Doe', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validateEmail: некорректный формат', () async {
      expect(
        () async => await ApiService.register('invalid', 'John Doe', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validatePassword: короткий пароль', () async {
      expect(
        () async => await ApiService.register('test@test.com', 'John Doe', '1234567'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validatePassword: пароль без цифр', () async {
      expect(
        () async => await ApiService.register('test@test.com', 'John Doe', 'password'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validateFullName: пустое имя', () async {
      expect(
        () async => await ApiService.register('test@test.com', '', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('_validateFullName: короткое имя', () async {
      expect(
        () async => await ApiService.register('test@test.com', 'A', 'password123'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ApiService - Обработка ошибок', () {
    test('getRecipeById: выброс Exception для ID <= 0', () async {
      expect(
        () => ApiService.fetchRecipeById(0),
        throwsA(isA<Exception>()),
      );
    });

    test('searchRecipes: пустая строка возвращает пустой список', () async {
      final result = await ApiService.searchRecipes('');
      expect(result, isEmpty);
    });

    test('fetchDifficulties: fallback возвращает список по умолчанию', () async {
      final result = await ApiService.fetchDifficulties();
      expect(result, isNotEmpty);
      expect(result, contains('Легко'));
    });
  });

  group('ApiService - Логирование', () {
    setUp(() {
      ApiService.clearRequestLog();
    });

    test('getRequestLog: возвращает пустой список вначале', () {
      expect(ApiService.getRequestLog(), isEmpty);
    });

    test('clearRequestLog: очищает логи', () {
      ApiService.clearRequestLog();
      expect(ApiService.getRequestLog(), isEmpty);
    });
  });

  group('ApiService - Токены', () {
    setUp(() {
      ApiService.clearRequestLog();
    });

    test('getTokenSync: возвращает null если токена нет', () {
      expect(ApiService.getTokenSync(), isNull);
    });

    test('getToken: возвращает Future<String?>', () async {
      final token = await ApiService.getToken();
      expect(token, isNull);
    });
  });
}
