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
  bool _hasError = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final details = await _spoonacularService.getRecipeDetails(widget.recipeId);
      if (mounted) {
        setState(() {
          _recipeDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      debugPrint('Error fetching recipe details: $e');
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Recipe bookmarked!' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _recipeDetails!['image'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color.fromRGBO(110, 59, 226, 1), // Purple color
        ),
      ),
    );
  }

  Widget _buildTextContent(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildIngredientItem(String ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 8, color: const Color.fromRGBO(110, 59, 226, 1)), // Purple color
          ),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipeDetails?['title'] ?? 'Recipe Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || _recipeDetails == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load recipe details.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRecipeDetails,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromRGBO(110, 59, 226, 1), // Purple color
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recipeDetails!['image'] != null) _buildImageSection(),

            // Title and Bookmark
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _recipeDetails!['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? const Color.fromRGBO(110, 59, 226, 1) : Colors.grey[600],
                      size: 30,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                ],
              ),
            ),

            // Description
            if (_recipeDetails!.containsKey('summary'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('About this recipe'),
                  _buildTextContent(
                    _recipeDetails!['summary'].replaceAll(RegExp(r'<[^>]*>'), ''),
                  ),
                  const Divider(height: 24),
                ],
              ),

            // Ingredients
            if (_recipeDetails!.containsKey('extendedIngredients'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Ingredients'),
                  ..._recipeDetails!['extendedIngredients']
                      .map<Widget>((ingredient) => _buildIngredientItem(ingredient['original']))
                      .toList(),
                  const Divider(height: 24),
                ],
              ),

            // Instructions
            if (_recipeDetails!.containsKey('instructions') &&
                _recipeDetails!['instructions'] != null &&
                _recipeDetails!['instructions'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Instructions'),
                  _buildTextContent(
                    _recipeDetails!['instructions'].replaceAll(RegExp(r'<[^>]*>'), ''),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
