import 'package:flutter/material.dart';
import 'catalog_screen.dart';
import 'planner_screen.dart';
import 'my_progress_screen.dart';

import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final _pages = [
    const CatalogScreen(),
    const PlannerScreen(),
    const MyProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // ✅ Показываем привет БЕЗ подключения WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationService.instance.tip('Добро пожаловать в Healthy Eating! 🥗');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_dining, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Healthy Eating',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        onPressed: () {
                          NotificationService.instance.actionable(
                            'Версия 1.0.0 готова к использованию',
                            actionLabel: 'Ок',
                            onAction: () {},
                            color: const Color(0xFF1565C0),
                            icon: Icons.app_registration,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _idx < _pages.length ? _pages[_idx] : const SizedBox(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF43A047),
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 3) {
            Navigator.pushNamed(context, '/profile');
          } else {
            setState(() => _idx = i);
            _showTabNotification(i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Каталог'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Планировщик'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Прогресс'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Доброе утро!';
    if (hour < 18) return '☀️ Добрый день!';
    return '🌙 Добрый вечер!';
  }

  void _showTabNotification(int index) {
    const messages = [
      '📖 Откройте рецепт и нажмите на него для деталей',
      '📅 Выберите блюда для завтрака, обеда и ужина',
      '📊 Отслеживайте ваш прогресс и достижения',
    ];

    if (index < messages.length) {
      NotificationService.instance.tip(messages[index]);
    }
  }
}

// WebSocket подключится автоматически к ws://172.20.10.5:8080/ws
