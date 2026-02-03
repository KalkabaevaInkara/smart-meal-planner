import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    // Получаем всех пользователей из локального хранилища
    // TODO: На backend нужен GET /api/admin/users
    final prefs = await SharedPreferences.getInstance();
    
    // Получаем текущего пользователя
    final currentEmail = prefs.getString('email') ?? '';
    final currentName = prefs.getString('fullName') ?? '';

    // Для демо добавляем текущего пользователя
    final users = [
      {
        'email': currentEmail,
        'name': currentName,
        'role': prefs.getBool('isAdmin') ?? false ? 'admin' : 'user',
        'createdAt': 'N/A',
      }
    ];

    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _toggleAdminRole(String email, bool isAdmin) async {
    // TODO: Реализовать PUT /api/admin/users/{email}/role на backend
    // Для теста просто показываем уведомление
    NotificationService.instance.info(
      '$email ${isAdmin ? "повышен до админа" : "понижен до пользователя"} (mock)',
    );
  }

  Future<void> _deleteUser(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text('Вы уверены, что хотите удалить пользователя $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // TODO: Реализовать DELETE /api/admin/users/{email} на backend
    NotificationService.instance.success('Пользователь $email удалён (mock)');
    
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление пользователями'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Нет пользователей'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isAdmin = user['role'] == 'admin';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.purple : Colors.blue,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(user['email'] ?? ''),
                            Text(
                              isAdmin ? '👑 Администратор' : '👤 Пользователь',
                              style: TextStyle(
                                color: isAdmin ? Colors.purple : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'toggle_admin') {
                              _toggleAdminRole(user['email'], !isAdmin);
                            } else if (v == 'delete') {
                              _deleteUser(user['email']);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'toggle_admin',
                              child: Text(
                                isAdmin ? 'Убрать админа' : 'Сделать админом',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Удалить',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
