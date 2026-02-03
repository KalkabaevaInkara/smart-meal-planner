import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'notification_service.dart';

class WebsocketService {
  StompClient? _client;
  bool _connecting = false;

  void connect({required String url}) {
    if (_client != null || _connecting) return;

    _connecting = true;
    NotificationService.instance.info('Подключаю уведомления...');

    // Преобразуем http/https в ws/wss
    final wsUrl = url
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://')
        .replaceFirst('/api', '/ws');

    print('🔗 WebSocket URL: $wsUrl');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 20),
        onConnect: (StompFrame frame) {
          print('✅ WS CONNECTED');
          _connecting = false;
          NotificationService.instance.success('Уведомления подключены ✅');

          _client!.subscribe(
            destination: '/topic/updates',
            callback: (frame) {
              final msg = frame.body ?? '';
              print('📩 WS MSG: $msg');
              if (msg.isNotEmpty) {
                NotificationService.instance.info(msg);
              }
            },
          );
        },

        onWebSocketError: (e) {
          print('❌ WS ERROR: $e');
          _connecting = false;
          NotificationService.instance.warning('Уведомления недоступны (это не критично)');
        },

        onStompError: (f) {
          print('❌ STOMP ERROR: ${f.body}');
          _connecting = false;
        },

        onDisconnect: (_) {
          print('🔌 WS DISCONNECTED');
          _connecting = false;
        },

        onUnhandledFrame: (frame) {
          print('⚠️ Unhandled frame: ${frame.command}');
        },
      ),
    );

    try {
      _client!.activate();
    } catch (e) {
      print('❌ Ошибка активации WS: $e');
      _connecting = false;
      NotificationService.instance.warning('WebSocket недоступен');
    }
  }

  void disconnect() {
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
    _connecting = false;
  }
}
