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
    return Ingredient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      caloriesPer100g: json['caloriesPer100g'] ?? 0,
      proteins: (json['proteins'] ?? 0).toDouble(),
      fats: (json['fats'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
    );
  }
}

class Recipe {
  final int id;
  final String title;
  final String description;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;
  final String imageUrl;
  final int cookingTime;
  final String difficulty;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.imageUrl,
    required this.cookingTime,
    required this.difficulty,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    var ingList = <Ingredient>[];
    if (json['ingredients'] != null && json['ingredients'] is List) {
      ingList = (json['ingredients'] as List)
          .map((e) => Ingredient.fromJson(e))
          .toList();
    }

    return Recipe(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      calories: json['calories'] ?? 0,
      proteins: (json['proteins'] ?? 0).toDouble(),
      fats: (json['fats'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      cookingTime: json['cookingTime'] ?? 0,
      difficulty: json['difficulty'] ?? 'Не указано',
      ingredients: ingList,
    );
  }
}
