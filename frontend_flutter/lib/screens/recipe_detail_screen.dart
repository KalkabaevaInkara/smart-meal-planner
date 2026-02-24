import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../models/recipe.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  Future<void> _addToPlan(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email == null || email.isEmpty) {
      NotificationService.instance.warning('Войдите в аккаунт, чтобы добавлять в план');
      return;
    }

    String slot = 'breakfast';
    final servingsCtrl = TextEditingController(text: '1');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Добавить в план'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Завтрак'),
                  value: 'breakfast',
                  groupValue: slot,
                  onChanged: (v) => setState(() => slot = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Обед'),
                  value: 'lunch',
                  groupValue: slot,
                  onChanged: (v) => setState(() => slot = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Ужин'),
                  value: 'dinner',
                  groupValue: slot,
                  onChanged: (v) => setState(() => slot = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: servingsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Порции (кол-во)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    // Сохраняем план
    final key = 'meal_plan_$email';
    final raw = prefs.getString(key);
    Map<String, dynamic> plan = {};
    if (raw != null) {
      try {
        plan = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    plan[slot] = recipe.id;
    await prefs.setString(key, jsonEncode(plan));

    // Добавляем в историю
    final histKey = 'meal_history_$email';
    final rawHist = prefs.getString(histKey);
    final List<dynamic> hist =
        rawHist != null ? (jsonDecode(rawHist) as List<dynamic>) : <dynamic>[];
    final totals = {
      'calories': recipe.calories,
      'proteins': recipe.proteins,
      'fats': recipe.fats,
      'carbs': recipe.carbs,
    };
    hist.insert(0, {
      'date': DateTime.now().toIso8601String(),
      'breakfast': slot == 'breakfast' ? recipe.id : null,
      'lunch': slot == 'lunch' ? recipe.id : null,
      'dinner': slot == 'dinner' ? recipe.id : null,
      'totals': totals,
    });
    await prefs.setString(histKey, jsonEncode(hist));

    NotificationService.instance.success('Добавлено в план');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(recipe.title, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                recipe.imageUrl.isNotEmpty
                    ? recipe.imageUrl
                    : 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.fastfood, size: 64),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('🔥 ${recipe.calories} ккал'),
                      const SizedBox(width: 8),
                      _chip('💪 ${recipe.proteins} г белков'),
                      const SizedBox(width: 8),
                      _chip('🥑 ${recipe.fats} г жиров'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⏱ ${recipe.cookingTime} мин • ${recipe.difficulty}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text('Описание',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(recipe.description.isNotEmpty
                      ? recipe.description
                      : 'Описание отсутствует'),
                  const SizedBox(height: 16),
                  const Text('Ингредиенты',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  if (recipe.ingredients.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: recipe.ingredients.map((ing) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- ${ing.name} (${ing.caloriesPer100g} ккал / 100г, '
                            'Б: ${ing.proteins}г, Ж: ${ing.fats}г, У: ${ing.carbs}г)',
                            style:
                                const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text('Нет данных по ингредиентам'),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToPlan(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить в план'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
