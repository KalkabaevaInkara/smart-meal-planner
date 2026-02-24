import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> _safeVibrate() async {
    if (kIsWeb) return; // ❌ Web не поддерживает vibration

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {
        Vibration.vibrate(duration: 100);
      }
    } catch (_) {
      // Игнорируем если плагин не поддерживается
    }
  }

  void show(
    String text, {
    Color? color,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    List<SnackBarAction>? actions,
    bool vibrate = false,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) {
      print('💬 Уведомление: $text');
      return;
    }

    if (vibrate) {
      _safeVibrate(); // 🔥 безопасная вибрация
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: color ?? Colors.black87,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(icon ?? Icons.notifications,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: duration,
        action: actions?.isNotEmpty == true
            ? SnackBarAction(
                label: actions!.first.label,
                textColor: Colors.white,
                onPressed: actions.first.onPressed,
              )
            : null,
      ),
    );
  }

  void success(String text, {bool vibrate = true}) => show(
        text,
        color: const Color(0xFF2E7D32),
        icon: Icons.check_circle,
        vibrate: vibrate,
      );

  void info(String text, {bool vibrate = false}) => show(
        text,
        color: const Color(0xFF1565C0),
        icon: Icons.info,
        vibrate: vibrate,
      );

  void warning(String text, {bool vibrate = false}) => show(
        text,
        color: const Color(0xFFF57C00),
        icon: Icons.warning_amber,
        vibrate: vibrate,
      );

  void error(String text, {bool vibrate = true}) => show(
        text,
        color: const Color(0xFFC62828),
        icon: Icons.error,
        vibrate: vibrate,
      );

  void actionable(
    String text, {
    required String actionLabel,
    required VoidCallback onAction,
    Color? color,
    IconData? icon,
  }) {
    show(
      text,
      color: color ?? const Color(0xFF1565C0),
      icon: icon ?? Icons.info,
      duration: const Duration(seconds: 6),
      actions: [
        SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
        ),
      ],
    );
  }

  void celebrate(String text) => success('🎉 $text');

  void tip(String text) => info('💡 $text');

  void quick(String text) => show(
        text,
        color: const Color(0xFF6200EA),
        icon: Icons.flash_on,
        duration: const Duration(seconds: 2),
        vibrate: true,
      );
}