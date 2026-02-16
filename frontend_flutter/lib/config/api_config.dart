import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    // Для веб-приложения используем localhost
    if (kIsWeb) {
      return "http://localhost:8080";
    }
    
    // Для Android эмулятора
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080";
    }
    
    // Для iOS и других платформ
    return "http://172.20.10.5:8080";
  }
}
