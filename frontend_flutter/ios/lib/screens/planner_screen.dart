import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../models/nutrients.dart';
import '../services/api_service.dart';

Future<List<Recipe>> fetchRecipes() async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    Recipe(
      id: 1,
      title: 'Овсянка с ягодами',
      description: 'Тёплая овсяная каша с ягодами и мёдом.',
      imageUrl: '',
      calories: 320,
      proteins: 10.0,
      fats: 8.0,
      carbs: 50.0,
      cookingTime: 10,
      difficulty: 'Легко',
      ingredients: [],
    ),
    Recipe(
      id: 2,
      title: 'Куриное филе с рисом',
      description: 'Нежное куриное филе, рис и овощи.',
      imageUrl: '',
      calories: 480,
      proteins: 35.0,
      fats: 10.0,
      carbs: 60.0,
      cookingTime: 30,
      difficulty: 'Средне',
      ingredients: [],
    ),
    Recipe(
      id: 3,
      title: 'Салат с тунцом',
      description: 'Лёгкий салат с тунцом, овощами и заправкой.',
      imageUrl: '',
      calories: 250,
      proteins: 20.0,
      fats: 8.0,
      carbs: 15.0,
      cookingTime: 8,
      difficulty: 'Легко',
      ingredients: [],
    ),
  ];
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  bool loading = true;
  List<Recipe> allRecipes = [];
  Recipe? breakfast;
  Recipe? lunch;
  Recipe? dinner;
  Nutrients total = Nutrients();
  String? _emailForSave;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<List<Recipe>> _fetchAllRecipes() async {
    try {
      final remote = await ApiService.fetchRecipes();
      return remote;
    } catch (_) {
      // fallback — локальный список
      return fetchRecipes();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _emailForSave = prefs.getString('email');

    final data = await _fetchAllRecipes();
    if (!mounted) return;
    setState(() {
      allRecipes = data;
      loading = false;
    });

    await _loadMealPlanFromPrefs();
  }

  Future<void> _loadMealPlanFromPrefs() async {
    if (_emailForSave == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'meal_plan_${_emailForSave!}';
    final s = prefs.getString(key);
    if (s == null) return;
    try {
      final Map<String, dynamic> m = jsonDecode(s);
      final int? bid = m['breakfast'];
      final int? lid = m['lunch'];
      final int? did = m['dinner'];
      setState(() {
        breakfast = bid != null
            ? allRecipes.firstWhere(
                (r) => r.id == bid,
                orElse: () => Recipe(
                    id: 0,
                    title: '',
                    description: '',
                    ingredients: [],
                    calories: 0,
                    proteins: 0,
                    fats: 0,
                    carbs: 0,
                    imageUrl: '',
                    cookingTime: 0,
                    difficulty: ''))
            : null;
        lunch = lid != null
            ? allRecipes.firstWhere(
                (r) => r.id == lid,
                orElse: () => Recipe(
                    id: 0,
                    title: '',
                    description: '',
                    ingredients: [],
                    calories: 0,
                    proteins: 0,
                    fats: 0,
                    carbs: 0,
                    imageUrl: '',
                    cookingTime: 0,
                    difficulty: ''))
            : null;
        dinner = did != null
            ? allRecipes.firstWhere(
                (r) => r.id == did,
                orElse: () => Recipe(
                    id: 0,
                    title: '',
                    description: '',
                    ingredients: [],
                    calories: 0,
                    proteins: 0,
                    fats: 0,
                    carbs: 0,
                    imageUrl: '',
                    cookingTime: 0,
                    difficulty: ''))
            : null;
      });
      _recalculate();
    } catch (_) {}
  }

  Future<void> _saveMealPlanToPrefs() async {
    if (_emailForSave == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'meal_plan_${_emailForSave!}';
    final Map<String, dynamic> m = {
      'breakfast': breakfast?.id,
      'lunch': lunch?.id,
      'dinner': dinner?.id,
    };
    await prefs.setString(key, jsonEncode(m));
  }

  Future<void> _appendHistory() async {
    if (_emailForSave == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'meal_history_${_emailForSave!}';
    final raw = prefs.getString(key);
    final List<dynamic> list = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];
    final entry = {
      'date': DateTime.now().toIso8601String(),
      'breakfast': breakfast?.id,
      'lunch': lunch?.id,
      'dinner': dinner?.id,
      'totals': {
        'calories': total.calories,
        'proteins': total.protein,
        'fats': total.fats,
        'carbs': total.carbs,
      }
    };
    list.insert(0, entry);
    await prefs.setString(key, jsonEncode(list));
  }

  void _recalculate() {
    total = Nutrients();
    if (breakfast != null && breakfast!.id != 0) total.add(breakfast!);
    if (lunch != null && lunch!.id != 0) total.add(lunch!);
    if (dinner != null && dinner!.id != 0) total.add(dinner!);
    setState(() {});
    _saveMealPlanToPrefs();
  }

  Future<void> _resetPlan() async {
    final prefs = await SharedPreferences.getInstance();
    if (_emailForSave != null) {
      final key = 'meal_plan_${_emailForSave!}';
      await prefs.remove(key);
    }
    setState(() {
      breakfast = null;
      lunch = null;
      dinner = null;
      total = Nutrients();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('План сброшен')));
  }

  Widget _mealSelector(String label, Recipe? selected, void Function(Recipe?) onChanged) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Recipe>(
                key: ValueKey(label),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                value: selected?.id == 0 ? null : selected,
                hint: const Text('Выберите блюдо'),
                items: allRecipes.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.title));
                }).toList(),
                onChanged: (val) {
                  onChanged(val);
                  _recalculate();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final percent = (total.calories / 2000).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Планировщик питания'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Итог за день', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBlock('${total.calories.toStringAsFixed(0)}', 'ккал'),
                          _statBlock('${total.protein.toStringAsFixed(1)}', 'Белки'),
                          _statBlock('${total.fats.toStringAsFixed(1)}', 'Жиры'),
                          _statBlock('${total.carbs.toStringAsFixed(1)}', 'Углеводы'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _mealSelector('🍳 Завтрак', breakfast, (r) => setState(() => breakfast = r)),
            _mealSelector('🥗 Обед', lunch, (r) => setState(() => lunch = r)),
            _mealSelector('🍝 Ужин', dinner, (r) => setState(() => dinner = r)),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _saveMealPlanToPrefs();
                        await _appendHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('План сохранён в истории')),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить план'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _resetPlan,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Сбросить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

  Widget _statBlock(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
