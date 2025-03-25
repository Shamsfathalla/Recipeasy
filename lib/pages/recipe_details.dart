import 'package:flutter/material.dart';
import '../services/Spoonacular_APi';

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailsPage({super.key, required this.recipeId});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  Map<String, dynamic>? _recipeDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  void _fetchRecipeDetails() async {
    try {
      final details = await _spoonacularService.getRecipeDetails(widget.recipeId);
      setState(() {
        _recipeDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching recipe details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipeDetails?['title'] ?? 'Recipe Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipeDetails == null
              ? const Center(child: Text('Failed to load recipe details.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_recipeDetails!['image'] != null)
                        Center(
                          child: Image.network(
                            _recipeDetails!['image'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _recipeDetails!['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_recipeDetails!.containsKey('summary'))
                        Text(
                          _recipeDetails!['summary']
                              .replaceAll(RegExp(r'<[^>]*>'), ''), // Remove HTML tags
                          style: const TextStyle(fontSize: 16),
                        ),
                      // Add more details like ingredients, instructions, etc., if available
                    ],
                  ),
                ),
    );
  }
}