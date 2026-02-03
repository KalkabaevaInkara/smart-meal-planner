import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../widgets/recipe_card.dart';

enum SortOption { none, caloriesAsc, caloriesDesc, timeAsc, timeDesc, proteinsDesc }

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Recipe>> futureRecipes;
  String query = '';
  final Set<String> selectedDifficulties = {};
  List<String> difficulties = [];
  SortOption sortOption = SortOption.none;

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
    futureRecipes = ApiService.fetchRecipes();
    futureRecipes.then((list) {
      final uniq = <String>{};
      for (var r in list) {
        if (r.difficulty.isNotEmpty) uniq.add(r.difficulty);
      }
      setState(() => difficulties = uniq.toList()..sort());
    }).catchError((_) {});
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
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0),
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
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                              ),
                            )
                          ],
                        ),
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
                        onChanged: (v) => setState(() => sortOption = v ?? SortOption.none),
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Рецепты не найдены'));
                } else {
                  final filtered = _applyFiltersAndSort(snapshot.data!);
                  if (filtered.isEmpty) return const Center(child: Text('Ничего не найдено'));

                  // обычный список карточек
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => RecipeCard(recipe: filtered[index]),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
