import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

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
    futureRecipes = ApiService.fetchRecipes();
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
      // TODO: Реализовать DELETE /api/recipes/{id} на backend
      // Для теста используем mock
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      NotificationService.instance.success('Рецепт "$title" удалён');
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
      // TODO: Реализовать POST /api/recipes на backend
      // Для теста используем mock
      final newRecipe = Recipe(
        id: DateTime.now().millisecond,
        title: titleCtrl.text,
        description: descCtrl.text,
        calories: int.tryParse(caloriesCtrl.text) ?? 0,
        proteins: double.tryParse(proteinsCtrl.text) ?? 0,
        fats: double.tryParse(fatsCtrl.text) ?? 0,
        carbs: double.tryParse(carbsCtrl.text) ?? 0,
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
        cookingTime: int.tryParse(timeCtrl.text) ?? 0,
        difficulty: difficulty,
        ingredients: [],
      );

      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      NotificationService.instance.celebrate('Рецепт "${newRecipe.title}" добавлен!');
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
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Рецепты не найдены'));
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
