// lib/pages/my_recipes_page.dart
import 'package:flutter/material.dart';
import 'package:recipeasy/models/recipe_model.dart';
import 'package:recipeasy/services/recipe_folder_service.dart';
import 'package:recipeasy/services/spoonacular_api';
import 'package:recipeasy/pages/recipe_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_recipe_page.dart';
import 'package:recipeasy/pages/user_recipe_details_page.dart';

class MyRecipesPage extends StatefulWidget {
  @override
  _MyRecipesPageState createState() => _MyRecipesPageState();
}

class _MyRecipesPageState extends State<MyRecipesPage> {
  final RecipeFolderService _folderService = RecipeFolderService();
  final SpoonacularService _spoonacularService = SpoonacularService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<_BookmarksPageState> _bookmarksPageKey = GlobalKey<_BookmarksPageState>();
  List<Recipe> _userRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadUserRecipes();
  }

  Future<void> _loadUserRecipes() async {
    setState(() {
      _userRecipes = [];
    });
    try {
      final recipes = await _folderService.getUserRecipes();
      setState(() {
        _userRecipes = recipes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load recipes: $e')));
    }
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? errorMessage; // Track duplicate folder error
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create New Folder'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Folder Name',
                        errorText: errorMessage, // Show duplicate error here
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a folder name';
                        }
                        if (value.length > 30) {
                          return 'Folder name too long (max 30 chars)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Clear error when user types
                        if (errorMessage != null) {
                          setState(() => errorMessage = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Check for duplicates in real-time
                      final folders = await _folderService.getUserFolders();
                      final isDuplicate = folders.any((f) =>
                      f['name'].toLowerCase() == controller.text.toLowerCase());
                      if (isDuplicate) {
                        setState(() {
                          errorMessage = 'A folder with this name already exists';
                        });
                        return;
                      }
                      Navigator.pop(context);
                      await _folderService.createFolder(controller.text);
                      _bookmarksPageKey.currentState?._loadFolders();
                    }
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              indicatorColor: Color.fromARGB(255, 110, 59, 226),
              tabs: [
                Tab(text: 'Bookmarks'),
                Tab(text: 'My Recipes'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            BookmarksPage(
              key: _bookmarksPageKey,
              folderService: _folderService,
              spoonacularService: _spoonacularService,
            ),
            MyRecipesPageContent(
              userRecipes: _userRecipes,
              onRecipeDeleted: _loadUserRecipes,
              onRecipeEdited: _loadUserRecipes,
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                return FloatingActionButton(
                  backgroundColor: Color.fromARGB(255, 110, 59, 226),
                  onPressed: () async {
                    if (tabController.index == 0) {
                      await _showCreateFolderDialog(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateRecipePage()),
                      ).then((_) => _loadUserRecipes());
                    }
                  },
                  child: IconTheme(
                    data: IconThemeData(color: Colors.white),
                    child: Icon(tabController.index == 0 ? Icons.create_new_folder : Icons.add),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class BookmarksPage extends StatefulWidget {
  final RecipeFolderService folderService;
  final SpoonacularService spoonacularService;
  const BookmarksPage({
    required this.folderService,
    required this.spoonacularService,
    Key? key,
  }) : super(key: key);

  @override
  _BookmarksPageState createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Map<String, dynamic>> _folders = [];
  String? _selectedFolderId = 'general';
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = false;
  bool _isPageVisible = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPageVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (isPageVisible && !_isPageVisible) {
      _loadFolders();
    }
    _isPageVisible = isPageVisible;
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });
    final folders = await widget.folderService.getUserFolders();
    setState(() {
      _folders = folders;
      _selectedFolderId = 'general';
    });
    await _loadRecipesInFolder(_selectedFolderId!);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRecipesInFolder(String folderId) async {
    setState(() {
      _isLoading = true;
      _recipes = [];
    });
    try {
      List<Map<String, dynamic>> apiRecipes = [];
      List<Map<String, dynamic>> userRecipes = [];
      final recipeDocs = await widget.folderService.getRecipesInFolder(folderId);
      for (final doc in recipeDocs) {
        final recipeId = doc['recipeId'];
        try {
          Map<String, dynamic>? details;
          if (recipeId is int) {
            details = await widget.spoonacularService.getRecipeDetails(recipeId);
            if (details != null) {
              apiRecipes.add({
                ...details,
                'docId': doc['id'],
                'folderId': folderId,
              });
            }
          } else if (recipeId is String) {
            details = await widget.folderService.getUserRecipeDetails(recipeId);
            if (details != null) {
              userRecipes.add({
                ...details,
                'docId': doc['id'],
                'folderId': folderId,
              });
            }
          } else {
            throw Exception('Invalid recipe ID type: $recipeId');
          }
        } catch (e) {
          print('Error loading recipe $recipeId: $e');
        }
      }
      // Combine both lists
      final combinedRecipes = [...apiRecipes, ...userRecipes];
      setState(() {
        _recipes = combinedRecipes;
      });
      if (combinedRecipes.isEmpty) {
        print('No recipes found for folderId: $folderId');
      }
    } catch (e) {
      print('Error loading recipes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recipes')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    if (folderId == 'general') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete the General folder')),
      );
      return;
    }
    // Check if folder is empty
    final recipes = await widget.folderService.getRecipesInFolder(folderId);
    final bool isFolderEmpty = recipes.isEmpty;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder'),
        content: Text(isFolderEmpty
            ? 'Are you sure you want to delete this empty folder?'
            : 'Are you sure you want to delete this folder?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    if (!shouldDelete) return;
    // Only show the additional prompt if folder has recipes
    bool deleteFromAll = false;
    if (!isFolderEmpty) {
      deleteFromAll = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Recipes'),
          content: Text('Do you want to delete these recipes from ALL folders including General?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No, keep recipes'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes, delete all copies', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
    }
    try {
      if (!isFolderEmpty && deleteFromAll) {
        await _removeRecipesFromAllFolders(folderId);
      }
      await widget.folderService.deleteFolder(folderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder deleted successfully')),
      );
      await _loadFolders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete folder: $e')),
      );
    }
  }

  Future<void> _removeRecipesFromAllFolders(String folderId) async {
    final recipes = await widget.folderService.getRecipesInFolder(folderId);
    final recipeIds = recipes.map((r) => r['recipeId']).toSet();
    final allFolders = await widget.folderService.getUserFolders();
    if (!allFolders.any((f) => f['id'] == 'general')) {
      allFolders.add({'id': 'general', 'name': 'General'});
    }
    for (final folder in allFolders) {
      final folderRecipes = await widget.folderService.getRecipesInFolder(folder['id']);
      for (final recipe in folderRecipes) {
        if (recipeIds.contains(recipe['recipeId'])) {
          await widget.folderService.removeRecipeFromFolder(
            folderId: folder['id'],
            recipeDocId: recipe['id'],
          );
        }
      }
    }
  }

  Future<void> _removeRecipeFromFolder(String folderId, String docId) async {
    try {
      await widget.folderService.removeRecipeFromFolder(
        folderId: folderId,
        recipeDocId: docId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe removed from folder')),
      );
      await _loadRecipesInFolder(_selectedFolderId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove recipe: $e')),
      );
    }
  }

  Future<void> _showDeleteOptions(Map<String, dynamic> recipe) async {
    if (_selectedFolderId == 'general') {
      await _removeRecipeFromAllFolders(recipe['id']);
    } else {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Recipe'),
          content: Text('How would you like to delete this recipe?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'current'),
              child: Text('From this folder only'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'all'),
              child: Text('From all folders', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
      if (action == 'current') {
        await _removeRecipeFromFolder(recipe['folderId'], recipe['docId']);
      } else if (action == 'all') {
        await _removeRecipeFromAllFolders(recipe['id']);
      }
    }
  }

  Future<void> _removeRecipeFromAllFolders(Object recipeId) async {
    try {
      for (final folder in _folders) {
        final recipes = await widget.folderService.getRecipesInFolder(folder['id']);
        for (final recipe in recipes) {
          if (recipe['recipeId'] == recipeId) {
            await widget.folderService.removeRecipeFromFolder(
              folderId: folder['id'],
              recipeDocId: recipe['id'],
            );
          }
        }
      }
      final generalRecipes = await widget.folderService.getRecipesInFolder('general');
      for (final recipe in generalRecipes) {
        if (recipe['recipeId'] == recipeId) {
          await widget.folderService.removeRecipeFromFolder(
            folderId: 'general',
            recipeDocId: recipe['id'],
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe removed from all folders')),
      );
      await _loadRecipesInFolder(_selectedFolderId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove recipe: $e')),
      );
    }
  }

  Future<void> _moveRecipeToFolders(Map<String, dynamic> recipe) async {
    final availableFolders = _folders.where((f) =>
    f['id'] != recipe['folderId'] && f['id'] != 'general').toList();
    final selectedFolders = <String, bool>{};
    for (final folder in availableFolders) {
      selectedFolders[folder['id']] = false;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Move to Folders'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Select destination folders:'),
                      SizedBox(height: 10),
                      ...availableFolders.map((folder) {
                        return CheckboxListTile(
                          title: Text(folder['name']),
                          value: selectedFolders[folder['id']] ?? false,
                          onChanged: (value) {
                            setState(() {
                              selectedFolders[folder['id']] = value!;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _performMoveToFolders(recipe, selectedFolders);
                  },
                  child: Text('Move'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performMoveToFolders(
      Map<String, dynamic> recipe,
      Map<String, bool> selectedFolders
      ) async {
    try {
      await widget.folderService.removeRecipeFromFolder(
        folderId: recipe['folderId'],
        recipeDocId: recipe['docId'],
      );
      for (final entry in selectedFolders.entries) {
        if (entry.value) {
          await widget.folderService.addRecipeToFolder(
            folderId: entry.key,
            recipeId: recipe['id'],
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe moved successfully')),
      );
      await _loadRecipesInFolder(_selectedFolderId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final unselectedTextColor = isDarkMode ? Colors.white : Colors.black;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!_folders.any((f) => f['id'] == 'general'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text('General'),
                      selected: _selectedFolderId == 'general',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFolderId = 'general';
                          });
                          _loadRecipesInFolder('general');
                        }
                      },
                      backgroundColor: _selectedFolderId == 'general'
                          ? Color.fromARGB(255, 110, 59, 226).withOpacity(0.2)
                          : Color.fromARGB(255, 110, 59, 226).withOpacity(0.1),
                      selectedColor: Color.fromARGB(255, 110, 59, 226).withOpacity(0.4),
                      labelStyle: TextStyle(
                        color: _selectedFolderId == 'general'
                            ? Color.fromARGB(255, 110, 59, 226)
                            : unselectedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ..._folders.map((folder) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(folder['name']),
                      selected: _selectedFolderId == folder['id'],
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFolderId = folder['id'];
                          });
                          _loadRecipesInFolder(folder['id']);
                        }
                      },
                      backgroundColor: _selectedFolderId == folder['id']
                          ? Color.fromARGB(255, 110, 59, 226).withOpacity(0.2)
                          : Color.fromARGB(255, 110, 59, 226).withOpacity(0.1),
                      selectedColor: Color.fromARGB(255, 110, 59, 226).withOpacity(0.4),
                      labelStyle: TextStyle(
                        color: _selectedFolderId == folder['id']
                            ? Color.fromARGB(255, 110, 59, 226)
                            : unselectedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFolderId == 'general'
                    ? 'All Bookmarks'
                    : _folders.firstWhere((f) => f['id'] == _selectedFolderId)['name'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 110, 59, 226),
                ),
              ),
              if (_selectedFolderId != 'general')
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteFolder(_selectedFolderId!),
                  tooltip: 'Delete folder',
                ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _recipes.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recipes in this folder',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: () => _loadRecipesInFolder(_selectedFolderId!),
            child: ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                final recipeId = recipe['recipeId'];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: recipe['image'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        recipe['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(Icons.fastfood, size: 50),
                    title: Text(
                      recipe['title'] ?? 'Untitled Recipe',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text('Move to folder(s)'),
                          value: 'move',
                        ),
                        PopupMenuItem(
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                          value: 'delete',
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'move') {
                          await _moveRecipeToFolders(recipe);
                        } else if (value == 'delete') {
                          await _showDeleteOptions(recipe);
                        }
                      },
                    ),
                    onTap: () {
                      final recipeId = _recipes[index]['id']; // Changed from 'recipeId' to 'id'
                      final isUserRecipe = recipeId is String;

                      if (isUserRecipe) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserRecipeDetailsPage(
                              recipeId: recipeId,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailsPage(
                              recipeId: int.tryParse(recipeId.toString()) ?? 0,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MyRecipesPageContent extends StatelessWidget {
  final List<Recipe> userRecipes;
  final VoidCallback onRecipeDeleted;
  final VoidCallback onRecipeEdited;
  const MyRecipesPageContent({
    required this.userRecipes,
    required this.onRecipeDeleted,
    required this.onRecipeEdited,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return userRecipes.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Your created recipes will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    )
        : ListView.builder(
      itemCount: userRecipes.length,
      itemBuilder: (context, index) {
        final recipe = userRecipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              recipe.title,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(recipe.description),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text('Edit'),
                  value: 'edit',
                ),
                PopupMenuItem(
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                  value: 'delete',
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRecipePage(recipe: recipe),
                    ),
                  ).then((_) => onRecipeEdited());
                } else if (value == 'delete') {
                  final confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Recipe'),
                      content: Text('Are you sure you want to delete this recipe?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ) ?? false;
                  if (confirmDelete) {
                    await RecipeFolderService().deleteUserRecipe(recipe.id);
                    onRecipeDeleted();
                  }
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserRecipeDetailsPage(
                    recipeId: recipe.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}