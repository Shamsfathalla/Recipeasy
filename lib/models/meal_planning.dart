import 'package:recipeasy/models/meal_model.dart';

class MealPlan {
  final List<Meal> meals;
  final double calories;
  final double carbs;
  final double fat;
  final double protein;
  double totalCost;

  MealPlan({
    required this.meals,
    required this.calories,
    required this.carbs,
    required this.fat,
    required this.protein,
    this.totalCost = 0.0,
  });

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    List<Meal> meals = (map['meals'] as List<dynamic>)
        .map((mealMap) => Meal.fromMap(mealMap))
        .toList();

    return MealPlan(
      meals: meals,
      calories: (map['nutrients']['calories'] ?? 0).toDouble(),
      carbs: (map['nutrients']['carbohydrates'] ?? 0).toDouble(),
      fat: (map['nutrients']['fat'] ?? 0).toDouble(),
      protein: (map['nutrients']['protein'] ?? 0).toDouble(),
    );
  }
}