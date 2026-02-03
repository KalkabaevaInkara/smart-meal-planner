import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_preview/device_preview.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Используем edge-to-edge — системные панели видимы, приложение рендерится корректно
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Отключён DevicePreview — убирает рамку/панель вокруг эмуляции устройства
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const MyApp(),
    ),
  );
}
