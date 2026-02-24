import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/no_internet.dart';
import '../widgets/empty_state.dart';

class AdminRecipesPage extends StatefulWidget {
  const AdminRecipesPage({super.key});

  @override
  State<AdminRecipesPage> createState() => _AdminRecipesPageState();
}

class _AdminRecipesPageState extends State<AdminRecipesPage> {
  late Future<List<Recipe>> futureRecipes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    futureRecipes = _loadRecipesWithFallback();
  }

  Future<List<Recipe>> _loadRecipesWithFallback() async {
    try {
      // Пытаемся загрузить с сервера
      return await ApiService.fetchRecipes();
    } catch (e) {
      // Fallback: загружаем локальные рецепты
      print('⚠️ Не удалось загрузить с сервера: $e. Загружаю локально...');
      
      final prefs = await SharedPreferences.getInstance();
      final localRecipes = prefs.getStringList('local_recipes') ?? [];
      
      List<Recipe> recipes = [];
      for (String recipeJson in localRecipes) {
        try {
          final data = jsonDecode(recipeJson) as Map<String, dynamic>;
          recipes.add(Recipe.fromJson(data));
        } catch (_) {}
      }
      
      return recipes;
    }
  }

  Future<void> _deleteRecipe(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить рецепт?'),
        content: Text('Вы уверены, что хотите удалить "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      try {
        await ApiService.deleteRecipe(id);
      } catch (serverError) {
        // Fallback: удаляем локально
        print('⚠️ Ошибка сервера при удалении: $serverError. Удаляю локально...');
        
        final prefs = await SharedPreferences.getInstance();
        final localRecipes = prefs.getStringList('local_recipes') ?? [];
        
        localRecipes.removeWhere((recipeJson) {
          try {
            final data = jsonDecode(recipeJson) as Map<String, dynamic>;
            return data['id'] == id;
          } catch (_) {
            return false;
          }
        });
        
        await prefs.setStringList('local_recipes', localRecipes);
        
        if (!mounted) return;
        NotificationService.instance.warning('Рецепт удалён локально (сервер недоступен)');
      }
      
      if (!mounted) return;
      NotificationService.instance.success('Рецепт "$title" удалён!');
      _loadRecipes();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      NotificationService.instance.error('Ошибка удаления: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRecipe() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinsCtrl = TextEditingController();
    final fatsCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String difficulty = 'Легко';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Добавить новый рецепт'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Описание'), maxLines: 2),
                TextField(controller: caloriesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Калории')),
                TextField(controller: proteinsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Белки (г)')),
                TextField(controller: fatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Жиры (г)')),
                TextField(controller: carbsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Углеводы (г)')),
                TextField(controller: timeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Время готовки (мин)')),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: difficulty,
                  items: ['Легко', 'Средне', 'Сложно']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => difficulty = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    setState(() => _isLoading = true);
    try {
      // Валидация данных
      if (titleCtrl.text.trim().isEmpty) {
        throw Exception('Название рецепта не может быть пустым');
      }
      if (descCtrl.text.trim().isEmpty) {
        throw Exception('Описание рецепта не может быть пустым');
      }

      final calories = int.tryParse(caloriesCtrl.text);
      if (calories == null || calories <= 0) {
        throw Exception('Калории должны быть положительным числом');
      }

      final proteins = double.tryParse(proteinsCtrl.text);
      if (proteins == null || proteins < 0) {
        throw Exception('Белки должны быть неотрицательным числом');
      }

      final fats = double.tryParse(fatsCtrl.text);
      if (fats == null || fats < 0) {
        throw Exception('Жиры должны быть неотрицательным числом');
      }

      final carbs = double.tryParse(carbsCtrl.text);
      if (carbs == null || carbs < 0) {
        throw Exception('Углеводы должны быть неотрицательным числом');
      }

      final cookingTime = int.tryParse(timeCtrl.text);
      if (cookingTime == null || cookingTime <= 0) {
        throw Exception('Время готовки должно быть положительным числом');
      }

      // Отправляем запрос на сервер
      try {
        await ApiService.createRecipe({
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'calories': calories,
          'proteins': proteins,
          'fats': fats,
          'carbs': carbs,
          'cookingTime': cookingTime,
          'difficulty': difficulty,
          'imageUrl': 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
          'ingredients': [], // Assuming empty for now
        });
      } catch (serverError) {
        // Fallback: сохраняем локально если сервер недоступен
        print('⚠️ Ошибка сервера: $serverError. Сохраняю локально...');
        
        final prefs = await SharedPreferences.getInstance();
        final localRecipes = prefs.getStringList('local_recipes') ?? [];
        final newRecipe = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'calories': calories,
          'proteins': proteins,
          'fats': fats,
          'carbs': carbs,
          'cookingTime': cookingTime,
          'difficulty': difficulty,
          'imageUrl': 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
          'ingredients': [],
        };
        
        localRecipes.add(jsonEncode(newRecipe));
        await prefs.setStringList('local_recipes', localRecipes);
        
        if (!mounted) return;
        NotificationService.instance.warning('Рецепт сохранён локально (сервер недоступен)');
      }
      
      if (!mounted) return;
      NotificationService.instance.celebrate('Рецепт "${titleCtrl.text}" добавлен!');
      _loadRecipes();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      NotificationService.instance.error('Ошибка добавления: $e');
    } finally {
      setState(() => _isLoading = false);
      titleCtrl.dispose();
      descCtrl.dispose();
      caloriesCtrl.dispose();
      proteinsCtrl.dispose();
      fatsCtrl.dispose();
      carbsCtrl.dispose();
      timeCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление рецептами'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addRecipe,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Recipe>>(
        future: futureRecipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final err = snapshot.error.toString();
            if (err.contains('SocketException') || err.contains('NetworkException') || err.contains('Timeout')) {
              return NoInternetWidget(onRetry: () => setState(() => _loadRecipes()));
            }
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(text: 'Рецепты не найдены');
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.restaurant, color: Colors.green),
                  ),
                  title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${recipe.calories} ккал • ${recipe.difficulty}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        _deleteRecipe(recipe.id, recipe.title);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
