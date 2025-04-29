import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/spoonacular_api';
import '../services/recipe_folder_service.dart';
import '../services/analytics_service.dart'; // Added new import

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;
  final VoidCallback? onFolderUpdated;
  const RecipeDetailsPage({
    super.key,
    required this.recipeId,
    this.onFolderUpdated,
  });

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  final RecipeFolderService _folderService = RecipeFolderService();
  final AnalyticsService _analyticsService = AnalyticsService(); // Added analytics service
  Map<String, dynamic>? _recipeDetails;
  bool _isLoading = true;
  bool _hasError = false;
  int _currentSectionIndex = 0;
  List<Map<String, dynamic>> _folders = [];
  Map<String, bool> _isRecipeInFolder = {};
  bool _isBookmarked = false;
  bool _isGeneralSelected = true;
  final TextEditingController _newFolderController = TextEditingController();
  String? _errorMessage;

  bool get _areOtherFoldersSelected => _isRecipeInFolder.values.any((value) => value);

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _loadFolders();
    _trackRecipeView(); // Added analytics tracking
  }

  // Added new method for tracking recipe views
  Future<void> _trackRecipeView() async {
    try {
      await _analyticsService.incrementRecipesVisited();
    } catch (e) {
      debugPrint('Error tracking recipe view: $e');
    }
  }

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
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

  Future<void> _loadFolders() async {
    final folders = await _folderService.getUserFolders();
    setState(() {
      _folders = folders.where((folder) => folder['id'] != 'general').toList();
    });
    // Check General folder
    _isGeneralSelected = await _checkIfRecipeInFolder('general');
    // Check other folders
    bool isInAnyOtherFolder = false;
    for (final folder in _folders) {
      final isInFolder = await _checkIfRecipeInFolder(folder['id']);
      setState(() {
        _isRecipeInFolder[folder['id']] = isInFolder;
      });
      if (isInFolder) {
        isInAnyOtherFolder = true;
      }
    }
    setState(() {
      _isBookmarked = _isGeneralSelected || isInAnyOtherFolder;
    });
  }

  Future<bool> _checkIfRecipeInFolder(String folderId) async {
    final recipes = await _folderService.getRecipesInFolder(folderId);
    return recipes.any((recipe) => recipe['recipeId'] == widget.recipeId);
  }

  void _showFolderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Save Recipe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newFolderController,
                              decoration: const InputDecoration(
                                labelText: 'New folder name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final folderName = _newFolderController.text.trim();
                              if (folderName.isNotEmpty) {
                                if (_folders.any((folder) => folder['name'] == folderName)) {
                                  setState(() {
                                    _errorMessage = 'Folder with this name already exists.';
                                  });
                                  return;
                                }
                                setState(() {
                                  _errorMessage = null;
                                });
                                await _folderService.createFolder(folderName);
                                _newFolderController.clear();
                                await _loadFolders();
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      title: const Text('All Bookmarks'),
                      value: _isGeneralSelected || _areOtherFoldersSelected,
                      onChanged: (value) {
                        if (_areOtherFoldersSelected && value == false) {
                          return;
                        }
                        setState(() {
                          _isGeneralSelected = value ?? false;
                        });
                      },
                      activeColor: const Color.fromRGBO(120, 60, 219, 1),
                    ),
                    if (_folders.isEmpty)
                      const Text('No folders available')
                    else
                      ..._folders.map((folder) {
                        return CheckboxListTile(
                          title: Text(folder['name']),
                          value: _isRecipeInFolder[folder['id']] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _isRecipeInFolder[folder['id']] = value!;
                            });
                          },
                          activeColor: const Color.fromRGBO(120, 60, 219, 1),
                        );
                      }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateFolders();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateFolders() async {
    final shouldBeInGeneral = _isGeneralSelected || _areOtherFoldersSelected;
    final isCurrentlyInGeneral = await _checkIfRecipeInFolder('general');

    // Track whether we need to count analytics
    bool shouldCountAnalytics = false;

    // Handle General folder
    if (shouldBeInGeneral && !isCurrentlyInGeneral) {
      await _folderService.addRecipeToFolder(
        folderId: 'general',
        recipeId: widget.recipeId,
      );
      shouldCountAnalytics = true;
    } else if (!shouldBeInGeneral && isCurrentlyInGeneral) {
      final recipes = await _folderService.getRecipesInFolder('general');
      final recipeDoc = recipes.firstWhere(
            (recipe) => recipe['recipeId'] == widget.recipeId,
      );
      await _folderService.removeRecipeFromFolder(
        folderId: 'general',
        recipeDocId: recipeDoc['id'],
      );
    }

    // Handle other folders
    for (final folder in _folders) {
      final folderId = folder['id'];
      final shouldBeInFolder = _isRecipeInFolder[folderId] ?? false;
      final isCurrentlyInFolder = await _checkIfRecipeInFolder(folderId);

      if (shouldBeInFolder && !isCurrentlyInFolder) {
        await _folderService.addRecipeToFolder(
          folderId: folderId,
          recipeId: widget.recipeId,
        );
        shouldCountAnalytics = true;

        // Ensure it's also in General folder when adding to any folder
        if (!isCurrentlyInGeneral && !shouldBeInGeneral) {
          await _folderService.addRecipeToFolder(
            folderId: 'general',
            recipeId: widget.recipeId,
          );
        }
      } else if (!shouldBeInFolder && isCurrentlyInFolder) {
        final recipes = await _folderService.getRecipesInFolder(folderId);
        final recipeDoc = recipes.firstWhere(
              (recipe) => recipe['recipeId'] == widget.recipeId,
        );
        await _folderService.removeRecipeFromFolder(
          folderId: folderId,
          recipeDocId: recipeDoc['id'],
        );
      }
    }

    // Only count analytics once per bookmark operation
    if (shouldCountAnalytics) {
      await _analyticsService.incrementBookmarksAdded();
    }

    setState(() {
      _isBookmarked = shouldBeInGeneral || _isRecipeInFolder.values.any((value) => value);
      _isGeneralSelected = _isBookmarked;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Recipe saved to your folders!'
                : 'Recipe removed from your folders',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (widget.onFolderUpdated != null) {
      widget.onFolderUpdated!();
    }
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
          color: const Color.fromRGBO(120, 60, 219, 1),
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
            child: Icon(Icons.circle, size: 8, color: const Color.fromRGBO(120, 60, 219, 1)),
          ),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _addIngredientToShoppingList(ingredient);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addIngredientToShoppingList(String ingredient) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to add ingredients to your shopping list.'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final collectionRef = FirebaseFirestore.instance.collection('users/${user.uid}/shopping_list');
      final querySnapshot = await collectionRef.where('name', isEqualTo: ingredient).get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        await collectionRef.doc(doc.id).update({
          'quantity': FieldValue.increment(1),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added another "$ingredient" to your shopping list.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await collectionRef.add({
          'name': ingredient,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "$ingredient" to your shopping list.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding ingredient to shopping list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add "$ingredient" to your shopping list.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
    String rawInstructions = _recipeDetails!['instructions'] ?? '';
    String cleanedInstructions = rawInstructions.replaceAll(RegExp(r'<[^>]*>'), '');
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
                      color: const Color.fromRGBO(120, 60, 219, 1),
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
      default:
        return _buildAboutSection();
    }
  }

  Widget _buildNavButton(String text, int index, BuildContext context) {
    final isSelected = _currentSectionIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextButton(
      onPressed: () {
        setState(() {
          _currentSectionIndex = index;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? const Color.fromRGBO(120, 60, 219, 1)
            : isDarkMode ? Colors.white : Colors.black,
        textStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Details',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(161, 63, 190, 1),
                Color.fromRGBO(120, 60, 219, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
                backgroundColor: const Color.fromRGBO(120, 60, 219, 1),
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
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      color: _isBookmarked
                          ? const Color.fromRGBO(120, 60, 219, 1)
                          : isDarkMode ? Colors.white : Colors.black,
                      size: 30,
                    ),
                    onPressed: _showFolderDialog,
                    tooltip: 'Bookmark recipe',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton('About', 0, context),
                  _buildNavButton('Ingredients', 1, context),
                  _buildNavButton('Instructions', 2, context),
                ],
              ),
            ),
            _buildCurrentSection(),
          ],
        ),
      ),
    );
  }
}