import 'recipe.dart';

class Nutrients {
  double calories;
  double protein;
  double fats;
  double carbs;

  Nutrients({
    this.calories = 0,
    this.protein = 0,
    this.fats = 0,
    this.carbs = 0,
  });

  void add(Recipe r, {double servings = 1.0}) {
    calories += r.calories * servings;
    protein += r.proteins * servings; // использует поле 'proteins' модели Recipe
    fats += r.fats * servings;
    carbs += r.carbs * servings;
  }
}
