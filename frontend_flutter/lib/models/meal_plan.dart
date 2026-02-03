class MealPlan {
  final String date;
  final int recipeId;
  final double servings;

  MealPlan({
    required this.date,
    required this.recipeId,
    required this.servings,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      date: json['date'],
      recipeId: json['recipe_id'],
      servings: (json['servings'] as num).toDouble(),
    );
  }
}
