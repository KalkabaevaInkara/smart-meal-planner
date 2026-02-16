import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'network_exceptions.dart';

class ErrorHandler {
  ErrorHandler._();
  static final instance = ErrorHandler._();

  void handleAndNotify(Object error, {String? fallbackMessage}) {
    final msg = _userMessage(error) ?? fallbackMessage ?? 'Произошла ошибка';
    if (error is TimeoutNetworkException) {
      NotificationService.instance.warning(msg);
    } else if (error is AuthException) {
      NotificationService.instance.error(msg);
    } else if (error is ApiException) {
      NotificationService.instance.error(msg);
    } else if (error is NetworkException) {
      NotificationService.instance.warning(msg);
    } else {
      if (kDebugMode) {
        NotificationService.instance.info(msg);
      } else {
        NotificationService.instance.error(msg);
      }
    }
  }

  String? _userMessage(Object error) {
    if (error is TimeoutNetworkException) return error.message;
    if (error is AuthException) return error.message;
    if (error is ApiException) return error.message;
    if (error is NetworkException) return error.message;
    if (error is Exception) return error.toString();
    return null;
  }
}
