import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  String message = '';
  bool _loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildProfileArgsFromResult(
      Map<String, dynamic> result, String fallbackEmail, String? fallbackName) {
    final user =
        result['user'] is Map ? Map<String, dynamic>.from(result['user']) : null;
    final name =
        result['fullName'] ?? user?['fullName'] ?? result['name'] ?? fallbackName ?? '';
    final email = result['email'] ?? user?['email'] ?? fallbackEmail;
    final avatar =
        result['avatar'] ?? user?['avatar'] ?? 'assets/avatars/avatar1.png';
    final description =
        result['description'] ?? user?['description'] ?? '';
    return {
      'fullName': name,
      'email': email,
      'avatar': avatar,
      'description': description
    };
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final pass = passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Заполните email и пароль')));
      return;
    }

    if (pass.length < 8) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Пароль должен содержать минимум 8 символов'),
    ),
  );
  return;
}


    setState(() {
      _loading = true;
      message = '';
    });

    try {
      final result = await ApiService.login(email, pass);
      if (!mounted) return;

      final args = _buildProfileArgsFromResult(result, email, null);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullName', args['fullName'] ?? '');
      await prefs.setString('email', args['email'] ?? email);
      await prefs.setString('avatar', args['avatar'] ?? '');
      await prefs.setString('description', args['description'] ?? '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Успех! Привет, ${args['fullName'] ?? args['email']}')),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        Navigator.of(context).pushNamed('/profile', arguments: args);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.toString();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showRegisterDialog() async {
    final fullNameController = TextEditingController();
    final regEmailController = TextEditingController();
    final regPasswordController = TextEditingController();
    final regConfirmController = TextEditingController();

    bool loading = false;
    String regError = '';
    final parentContext = context;

    await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setStateDialog) {
          Future<void> doRegister() async {
            final fullName = fullNameController.text.trim();
            final email = regEmailController.text.trim();
            final pass = regPasswordController.text;
            final confirm = regConfirmController.text;

            if (fullName.isEmpty ||
                email.isEmpty ||
                pass.isEmpty ||
                confirm.isEmpty) {
              setStateDialog(() => regError = 'Заполните все поля');
              return;
            }
            if (pass != confirm) {
              setStateDialog(() => regError = 'Пароли не совпадают');
              return;
            }

            setStateDialog(() {
              loading = true;
              regError = '';
            });

            try {
              final res = await ApiService.register(email, fullName, pass);
              if (!dialogContext.mounted) return;

              final args = {
                'fullName': res['fullName'] ?? res['user']?['fullName'] ?? fullName,
                'email': res['email'] ?? res['user']?['email'] ?? email,
                'avatar': res['avatar'] ??
                    res['user']?['avatar'] ??
                    'assets/avatars/avatar1.png',
                'description':
                    res['description'] ?? res['user']?['description'] ?? ''
              };

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('fullName', args['fullName'] ?? '');
              await prefs.setString('email', args['email'] ?? email);
              await prefs.setString('avatar', args['avatar'] ?? '');
              await prefs.setString('description', args['description'] ?? '');

              Navigator.of(dialogContext).pop(true);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Регистрация успешна. Добро пожаловать, ${args['fullName']}')),
                );
                Navigator.of(parentContext)
                    .pushNamedAndRemoveUntil('/home', (route) => false);
                Navigator.of(parentContext)
                    .pushNamed('/profile', arguments: args);
              });
            } catch (e) {
              setStateDialog(() => regError = e.toString());
            } finally {
              if (dialogContext.mounted) {
                setStateDialog(() => loading = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Регистрация'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'ФИО')),
                  TextField(controller: regEmailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: regPasswordController, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
                  TextField(controller: regConfirmController, decoration: const InputDecoration(labelText: 'Подтвердите пароль'), obscureText: true),
                  if (regError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(regError, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.of(dialogContext).pop(false), child: const Text('Отмена')),
              ElevatedButton(
                onPressed: loading ? null : doRegister,
                child: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Зарегистрироваться'),
              ),
            ],
          );
        });
      },
    );

    fullNameController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    regConfirmController.dispose();
  }

  Future<void> _showResetDialog() async {
    final emailCtrl = TextEditingController(text: emailController.text.trim());
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Восстановление пароля'),
        content: TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите email')));
                return;
              }
              Navigator.pop(ctx, true);
              try {
                await ApiService.resetPassword(email);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Письмо для восстановления отправлено, проверьте почту')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.local_dining, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Healthy Eating',
                    style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Добро пожаловать — войдите в аккаунт',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email),
                            hintText: 'Email',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: 'Пароль',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white))
                                : const Text('Войти'),
                          ),
                        ),

                        // ✅ Новая кнопка для входа без авторизации
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('fullName', 'Гость');
                              await prefs.setString('email', 'guest@local');
                              await prefs.setString('avatar', 'assets/avatars/avatar1.png');
                              await prefs.setString('description', 'Гостевой режим');

                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/home', (route) => false);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Продолжить без входа',
                                style: TextStyle(color: Colors.green)),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _showRegisterDialog,
                                child: const Text(
                                  'Создать аккаунт',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed: _showResetDialog,
                                child: const Text(
                                  'Забыли пароль?',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
