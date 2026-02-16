import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_eating_flutter/services/sftp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SftpService throws when not connected', () async {
    final svc = SftpService.instance;
    svc.disconnect();
    await expectLater(
      svc.uploadFile(
        host: 'nope',
        username: 'nope',
        localPath: '/tmp/nope',
        remotePath: '/tmp/nope',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
