import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  LocalNotificationsService._();
  static final instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'healthy_eating_channel',
      'Healthy Eating Уведомления',
      channelDescription: 'Уведомления от приложения Healthy Eating',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // 🎯 Специальные уведомления
  Future<void> notifyMealAdded(String mealName) =>
      showNotification(
        title: '🍽️ Блюдо добавлено',
        body: '$mealName добавлено в план питания',
      );

  Future<void> notifyGoalReached() =>
      showNotification(
        title: '🎉 Поздравляем!',
        body: 'Вы достигли дневной цели по калориям',
      );

  Future<void> notifyPlanSaved() =>
      showNotification(
        title: '💾 План сохранён',
        body: 'Ваш план питания успешно сохранён',
      );

  Future<void> notifyRecipeLoaded(int count) =>
      showNotification(
        title: '✨ Рецепты загружены',
        body: 'Загружено $count рецептов',
      );
}
