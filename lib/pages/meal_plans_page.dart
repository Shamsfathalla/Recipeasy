import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeasy/services/Spoonacular_APi';
import 'package:recipeasy/models/meal_planning.dart';
import 'package:recipeasy/theme_provider.dart';
import 'package:recipeasy/pages/recipe_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meal_details.dart';

class MealPlansPage extends StatefulWidget {
  final String userId;

  const MealPlansPage({super.key, required this.userId});

  @override
  _MealPlansPageState createState() => _MealPlansPageState();
}

class _MealPlansPageState extends State<MealPlansPage> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MealPlan? _mealPlan;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _errorMessage = '';
  Map<String, dynamic>? _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndMealPlan();
  }

  Future<void> _loadPreferencesAndMealPlan() async {
    await _loadPreferences();
    await _fetchMealPlan();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      if (doc.exists && doc.data()?['mealPlanPreferences'] != null) {
        setState(() {
          _preferences = doc.data()?['mealPlanPreferences'] as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _preferences = {
            'calories': 2000,
            'protein': 50,
            'carbs': 130,
            'fat': 30,
          };
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load preferences: $e';
      });
    }
  }

  Future<void> _fetchMealPlan() async {
    if (_preferences == null) return;

    setState(() => _isRefreshing = true);

    try {
      MealPlan mealPlan = await _spoonacularService.generateMealPlan(
        targetCalories: _preferences!['calories'] ?? 2000,
        diet: '',
        minProtein: _preferences!['protein'] ?? 50,
        minCarbs: _preferences!['carbs'] ?? 130,
        minFat: _preferences!['fat'] ?? 30,
        includeIngredients: '',
        excludeIngredients: '',
      );

      double totalCost = 0.0;

      for (var meal in mealPlan.meals) {
        if (meal.id != null) {
          final priceBreakdown = await _spoonacularService.getRecipePriceBreakdown(meal.id!);
          totalCost += priceBreakdown['totalCost'] ?? 0.0;
        }
      }

      setState(() {
        _mealPlan = mealPlan;
        _mealPlan!.totalCost = totalCost; // Add total cost to the meal plan
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _isRefreshing = false;
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

  void _navigateToMealPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealDetailsPage(),
      ),
    ).then((_) => _loadPreferencesAndMealPlan());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDarkMode
            ? const Color.fromRGBO(110, 59, 226, 1) // Purple in dark mode
            : const Color.fromRGBO(255, 234, 221, 1), // Light peach in light mode
        child: Icon(
          Icons.settings,
          color: isDarkMode
              ? Colors.white // White icon in dark mode
              : const Color.fromARGB(255, 79, 55, 139),
        ),
        onPressed: _navigateToMealPreferences,
      ),
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
              onPressed: _fetchMealPlan,
              child: const Text('Generate Meal Plan'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Daily Meal Plan',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _isRefreshing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchMealPlan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_mealPlan!.calories.round()} calories • '
                  'Protein: ${_mealPlan!.protein.round()}g • '
                  'Carbs: ${_mealPlan!.carbs.round()}g • '
                  'Fat: ${_mealPlan!.fat.round()}g',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? colorScheme.onSurface.withValues(alpha: (0.8))
                    : Colors.grey[700],
              ),
            ),
            Text(
          'Total Cost: \$${_mealPlan!.totalCost.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? colorScheme.onSurface : Colors.black,
          ),
        ),
            const SizedBox(height: 16),
            ..._buildMealPlanList(isDarkMode, colorScheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealPlanList(bool isDarkMode, ColorScheme colorScheme) {
    return _mealPlan!.meals.map((meal) {
      return Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        color: isDarkMode
            ? colorScheme.surfaceContainerHighest.withValues(alpha: (0.3))
            : Colors.grey[200],
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            if (meal.id != null) {
              _navigateToRecipeDetails(meal.id!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    meal.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.restaurant_menu);
                    },
                  ),
                )
                    : const Icon(Icons.restaurant_menu),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    meal.title ?? "Unknown Meal",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? colorScheme.onSurface : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}