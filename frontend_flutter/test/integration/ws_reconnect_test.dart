import 'dart:io';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_eating_flutter/services/websocket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpServer? server;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    int connCount = 0;
    server!.listen((HttpRequest req) async {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        final socket = await WebSocketTransformer.upgrade(req);
        connCount++;
        if (connCount == 1) {
          // close quickly to trigger reconnect
          await Future.delayed(Duration(milliseconds: 200));
          await socket.close(WebSocketStatus.goingAway);
        } else {
          // send a message after a short delay
          await Future.delayed(Duration(milliseconds: 200));
          socket.add('{"topic":"greet","payload":"hello"}');
        }
      } else {
        req.response.statusCode = 404;
        await req.response.close();
      }
    });
  });

  tearDownAll(() async {
    await server?.close(force: true);
    await WebsocketService.instance.disconnect();
  });

  test('WebSocket reconnects and receives message', () async {
    final port = server!.port;
    final url = 'ws://127.0.0.1:$port/ws';
    final completer = Completer<String>();

    WebsocketService.instance.subscribe('greet', (payload) {
      if (!completer.isCompleted) completer.complete(payload as String);
    });

    await WebsocketService.instance.connect(url);

    final result = await completer.future.timeout(Duration(seconds: 10));
    expect(result, 'hello');
  }, timeout: Timeout(Duration(seconds: 15)));
}
