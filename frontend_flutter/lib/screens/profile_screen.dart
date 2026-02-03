import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'meal_history_screen.dart';
import 'goals_screen.dart';
import 'nutrition_tips_screen.dart';
import 'admin_recipes_page.dart';
import 'admin_users_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = '';
  String email = '';
  String description = '';
  String avatar = '';
  double weight = 64.5;
  List<Map<String, dynamic>> mealHistory = [];
  bool isAdmin = false;

  final List<String> healthyAvatars = [
    'https://cdn-icons-png.flaticon.com/512/415/415682.png',
    'https://cdn-icons-png.flaticon.com/512/706/706195.png',
    'https://cdn-icons-png.flaticon.com/512/2974/2974602.png',
    'https://cdn-icons-png.flaticon.com/512/620/620851.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? 'Пользователь';
      email = prefs.getString('email') ?? '';
      description = prefs.getString('description') ?? '';
      avatar = prefs.getString('avatar') ?? healthyAvatars.first;
      weight = prefs.getDouble('weight') ?? 64.5;
      isAdmin = prefs.getBool('isAdmin') ?? false;
    });

    if (email.isNotEmpty) {
      final raw = prefs.getString('meal_history_$email');
      if (raw != null) {
        try {
          final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
          mealHistory = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {
          mealHistory = [];
        }
      }
    } else {
      mealHistory = [];
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', fullName);
    await prefs.setString('email', email);
    await prefs.setString('description', description);
    await prefs.setString('avatar', avatar);
    await prefs.setDouble('weight', weight);
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: fullName);
    final descCtrl = TextEditingController(text: description);
    final weightCtrl = TextEditingController(text: weight.toString());
    String selectedAvatar = avatar;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDialog) {
        return AlertDialog(
          title: const Text('Редактировать профиль'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(radius: 45, backgroundImage: NetworkImage(selectedAvatar)),
                const SizedBox(height: 10),
                const Text('Выберите аватар:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: healthyAvatars.map((url) {
                    final selected = selectedAvatar == url;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selectedAvatar = url),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: selected ? Colors.green : Colors.transparent, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(backgroundImage: NetworkImage(url), radius: 26, backgroundColor: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Имя')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'О себе')),
                const SizedBox(height: 10),
                TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес (в кг)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                fullName = nameCtrl.text.trim();
                description = descCtrl.text.trim();
                avatar = selectedAvatar;
                weight = double.tryParse(weightCtrl.text) ?? weight;
                Navigator.pop(ctx, true);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      }),
    );

    if (result == true && mounted) {
      await _saveProfile();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён'), backgroundColor: Colors.green));
    }
  }

  void _openMealHistory() {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала войдите в аккаунт (email не указан)')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => MealHistoryScreen(email: email)));
  }

  void _openGoals() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => GoalsScreen())).then((_) => _loadProfile());
  }

  void _openTips() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionTipsScreen()));
  }

  void _adminAddRecipe() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRecipesPage())).then((_) => _loadProfile());
  }

  void _adminDeleteRecipe() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRecipesPage())).then((_) => _loadProfile());
  }

  void _adminUsers() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsersPage())).then((_) => _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget() => CircleAvatar(radius: 48, backgroundColor: Colors.green.shade50, backgroundImage: NetworkImage(avatar));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/home')),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          ApiService.logout();
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      avatarWidget(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(email.isNotEmpty ? email : 'Не указан email', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditDialog,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 18, color: Color(0xFF43A047)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('О себе', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(description.isNotEmpty ? description : 'Добавьте информацию о себе, чтобы получать персональные советы.'),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Текущий вес:', style: TextStyle(fontSize: 16)),
                                Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showEditDialog,
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Редактировать профиль'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin) ...[
                      const Text('Админ панель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _adminAddRecipe,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить рецепт'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _adminDeleteRecipe,
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить рецепт'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _adminUsers,
                        icon: const Icon(Icons.people),
                        label: const Text('Пользователи'),
                      ),
                      const Divider(height: 40),
                    ],
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.flag, color: Colors.green),
                            title: const Text('Мои цели питания'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openGoals,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.lightbulb, color: Colors.green),
                            title: const Text('Советы по питанию'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openTips,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history, color: Colors.green),
                            title: const Text('История питания'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openMealHistory,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ваши данные сохраняются локально и не передаются третьим лицам.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}