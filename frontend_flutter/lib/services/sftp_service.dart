import 'dart:io';

class SftpService {
  SftpService._();
  static final instance = SftpService._();

  

  /// NOTE: Placeholder implementation. To enable real SFTP, add a suitable
  /// dependency (e.g. dartssh2) and implement the connect/upload/download methods.
  Future<bool> uploadFile({
    required String host,
    int port = 22,
    required String username,
    String? privateKeyPath,
    required String localPath,
    required String remotePath,
  }) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      throw UnsupportedError('SFTP upload via scp is supported only on desktop platforms');
    }

    final args = <String>[];
    if (privateKeyPath != null && privateKeyPath.isNotEmpty) {
      args.addAll(['-i', privateKeyPath]);
    }
    args.addAll(['-P', port.toString()]);
    args.add(localPath);
    args.add('$username@$host:$remotePath');

    try {
      final res = await Process.run('scp', args);
      if (res.exitCode == 0) return true;
      print('SCP exit=${res.exitCode} stdout=${res.stdout} stderr=${res.stderr}');
      return false;
    } catch (e) {
      print('SCP error: $e');
      return false;
    }
  }

  Future<bool> downloadFile({
    required String host,
    int port = 22,
    required String username,
    String? privateKeyPath,
    required String remotePath,
    required String localPath,
  }) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      throw UnsupportedError('SFTP download via scp is supported only on desktop platforms');
    }

    final args = <String>[];
    if (privateKeyPath != null && privateKeyPath.isNotEmpty) {
      args.addAll(['-i', privateKeyPath]);
    }
    args.addAll(['-P', port.toString()]);
    args.add('$username@$host:$remotePath');
    args.add(localPath);

    try {
      final res = await Process.run('scp', args);
      if (res.exitCode == 0) return true;
      print('SCP exit=${res.exitCode} stdout=${res.stdout} stderr=${res.stderr}');
      return false;
    } catch (e) {
      print('SCP error: $e');
      return false;
    }
  }

  void disconnect() {
    // No persistent connection in this scp-based implementation.
    return;
  }
}
