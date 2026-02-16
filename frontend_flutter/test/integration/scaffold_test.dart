import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_eating_flutter/services/network_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HttpServer? server;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((HttpRequest req) async {
      if (req.uri.path == '/health') {
        req.response.statusCode = 200;
        req.response.write('ok');
      } else if (req.uri.path == '/api/recipes') {
        // Simple stub: always return empty list
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write('[]');
      } else {
        req.response.statusCode = 404;
        req.response.write('not found');
      }
      await req.response.close();
    });
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('NetworkClient can reach local stub server', () async {
    final port = server!.port;
    final uri = Uri.parse('http://127.0.0.1:$port/health');
    final res = await NetworkClient.instance.get(uri);
    expect(res.statusCode, 200);
    expect(res.body, 'ok');
  });
}
