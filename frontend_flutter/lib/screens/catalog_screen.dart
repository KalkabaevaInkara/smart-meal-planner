import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/local_notifications_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/no_internet.dart';
import '../widgets/empty_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOption { none, caloriesAsc, caloriesDesc, timeAsc, timeDesc, proteinsDesc }

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Recipe>> futureRecipes;
  String query = '';
  bool gridView = false;
  
  final Set<String> selectedDifficulties = {};
  List<String> difficulties = [];
  SortOption sortOption = SortOption.none;
  
  // ✅ Кэш рецептов
  List<Recipe> _cachedRecipes = [];
  bool _cacheLoaded = false;

  List<Recipe> _applyFiltersAndSort(List<Recipe> list) {
    var filtered = list.where((r) {
      final q = query.toLowerCase();
      final ingredientText = r.ingredients.map((i) => i.name.toLowerCase()).join(' ');
      final matchesQuery = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          ingredientText.contains(q);
      final matchesDifficulty = selectedDifficulties.isEmpty || selectedDifficulties.contains(r.difficulty);
      return matchesQuery && matchesDifficulty;
    }).toList();

    switch (sortOption) {
      case SortOption.caloriesAsc:
        filtered.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case SortOption.caloriesDesc:
        filtered.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case SortOption.timeAsc:
        filtered.sort((a, b) => a.cookingTime.compareTo(b.cookingTime));
        break;
      case SortOption.timeDesc:
        filtered.sort((a, b) => b.cookingTime.compareTo(a.cookingTime));
        break;
      case SortOption.proteinsDesc:
        filtered.sort((a, b) => b.proteins.compareTo(a.proteins));
        break;
      case SortOption.none:
        break;
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    print('🔄 CatalogScreen initState запущен');
    
    // ✅ Загружаем асинхронно БЕЗ ожидания
    futureRecipes = _loadRecipesOptimized();
    
    futureRecipes.then((list) {
      print('✅ Рецепты загружены: ${list.length} штук');
      final uniq = <String>{};
      for (var r in list) {
        if (r.difficulty.isNotEmpty) uniq.add(r.difficulty);
      }
      setState(() => difficulties = uniq.toList()..sort());

      LocalNotificationsService.instance.notifyRecipeLoaded(list.length);
      NotificationService.instance.tip('${list.length} рецептов загружено ✨');
    }).catchError((e) {
      print('❌ Ошибка загрузки рецептов в initState: $e');
    });
  }

  // ✅ Оптимизированная загрузка с кэшем
  Future<List<Recipe>> _loadRecipesOptimized() async {
    print('📥 _loadRecipesOptimized запущена');
    
    if (_cacheLoaded && _cachedRecipes.isNotEmpty) {
      print('📦 Используем кэш: ${_cachedRecipes.length} рецептов');
      return _cachedRecipes;
    }

    try {
      print('🌐 Запрашиваем рецепты с сервера...');
      final list = await ApiService.fetchRecipes().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ ТАЙМАУТ загрузки рецептов!');
          return <Recipe>[];
        },
      );

      print('✅ Получено ${list.length} рецептов');
      _cachedRecipes = list;
      _cacheLoaded = true;

      // Сохраняем в SharedPreferences для fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = list.map((r) => {
          'id': r.id,
          'title': r.title,
          'description': r.description,
          'calories': r.calories,
          'proteins': r.proteins,
          'fats': r.fats,
          'carbs': r.carbs,
          'imageUrl': r.imageUrl,
          'cookingTime': r.cookingTime,
          'difficulty': r.difficulty,
          'ingredients': r.ingredients.map((i) => {
            'id': i.id,
            'name': i.name,
            'caloriesPer100g': i.caloriesPer100g,
            'proteins': i.proteins,
            'fats': i.fats,
            'carbs': i.carbs,
          }).toList(),
        }).toList();
        await prefs.setString('cached_recipes_json', jsonEncode(jsonList));
      } catch (e) {
        print('⚠️ Не удалось записать кэш рецептов: $e');
      }

      final uniq = <String>{};
      for (var r in list) {
        if (r.difficulty.isNotEmpty) uniq.add(r.difficulty);
      }
      setState(() => difficulties = uniq.toList()..sort());

      LocalNotificationsService.instance.notifyRecipeLoaded(list.length);
      NotificationService.instance.tip('${list.length} рецептов загружено ✨');

      return list;
    } catch (e) {
      print('❌ Ошибка загрузки рецептов: $e');
      // Попробуем взять из SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('cached_recipes_json');
        if (raw != null && raw.isNotEmpty) {
          final List<dynamic> data = jsonDecode(raw);
          final list = data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
          _cachedRecipes = list;
          _cacheLoaded = true;
          print('📦 Использован кэш из SharedPreferences: ${list.length} рецептов');
          return list;
        }
      } catch (e2) {
        print('⚠️ Ошибка чтения кэша: $e2');
      }
      return <Recipe>[];
    }
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[];
    chips.add(
      ChoiceChip(
        label: const Text('Все'),
        selected: selectedDifficulties.isEmpty,
        onSelected: (_) => setState(() => selectedDifficulties.clear()),
      ),
    );
    for (var d in difficulties) {
      chips.add(Padding(
        padding: const EdgeInsets.only(left: 6),
        child: FilterChip(
          label: Text(d),
          selected: selectedDifficulties.contains(d),
          onSelected: (sel) {
            setState(() {
              if (sel) {
                selectedDifficulties.add(d);
              } else {
                selectedDifficulties.remove(d);
              }
            });
          },
        ),
      ));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(children: chips),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Каталог рецептов',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Поиск рецептов',
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) {
                                  setState(() => query = v.trim().toLowerCase());
                                  if (v.isNotEmpty) {
                                    NotificationService.instance.quick('Поиск: "$v"');
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        icon: Icon(gridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
                        onPressed: () {
                          setState(() => gridView = !gridView);
                          NotificationService.instance.quick(gridView ? '🔲 Сетка' : '📋 Список');
                        },
                        tooltip: gridView ? 'Показать список' : 'Показать сетку',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: DropdownButton<SortOption>(
                        value: sortOption,
                        dropdownColor: Colors.white,
                        underline: const SizedBox(),
                        iconEnabledColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: SortOption.none, child: Text('По умолчанию')),
                          DropdownMenuItem(value: SortOption.caloriesAsc, child: Text('Калории ↑')),
                          DropdownMenuItem(value: SortOption.caloriesDesc, child: Text('Калории ↓')),
                          DropdownMenuItem(value: SortOption.timeAsc, child: Text('Время ↑')),
                          DropdownMenuItem(value: SortOption.timeDesc, child: Text('Время ↓')),
                          DropdownMenuItem(value: SortOption.proteinsDesc, child: Text('Белки ↓')),
                        ],
                        onChanged: (v) {
                          setState(() => sortOption = v ?? SortOption.none);
                          NotificationService.instance.quick('Сортировка изменена');
                        },
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFilterChips(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Recipe>>(
              future: futureRecipes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Загружаю рецепты...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                  } else if (snapshot.hasError) {
                    final err = snapshot.error.toString();
                    if (err.contains('SocketException') || err.contains('NetworkException') || err.contains('Timeout')) {
                      return NoInternetWidget(onRetry: () => setState(() => futureRecipes = _loadRecipesOptimized()));
                    }
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const EmptyState(text: 'Рецепты не найдены');
                } else {
                  final filtered = _applyFiltersAndSort(snapshot.data!);
                  if (filtered.isEmpty) return const Center(child: Text('Ничего не найдено'));
                  
                  if (gridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => RecipeCard(recipe: filtered[index]),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => RecipeCard(recipe: filtered[index]),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
