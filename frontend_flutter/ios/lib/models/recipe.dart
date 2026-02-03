class Ingredient {
  final int id;
  final String name;
  final int caloriesPer100g;
  final double proteins;
  final double fats;
  final double carbs;

  Ingredient({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    return Ingredient(
      id: toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      caloriesPer100g: toInt(json['caloriesPer100g'] ?? json['calories'] ?? 0),
      proteins: toDouble(json['proteins'] ?? 0),
      fats: toDouble(json['fats'] ?? 0),
      carbs: toDouble(json['carbs'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'caloriesPer100g': caloriesPer100g,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
      };
}

class Recipe {
  final int id;
  final String title;
  final String description;
  final String ingredientsList; // совместимость со старым кодом (строка)
  final List<Ingredient> ingredients; // основной список ингредиентов
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;
  final String imageUrl;
  final int cookingTime;
  final String difficulty;

  Recipe({
    required this.id,
    required this.title,
    this.description = '',
    this.ingredientsList = '',
    List<Ingredient>? ingredients,
    this.calories = 0,
    this.proteins = 0.0,
    this.fats = 0.0,
    this.carbs = 0.0,
    this.imageUrl = '',
    this.cookingTime = 0,
    this.difficulty = 'Не указано',
  }) : ingredients = ingredients ?? _parseIngredientsFromString(ingredientsList);

  // Вспомогательный парсер строки в список Ingredient (имя только)
  static List<Ingredient> _parseIngredientsFromString(String s) {
    if (s.trim().isEmpty) return <Ingredient>[];
    final parts = s.split(RegExp(r'[,\n;]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    int idx = 1;
    return parts.map((p) => Ingredient(id: idx++, name: p, caloriesPer100g: 0, proteins: 0.0, fats: 0.0, carbs: 0.0)).toList();
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double toDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    // image fields fallback
    String img = '';
    if (json.containsKey('image_url')) img = json['image_url'] ?? '';
    else if (json.containsKey('imageUrl')) img = json['imageUrl'] ?? '';
    else if (json.containsKey('image')) img = json['image'] ?? '';

    // ingredients: try list first, then string fields
    List<Ingredient> ingList = [];
    final dynamic ingVal = json['ingredients'] ?? json['ingredients_list'] ?? json['ingredientsList'];
    if (ingVal != null) {
      if (ingVal is List) {
        for (var it in ingVal) {
          if (it is Map<String, dynamic>) {
            ingList.add(Ingredient.fromJson(it));
          } else if (it is Map) {
            ingList.add(Ingredient.fromJson(Map<String, dynamic>.from(it)));
          } else {
            ingList.add(Ingredient(id: 0, name: it.toString(), caloriesPer100g: 0, proteins: 0.0, fats: 0.0, carbs: 0.0));
          }
        }
      } else if (ingVal is String) {
        ingList.addAll(_parseIngredientsFromString(ingVal));
      }
    }

    final ingredientsListStr = (json['ingredients_list'] ?? json['ingredientsList'] ?? (json['ingredients'] is String ? json['ingredients'] : ''))?.toString() ?? '';

    return Recipe(
      id: toInt(json['id']),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      ingredientsList: ingredientsListStr,
      ingredients: ingList.isNotEmpty ? ingList : null,
      calories: toInt(json['calories']),
      proteins: toDouble(json['proteins'] ?? json['protein']),
      fats: toDouble(json['fats']),
      carbs: toDouble(json['carbs']),
      imageUrl: img,
      cookingTime: toInt(json['cooking_time'] ?? json['cookingTime']),
      difficulty: (json['difficulty'] ?? 'Не указано').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients_list': ingredientsList,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'calories': calories,
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'image_url': imageUrl,
        'cooking_time': cookingTime,
        'difficulty': difficulty,
      };
}
