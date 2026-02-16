class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutNetworkException extends NetworkException {
  TimeoutNetworkException([String message = 'Request timed out']) : super(message);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, [this.message = 'API error']);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthException extends ApiException {
  AuthException(int statusCode, [String message = 'Authentication error']) : super(statusCode, message);
}
