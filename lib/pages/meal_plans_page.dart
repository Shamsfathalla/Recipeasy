import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeasy/services/Spoonacular_APi';
import 'package:recipeasy/models/meal_planning.dart';
import 'package:recipeasy/theme_provider.dart';
import 'package:recipeasy/pages/recipe_details.dart';

class MealPlansPage extends StatefulWidget {
  final String userId;

  const MealPlansPage({super.key, required this.userId});

  @override
  _MealPlansPageState createState() => _MealPlansPageState();
}

class _MealPlansPageState extends State<MealPlansPage> {
  final SpoonacularService _spoonacularService = SpoonacularService();

  MealPlan? _mealPlan;
  bool _isLoading = false;
  String _errorMessage = '';

  // Purple color constants
  static const Color purplePrimary = Color(0xFF6A1B9A);
  static const Color purpleLight = Color(0xFF9C4DFF);
  static const Color purpleDark = Color(0xFF38006B);

  @override
  void initState() {
    super.initState();
    _fetchMealPlan();
  }

  Future<void> _fetchMealPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      MealPlan mealPlan = await _spoonacularService.generateMealPlan(
        targetCalories: 2000,
        diet: '',
        minProtein: 50,
        minCarbs: 130,
        minFat: 30,
        includeIngredients: '',
        excludeIngredients: '',
      );

      setState(() {
        _mealPlan = mealPlan;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load meal plan: $error')),
      );
    }
  }

  void _navigateToRecipeDetails(int recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipeId: recipeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _mealPlan == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No meal plan available'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: purplePrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchMealPlan,
              child: const Text('Generate Meal Plan'),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Your Daily Meal Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: purplePrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_mealPlan!.calories.round()} calories • '
                'Protein: ${_mealPlan!.protein.round()}g • '
                'Carbs: ${_mealPlan!.carbs.round()}g • '
                'Fat: ${_mealPlan!.fat.round()}g',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode
                  ? colorScheme.onSurface.withOpacity(0.8)
                  : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          ..._buildMealPlanList(isDarkMode, colorScheme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: purplePrimary,
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _fetchMealPlan,
      ),
    );
  }

  List<Widget> _buildMealPlanList(bool isDarkMode, ColorScheme colorScheme) {
    return _mealPlan!.meals.map((meal) {
      return Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        color: isDarkMode ? colorScheme.surfaceVariant : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12.0),
          leading: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              meal.imageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return CircleAvatar(
                  backgroundColor: purplePrimary,
                  child: const Icon(Icons.restaurant_menu, color: Colors.white),
                );
              },
            ),
          )
              : CircleAvatar(
            backgroundColor: purplePrimary,
            child: const Icon(Icons.restaurant_menu, color: Colors.white),
          ),
          title: Text(
            meal.title ?? "Unknown Meal",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? colorScheme.onSurface : Colors.black,
            ),
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              backgroundColor: purplePrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (meal.id != null) {
                _navigateToRecipeDetails(meal.id!);
              }
            },
            child: const Text('View'),
          ),
        ),
      );
    }).toList();
  }
}