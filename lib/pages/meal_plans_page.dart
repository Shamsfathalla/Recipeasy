import 'package:flutter/material.dart';

class MealPlansPage extends StatelessWidget {
  const MealPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(context, 'General Meal Plans', [
            _buildMealPlanCard(context, '7-Day Meal Plan', 'A balanced meal plan for a week.'),
            _buildMealPlanCard(context, '30-Day Meal Plan', 'Stay on track with this month-long plan.')
          ]),
          _buildSection(context, 'Filtered Meal Plans', [
            _buildMealPlanCard(context, 'Vegetarian Meal Plan', 'Plant-based meals for a week.'),
            _buildMealPlanCard(context, 'Gluten-Free Meal Plan', 'Enjoy delicious gluten-free options.'),
            _buildMealPlanCard(context, 'Low-Carb Meal Plan', 'Perfect for those following a low-carb diet.')
          ]),
          _buildSection(context, 'Recommended Meal Plans', [
            _buildMealPlanCard(context, 'Weight Loss Plan', 'Tailored meals to help you lose weight.'),
            _buildMealPlanCard(context, 'Muscle Gain Plan', 'Nutrient-rich meals to support muscle growth.'),
            _buildMealPlanCard(context, 'Healthy Snack Plan', 'Quick and healthy snacks to keep you energized.')
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
        child: const Icon(Icons.add),
        onPressed: () {
          // Add functionality to create a new meal plan
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color.fromRGBO(110, 59, 226, 1),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildMealPlanCard(BuildContext context, String title, String description) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: const CircleAvatar(
          backgroundColor: Color.fromRGBO(110, 59, 226, 1),
          child: Icon(Icons.restaurant_menu, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
          ),
          onPressed: () {
            // Navigate to meal plan details page
          },
          child: const Text('View', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
