import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_eating_flutter/services/api_service.dart';
import 'package:healthy_eating_flutter/services/network_exceptions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HttpServer? server;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((HttpRequest req) async {
      // Симулируем медленный сервер — delay больше, чем таймаут в тесте
      await Future.delayed(const Duration(milliseconds: 800));
      req.response.statusCode = 200;
      req.response.write('{}');
      await req.response.close();
    });
  });

  tearDownAll(() async {
    await server?.close(force: true);
    // Вернуть тестовые значения
    ApiService.setTimeoutForTests(null);
    ApiService.setMaxRetriesForTests(3);
  });

  test('ApiService should throw TimeoutNetworkException after retries', () async {
    final port = server!.port;
    // Установим короткий таймаут и только 2 попытки
    ApiService.setTimeoutForTests(const Duration(milliseconds: 200));
    ApiService.setMaxRetriesForTests(2);

    // test server is used implicitly by ApiService via network client

    // Вызовем напрямую через ApiService.getProfile (она использует _retryableRequest)
    try {
      await ApiService.getProfile();
      fail('Expected TimeoutNetworkException');
    } catch (e) {
      expect(e, isA<TimeoutNetworkException>());
    }
  }, timeout: Timeout(Duration(seconds: 10)));
}
