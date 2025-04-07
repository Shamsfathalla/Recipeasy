import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipeasy/models/recipe_model.dart';
import 'package:recipeasy/services/recipe_folder_service.dart';
import 'package:recipeasy/services/analytics_service.dart'; // Added new import

class UserRecipeDetailsPage extends StatefulWidget {
  final String recipeId;
  final VoidCallback? onFolderUpdated;
  const UserRecipeDetailsPage({
    super.key,
    required this.recipeId,
    this.onFolderUpdated,
  });

  @override
  State<UserRecipeDetailsPage> createState() => _UserRecipeDetailsPageState();
}

class _UserRecipeDetailsPageState extends State<UserRecipeDetailsPage> {
  final RecipeFolderService _folderService = RecipeFolderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analyticsService = AnalyticsService(); // Added analytics service
  Recipe? _recipeDetails;
  bool _isLoading = true;
  bool _hasError = false;
  int _currentSectionIndex = 0;
  List<Map<String, dynamic>> _folders = [];
  Map<String, bool> _isRecipeInFolder = {};
  bool _isBookmarked = false;
  bool _isGeneralSelected = true;
  final TextEditingController _newFolderController = TextEditingController();
  String? _errorMessage;

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
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _recipeDetails = Recipe.fromJson(snapshot.data()!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error fetching recipe details: $e');
    }
  }

  Future<void> _loadFolders() async {
    final folders = await _folderService.getUserFolders();
    setState(() {
      _folders = folders.where((folder) => folder['id'] != 'general').toList();
    });

    _isGeneralSelected = await _checkIfRecipeInFolder('general');

    bool isInAnyOtherFolder = false;
    for (final folder in _folders) {
      final isInFolder = await _checkIfRecipeInFolder(folder['id']);
      setState(() {
        _isRecipeInFolder[folder['id']] = isInFolder;
      });
      if (isInFolder) isInAnyOtherFolder = true;
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
                              if (folderName.isEmpty) return;

                              if (_folders.any((folder) => folder['name'] == folderName)) {
                                setState(() {
                                  _errorMessage = 'Folder already exists';
                                });
                                return;
                              }

                              await _folderService.createFolder(folderName);
                              _newFolderController.clear();
                              await _loadFolders();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      title: const Text('General'),
                      value: _isGeneralSelected || _isRecipeInFolder.values.any((v) => v),
                      onChanged: (value) {
                        if (_isRecipeInFolder.values.any((v) => v) && value == false) return;
                        setState(() => _isGeneralSelected = value ?? false);
                      },
                      activeColor: const Color.fromRGBO(110, 59, 226, 1),
                    ),
                    if (_folders.isEmpty)
                      const Text('No folders available')
                    else
                      ..._folders.map((folder) => CheckboxListTile(
                        title: Text(folder['name']),
                        value: _isRecipeInFolder[folder['id']] ?? false,
                        onChanged: (value) {
                          setState(() => _isRecipeInFolder[folder['id']] = value!);
                        },
                        activeColor: const Color.fromRGBO(110, 59, 226, 1),
                      )),
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
    final shouldBeInGeneral = _isGeneralSelected || _isRecipeInFolder.values.any((v) => v);
    final isInGeneral = await _checkIfRecipeInFolder('general');

    // Track whether we need to count analytics
    bool shouldCountAnalytics = false;

    // Handle General folder
    if (shouldBeInGeneral && !isInGeneral) {
      await _folderService.addRecipeToFolder(
        folderId: 'general',
        recipeId: widget.recipeId,
      );
      shouldCountAnalytics = true;
    } else if (!shouldBeInGeneral && isInGeneral) {
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
      final isInFolder = await _checkIfRecipeInFolder(folderId);

      if (shouldBeInFolder && !isInFolder) {
        await _folderService.addRecipeToFolder(
          folderId: folderId,
          recipeId: widget.recipeId,
        );
        shouldCountAnalytics = true;

        // Ensure it's also in General folder when adding to any folder
        if (!isInGeneral && !shouldBeInGeneral) {
          await _folderService.addRecipeToFolder(
            folderId: 'general',
            recipeId: widget.recipeId,
          );
        }
      } else if (!shouldBeInFolder && isInFolder) {
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
      _isBookmarked = shouldBeInGeneral || _isRecipeInFolder.values.any((v) => v);
      _isGeneralSelected = _isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked
            ? 'Recipe saved to folders!'
            : 'Recipe removed from folders'),
        duration: const Duration(seconds: 2),
      ),
    );

    widget.onFolderUpdated?.call();
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color.fromRGBO(110, 59, 226, 1),
        ),
      ),
    );
  }

  Widget _buildTextContent(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.5),
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
            child: Icon(
              Icons.circle,
              size: 8,
              color: const Color.fromRGBO(110, 59, 226, 1),
            ),
          ),
          Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 16))),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addIngredientToShoppingList(ingredient),
          ),
        ],
      ),
    );
  }

  Future<void> _addIngredientToShoppingList(String ingredient) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add ingredients'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final collection = FirebaseFirestore.instance
          .collection('users/${user.uid}/shopping_list');

      final query = await collection.where('name', isEqualTo: ingredient).get();

      if (query.docs.isNotEmpty) {
        await collection.doc(query.docs.first.id).update({
          'quantity': FieldValue.increment(1),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added another "$ingredient"'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        await collection.add({
          'name': ingredient,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$ingredient"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding ingredient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add ingredient'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About this recipe'),
        _buildTextContent(_recipeDetails!.description),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ingredients'),
        ..._recipeDetails!.ingredients.map(_buildIngredientItem).toList(),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Instructions'),
        if (_recipeDetails!.instructions.isEmpty)
          _buildTextContent('No instructions available')
        else
          ..._recipeDetails!.instructions.map((step) {
            final index = _recipeDetails!.instructions.indexOf(step) + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12, top: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(110, 59, 226, 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Text(step.trim(), style: const TextStyle(fontSize: 16))),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildCurrentSection() {
    if (_recipeDetails == null) return const SizedBox();
    switch (_currentSectionIndex) {
      case 0: return _buildAboutSection();
      case 1: return _buildIngredientsSection();
      case 2: return _buildInstructionsSection();
      default: return _buildAboutSection();
    }
  }

  Widget _buildNavButton(String text, int index) {
    final isSelected = _currentSectionIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDarkMode ? Colors.white : Colors.black;

    return TextButton(
      onPressed: () => setState(() => _currentSectionIndex = index),
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? const Color.fromRGBO(110, 59, 226, 1)
            : unselectedColor,
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
    final unselectedColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
            const Text('Failed to load recipe'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRecipeDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _recipeDetails!.title,
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
                        ? const Color.fromRGBO(110, 59, 226, 1)
                        : unselectedColor,
                    size: 30,
                  ),
                  onPressed: _showFolderDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton('About', 0),
                _buildNavButton('Ingredients', 1),
                _buildNavButton('Instructions', 2),
              ],
            ),
            const SizedBox(height: 16),
            _buildCurrentSection(),
          ],
        ),
      ),
    );
  }
}