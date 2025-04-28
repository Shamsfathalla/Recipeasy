import 'package:flutter/material.dart';

class HelpFAQPage extends StatelessWidget {
  const HelpFAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & FAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(168, 64, 185, 1),
                Color.fromRGBO(110, 59, 226, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFAQItem(
              context,
              'How do I search for recipes?',
              'Use the search bar on the home screen. You can search by recipe name, ingredients.',
            ),
            _buildFAQItem(
              context,
              'How do I save recipes?',
              'When viewing a recipe, tap the bookmark icon, all recipes automatically save to "General" folder, the user can create or choose any created folders. Saved recipes can be found in Recipes page under Bookmarks, in which the user can move, and delete bookmarks, and create new folders.',
            ),
            _buildFAQItem(
              context,
              'Can I create my own recipes?',
              'Yes! Tap the "+" button on the home screen or in your profile to create a new recipe. Add description, ingredients, and instructions.',
            ),
            _buildFAQItem(
              context,
              'How do meal plans work?',
              'In the Meal Plans section, tap "settings icon" to adjust your minimum calorie, protein, carbohydrates and fat values. Meal plan will automatically be generated based on preferences.',
            ),
            _buildFAQItem(
              context,
              'How do I follow other users?',
              'Visit any user\'s profile and tap the "Follow" button. You\'ll see their public recipes in your feed.',
            ),
            _buildFAQItem(
              context,
              'Where can I find my shopping list?',
              'The user can add ingredients to their shopping list through recipe pages, and it will be updated to their shopping list page. The user can also manually add ingredients to their shopping list through "+" found in the page',
            ),
            const SizedBox(height: 20),
            _buildSupportMessage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportMessage(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.support_agent,
              size: 40,
              color: Color.fromRGBO(110, 59, 226, 1),
            ),
            const SizedBox(height: 10),
            Text(
              'Need more help?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Contact our support team at:'),
            const SizedBox(height: 4),
            const Text(
              'support@recipeasyapp.com',
              style: TextStyle(
                color: Color.fromRGBO(110, 59, 226, 1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}