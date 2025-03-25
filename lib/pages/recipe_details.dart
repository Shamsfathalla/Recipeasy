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
        content: Text(_isBookmarked
            ? 'Recipe bookmarked!'
            : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _recipeDetails!['image'],
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.fastfood, size: 100, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextSection(String text, {bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTitle ? 24 : 16,
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipeDetails?['title'] ?? 'Recipe Details'),
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
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recipeDetails!['image'] != null) _buildImageSection(),
            const SizedBox(height: 16),
            // Recipe title with bookmark button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildTextSection(
                    _recipeDetails!['title'],
                    isTitle: true,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.amber : Colors.grey,
                    size: 28,
                  ),
                  onPressed: _toggleBookmark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recipeDetails!.containsKey('summary'))
              _buildTextSection(
                _recipeDetails!['summary']
                    .replaceAll(RegExp(r'<[^>]*>'), ''),
              ),
            if (_recipeDetails!.containsKey('extendedIngredients'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTextSection('Ingredients:', isTitle: true),
                  ..._recipeDetails!['extendedIngredients']
                      .map<Widget>((ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0),
                    child: Text(
                        '• ${ingredient['original']}'),
                  ))
                      .toList(),
                ],
              ),
            if (_recipeDetails!.containsKey('instructions') &&
                _recipeDetails!['instructions'] != null &&
                _recipeDetails!['instructions'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTextSection('Instructions:', isTitle: true),
                  _buildTextSection(
                    _recipeDetails!['instructions']
                        .replaceAll(RegExp(r'<[^>]*>'), ''),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}