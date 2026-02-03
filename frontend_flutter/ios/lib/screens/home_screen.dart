import 'package:flutter/material.dart';
import 'catalog_screen.dart';
import 'planner_screen.dart';
import 'my_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final _pages = [const CatalogScreen(), const PlannerScreen(), const MyProgressScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // убираем текст заголовка — заголовок теперь на экране авторизации
        toolbarHeight: kToolbarHeight,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _idx < _pages.length ? _pages[_idx] : const SizedBox(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor, // заменено на цвет темы (зелёный)
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 3) {
            Navigator.pushNamed(context, '/profile');
          } else {
            setState(() => _idx = i);
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
}
