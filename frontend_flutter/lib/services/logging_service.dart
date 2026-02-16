import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'network_client.dart';

class LoggingService {
  LoggingService._();
  static final instance = LoggingService._();

  /// Экспорт логов из SharedPreferences (через NetworkClient) в файл и возвращает путь файла
  Future<String?> exportLogsToFile({String fileName = 'network_logs.txt'}) async {
    try {
      final logs = await NetworkClient.instance.readLogs();
      final content = logs.join('\n');
      Directory dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = Directory.systemTemp;
      }
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Отправляет логи на удалённый endpoint в формате JSON {logs: [...]}
  Future<bool> sendLogsToEndpoint(String endpointUrl, {Map<String, String>? headers}) async {
    try {
      final logs = await NetworkClient.instance.readLogs();
      final uri = Uri.parse(endpointUrl);
      final body = jsonEncode({'logs': logs});
      final res = await NetworkClient.instance.post(uri, headers: headers ?? {'Content-Type': 'application/json'}, body: body);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
}
