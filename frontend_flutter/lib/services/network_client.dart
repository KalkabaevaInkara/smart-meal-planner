import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkClient {
  NetworkClient._private();
  static final instance = NetworkClient._private();

  final http.Client _inner = http.Client();
  static const _logKey = 'network_logs';
  static const _maxLogs = 200;

  Future<void> _persistLog(String entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_logKey);
      final List<String> list = raw != null ? List<String>.from(jsonDecode(raw)) : [];
      list.add(entry);
      if (list.length > _maxLogs) list.removeAt(0);
      await prefs.setString(_logKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<String>> readLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_logKey);
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    final sw = Stopwatch()..start();
    final res = await _inner.get(uri, headers: headers);
    sw.stop();
    final entry = '[GET] ${uri.toString()} -> ${res.statusCode} (${sw.elapsedMilliseconds}ms)';
    _persistLog(entry);
    return res;
  }

  Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    final sw = Stopwatch()..start();
    final res = await _inner.post(uri, headers: headers, body: body);
    sw.stop();
    final entry = '[POST] ${uri.toString()} -> ${res.statusCode} (${sw.elapsedMilliseconds}ms)';
    _persistLog(entry);
    return res;
  }

  Future<http.Response> put(Uri uri, {Map<String, String>? headers, Object? body}) async {
    final sw = Stopwatch()..start();
    final res = await _inner.put(uri, headers: headers, body: body);
    sw.stop();
    final entry = '[PUT] ${uri.toString()} -> ${res.statusCode} (${sw.elapsedMilliseconds}ms)';
    _persistLog(entry);
    return res;
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers, Object? body}) async {
    final sw = Stopwatch()..start();
    final res = await _inner.delete(uri, headers: headers, body: body);
    sw.stop();
    final entry = '[DELETE] ${uri.toString()} -> ${res.statusCode} (${sw.elapsedMilliseconds}ms)';
    _persistLog(entry);
    return res;
  }
}
