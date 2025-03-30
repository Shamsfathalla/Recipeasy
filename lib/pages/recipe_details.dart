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
  int _currentSectionIndex = 0; // 0: About, 1: Ingredients, 2: Instructions, 3: Nutrition

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

  void _showShareUI() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would appear here'),
        duration: Duration(seconds: 1),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color.fromRGBO(110, 59, 226, 1),
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
            child: Icon(Icons.circle, size: 8, color: const Color.fromRGBO(110, 59, 226, 1)),
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

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About this recipe'),
        if (_recipeDetails!['spoonacularScore'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Spoonacular Score: ${_recipeDetails!['spoonacularScore']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        _buildTextContent(
          _recipeDetails!['summary'].replaceAll(RegExp(r'<[^>]*>'), ''),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ingredients'),
        ..._recipeDetails!['extendedIngredients']
            .map<Widget>((ingredient) => _buildIngredientItem(ingredient['original']))
            .toList(),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    // Clean up instructions by splitting into steps
    String rawInstructions = _recipeDetails!['instructions'] ?? '';
    String cleanedInstructions = rawInstructions.replaceAll(RegExp(r'<[^>]*>'), '');

    // Split instructions into steps (assuming they're numbered or separated by newlines)
    List<String> instructionSteps = cleanedInstructions.split('\n').where((step) => step.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Instructions'),
        if (instructionSteps.isEmpty)
          _buildTextContent('No instructions available.')
        else
          ...instructionSteps.map((step) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12, top: 4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(110, 59, 226, 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${instructionSteps.indexOf(step) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step.trim(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildNutritionSection() {
    if (_recipeDetails!['nutrition'] == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Nutrition Information'),
          _buildTextContent('No nutrition information available.'),
        ],
      );
    }

    final nutrition = _recipeDetails!['nutrition'];
    final nutrients = nutrition['nutrients'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nutrition Information'),
        if (nutrients == null || nutrients.isEmpty)
          _buildTextContent('No nutrition data available.')
        else
          Column(
            children: nutrients.map((nutrient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        nutrient['name'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${nutrient['amount']?.toStringAsFixed(1) ?? 'N/A'} ${nutrient['unit'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCurrentSection() {
    if (_recipeDetails == null) return const SizedBox();

    switch (_currentSectionIndex) {
      case 0:
        return _buildAboutSection();
      case 1:
        return _buildIngredientsSection();
      case 2:
        return _buildInstructionsSection();
      case 3:
        return _buildNutritionSection();
      default:
        return _buildAboutSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
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
                backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
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

            // Title and Action Buttons
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
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
                    icon: const Icon(Icons.share),
                    onPressed: _showShareUI,
                    tooltip: 'Share recipe',
                  ),
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? const Color.fromRGBO(110, 59, 226, 1) : Colors.grey[600],
                    ),
                    onPressed: _toggleBookmark,
                    tooltip: 'Bookmark recipe',
                  ),
                ],
              ),
            ),

            // Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton('About', 0),
                  _buildNavButton('Ingredients', 1),
                  _buildNavButton('Instructions', 2),
                  _buildNavButton('Nutrition', 3),
                ],
              ),
            ),

            // Current Section Content
            _buildCurrentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String text, int index) {
    final isSelected = _currentSectionIndex == index;
    return TextButton(
      onPressed: () {
        setState(() {
          _currentSectionIndex = index;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? const Color.fromRGBO(110, 59, 226, 1) : Colors.grey,
        textStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      child: Text(text),
    );
  }
}