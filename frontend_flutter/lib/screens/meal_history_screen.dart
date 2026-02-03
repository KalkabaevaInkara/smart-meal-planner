import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';

class MealHistoryScreen extends StatefulWidget {
  final String email;
  const MealHistoryScreen({super.key, required this.email});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<Map<String, dynamic>> history = [];
  List<Recipe> allRecipes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadRecipes();
    await _loadHistory();
    setState(() => loading = false);
  }

  Future<void> _loadRecipes() async {
    try {
      allRecipes = await ApiService.fetchRecipes();
    } catch (_) {
      allRecipes = [];
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'meal_history_${widget.email}';
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        history = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
  }

  String _recipeTitleById(int? id) {
    if (id == null || id == 0) return '-';
    final r = allRecipes.firstWhere(
      (x) => x.id == id,
      orElse: () => Recipe(
        id: 0,
        title: '-',
        description: '',
        calories: 0,
        proteins: 0.0,
        fats: 0.0,
        carbs: 0.0,
        imageUrl: '',
        cookingTime: 0,
        difficulty: '',
        ingredients: [], // обязательно: пустой список ингредиентов
      ),
    );
    return r.title;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('История питания'),
        backgroundColor: Colors.green,
      ),
      body: history.isEmpty
          ? const Center(child: Text('История пока пуста'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final entry = history[i];
                final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
                final totals = entry['totals'] ?? {};

                double toDouble(dynamic v) =>
                    (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}.${date.month}.${date.year}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('🍳 Завтрак: ${_recipeTitleById(entry['breakfast'])}'),
                        Text('🥗 Обед: ${_recipeTitleById(entry['lunch'])}'),
                        Text('🍝 Ужин: ${_recipeTitleById(entry['dinner'])}'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _nutrientItem('${toDouble(totals['calories']).toStringAsFixed(0)}', 'ккал'),
                            _nutrientItem('${toDouble(totals['proteins']).toStringAsFixed(1)}', 'Б'),
                            _nutrientItem('${toDouble(totals['fats']).toStringAsFixed(1)}', 'Ж'),
                            _nutrientItem('${toDouble(totals['carbs']).toStringAsFixed(1)}', 'У'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _nutrientItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
