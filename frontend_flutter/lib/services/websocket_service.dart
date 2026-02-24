import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_service.dart';

class WebsocketService {
  WebsocketService._();
  static final instance = WebsocketService._();

  WebSocket? _socket;
  bool _connecting = false;
  int _reconnectAttempts = 0;
  Timer? _pingTimer;
  final Map<String, List<void Function(dynamic)>> _listeners = {};
  final List<String> _outgoing = [];

  /// Connect to WS (accepts http/https and converts to ws/wss)
  Future<void> connect(String url) async {
    if (_socket != null || _connecting) return;
    _connecting = true;
    NotificationService.instance.info('Подключаюсь к WebSocket...');

    final wsUrl = url
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://');

    // Add auth header if token available
    final headers = <String, dynamic>{};
    try {
      final token = await ApiService.getToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    } catch (_) {}

    try {
      final uri = Uri.parse(wsUrl);
      _socket = await WebSocket.connect(uri.toString(), headers: headers.cast<String, Object>());
      _onOpen();
    } catch (e) {
      _connecting = false;
      _scheduleReconnect(url);
      NotificationService.instance.warning('Не удалось подключиться к WebSocket');
    }
  }

  void _onOpen() {
    _connecting = false;
    _reconnectAttempts = 0;
    NotificationService.instance.success('WebSocket подключён');

    _socket!.listen(_onMessage, onDone: () {
      _cleanupSocket();
      _scheduleReconnect(_lastUrl ?? '');
    }, onError: (e) {
      _cleanupSocket();
      _scheduleReconnect(_lastUrl ?? '');
    });

    // start ping
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      try {
        _socket?.add(jsonEncode({'type': 'ping'}));
      } catch (_) {}
    });

    // flush outgoing
    for (final m in List.from(_outgoing)) {
      _socket?.add(m);
      _outgoing.remove(m);
    }
  }

  String? _lastUrl;

  void _onMessage(dynamic data) {
    dynamic msg;
    if (data is String) {
      try {
        msg = jsonDecode(data);
      } catch (_) {
        msg = data;
      }
    } else {
      msg = data;
    }

    // dispatch by topic or type
    if (msg is Map && msg['topic'] != null) {
      final topic = msg['topic'] as String;
      final handlers = _listeners[topic] ?? [];
      for (final h in handlers) {
        try {
          h(msg['payload']);
        } catch (_) {}
      }
    } else if (msg is Map && msg['type'] != null) {
      final type = msg['type'] as String;
      final handlers = _listeners[type] ?? [];
      for (final h in handlers) {
        try {
          h(msg);
        } catch (_) {}
      }
    } else {
      // broadcast
      final handlers = _listeners['__all__'] ?? [];
      for (final h in handlers) {
        try {
          h(msg);
        } catch (_) {}
      }
    }
  }

  void subscribe(String topic, void Function(dynamic) handler) {
    _listeners.putIfAbsent(topic, () => []).add(handler);
  }

  void unsubscribe(String topic, void Function(dynamic) handler) {
    final list = _listeners[topic];
    list?.remove(handler);
    if (list != null && list.isEmpty) _listeners.remove(topic);
  }

  Future<void> send(String topic, dynamic payload) async {
    final msg = jsonEncode({'topic': topic, 'payload': payload});
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(msg);
    } else {
      _outgoing.add(msg);
    }
  }

  void _cleanupSocket() {
    try {
      _pingTimer?.cancel();
    } catch (_) {}
    try {
      _socket = null;
    } catch (_) {}
    _connecting = false;
  }

  void _scheduleReconnect(String url) {
    _reconnectAttempts++;
    _lastUrl = url;
    final maxBackoff = 64;
    final base = min(maxBackoff, (1 << (_reconnectAttempts)).toInt());
    final jitter = Random().nextInt(3);
    final delay = Duration(seconds: base + jitter);
    if (kDebugMode) print('WS reconnect in ${delay.inSeconds}s (attempt=$_reconnectAttempts)');
    Future.delayed(delay, () {
      if (_socket != null && _socket!.readyState == WebSocket.open) return;
      connect(url);
    });
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close(WebSocketStatus.normalClosure);
    } catch (_) {}
    _cleanupSocket();
    _reconnectAttempts = 0;
    _listeners.clear();
    _outgoing.clear();
  }
}

