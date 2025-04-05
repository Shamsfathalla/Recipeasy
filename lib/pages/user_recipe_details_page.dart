// lib/pages/user_recipe_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipeasy/models/recipe_model.dart';
import 'package:recipeasy/services/recipe_folder_service.dart';

class UserRecipeDetailsPage extends StatefulWidget {
  final String recipeId;
  final VoidCallback? onFolderUpdated;
  const UserRecipeDetailsPage({
    super.key,
    required this.recipeId,
    this.onFolderUpdated,
  });

  @override
  _UserRecipeDetailsPageState createState() => _UserRecipeDetailsPageState();
}

class _UserRecipeDetailsPageState extends State<UserRecipeDetailsPage> {
  final RecipeFolderService _folderService = RecipeFolderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
                      title: const Text('General'),
                      value: _isGeneralSelected || _isRecipeInFolder.values.any((value) => value),
                      onChanged: (value) {
                        if (_isRecipeInFolder.values.any((value) => value) && value == false) {
                          // Don't allow unselecting General if other folders are selected
                          return;
                        }
                        setState(() {
                          _isGeneralSelected = value ?? false;
                        });
                      },
                      activeColor: const Color.fromRGBO(110, 59, 226, 1),
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
                          activeColor: const Color.fromRGBO(110, 59, 226, 1),
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
    final isCurrentlyInGeneral = await _checkIfRecipeInFolder('general');
    // Handle General folder
    if (_isGeneralSelected && !isCurrentlyInGeneral) {
      await _folderService.addRecipeToFolder(
        folderId: 'general',
        recipeId: widget.recipeId,
      );
    } else if (!_isGeneralSelected && isCurrentlyInGeneral) {
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
    // Update bookmark status
    setState(() {
      _isBookmarked = _isGeneralSelected || _isRecipeInFolder.values.any((value) => value);
    });
    // Show success message
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
              duration: Duration(seconds: 3),
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
        _buildTextContent(_recipeDetails!.description),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ingredients'),
        ..._recipeDetails!.ingredients.map<Widget>(_buildIngredientItem).toList(),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Instructions'),
        if (_recipeDetails!.instructions.isEmpty)
          _buildTextContent('No instructions available.')
        else
          ..._recipeDetails!.instructions.map((step) {
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
                        '${_recipeDetails!.instructions.indexOf(step) + 1}',
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
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
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
                      color: _isBookmarked ? const Color.fromRGBO(110, 59, 226, 1) : Colors.grey,
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
                  _buildNavButton('About', 0),
                  _buildNavButton('Ingredients', 1),
                  _buildNavButton('Instructions', 2),
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