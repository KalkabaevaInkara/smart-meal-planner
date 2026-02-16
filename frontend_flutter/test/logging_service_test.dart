import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthy_eating_flutter/services/logging_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export logs to file writes file and returns path', () async {
    SharedPreferences.setMockInitialValues({
      'network_logs': '["log1","log2"]'
    });

    final path = await LoggingService.instance.exportLogsToFile(fileName: 'test_logs.txt');
    expect(path, isNotNull);
    final file = File(path!);
    final content = await file.readAsString();
    expect(content.contains('log1'), isTrue);
  });
}
