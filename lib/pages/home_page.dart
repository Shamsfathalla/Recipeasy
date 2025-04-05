import 'package:flutter/material.dart';
import 'package:recipeasy/pages/recipe_details.dart';
import 'package:recipeasy/pages/user_recipe_details_page.dart'; // Ensure this import is correct
import '/auth.dart';
import '/pages/profile_page.dart';
import '/pages/shoplist_page.dart';
import '/pages/my_recipes_page.dart';
import '/pages/settings_page.dart';
import '/pages/meal_plans_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/spoonacular_api';
import '../services/recipe_folder_service.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Auth _auth = Auth();
  int _selectedIndex = 0;
  final SpoonacularService _spoonacularService = SpoonacularService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _recipes = [];
  List<dynamic> _exploreRecipes = [];
  List<dynamic> _communityRecipes = [];
  bool _isLoading = false;
  bool _isSearching = false;
  int _exploreRecipesLimit = 5;
  int _communityRecipesLimit = 5;

  @override
  void initState() {
    super.initState();
    _fetchRandomRecipes();
    _fetchCommunityRecipes();
  }

  void _fetchRandomRecipes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final recipes = await _spoonacularService.getRandomRecipes();
      if (recipes.isEmpty) {
        print('No recipes found from the API');
      }
      setState(() {
        _exploreRecipes = recipes;
      });
    } catch (e) {
      print('Error fetching random recipes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchCommunityRecipes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('recipes').get();
      final List<dynamic> userRecipes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure each user recipe has an 'id' field
        data['source'] = 'user'; // Add a source field to identify user-created recipes
        return data;
      }).toList();
      userRecipes.shuffle(Random());
      setState(() {
        _communityRecipes = userRecipes;
      });
    } catch (e) {
      print('Error fetching community recipes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _searchController.clear();
      _recipes = [];
      _isSearching = false;
      _exploreRecipesLimit = 5;
      _communityRecipesLimit = 5;
      if (index == 0) {
        _fetchRandomRecipes();
        _fetchCommunityRecipes();
      }
    });
  }

  void _searchRecipes(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });
    try {
      final apiRecipes = await _spoonacularService.searchRecipes(query);
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('recipes')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      final List<dynamic> userRecipes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['source'] = 'user';
        return data;
      }).toList();
      setState(() {
        _recipes = [...apiRecipes, ...userRecipes];
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _recipes = [];
      _isSearching = false;
      _fetchRandomRecipes();
      _fetchCommunityRecipes();
    });
  }

  void _resetHomePage() {
    setState(() {
      _searchController.clear();
      _recipes = [];
      _isSearching = false;
      _exploreRecipesLimit = 5;
      _communityRecipesLimit = 5;
      _fetchRandomRecipes();
      _fetchCommunityRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeContent(
        searchRecipes: _searchRecipes,
        clearSearch: _clearSearch,
        recipes: _recipes,
        isLoading: _isLoading,
        searchController: _searchController,
        exploreRecipes: _exploreRecipes,
        communityRecipes: _communityRecipes,
        fetchRandomRecipes: _fetchRandomRecipes,
        fetchCommunityRecipes: _fetchCommunityRecipes,
        isSearching: _isSearching,
        exploreRecipesLimit: _exploreRecipesLimit,
        communityRecipesLimit: _communityRecipesLimit,
        setExploreRecipesLimit: (limit) => setState(() => _exploreRecipesLimit = limit),
        setCommunityRecipesLimit: (limit) => setState(() => _communityRecipesLimit = limit),
      ),
      MyRecipesPage(),
      ShopListPage(),
      MealPlansPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfilePage(user: FirebaseAuth.instance.currentUser!),
              ),
            );
            _resetHomePage();
          },
        ),
        title: const Text(
          'RecipEasy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(user: FirebaseAuth.instance.currentUser),
                ),
              );
              _resetHomePage();
            },
          ),
        ],
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
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Shop List'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Meal Plans'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(String) searchRecipes;
  final Function clearSearch;
  final Function fetchRandomRecipes;
  final Function fetchCommunityRecipes;
  final List<dynamic> recipes;
  final List<dynamic> exploreRecipes;
  final List<dynamic> communityRecipes;
  final bool isLoading;
  final TextEditingController searchController;
  final bool isSearching;
  final int exploreRecipesLimit;
  final int communityRecipesLimit;
  final Function(int) setExploreRecipesLimit;
  final Function(int) setCommunityRecipesLimit;

  const HomeContent({
    super.key,
    required this.searchRecipes,
    required this.clearSearch,
    required this.recipes,
    required this.isLoading,
    required this.searchController,
    required this.exploreRecipes,
    required this.communityRecipes,
    required this.fetchRandomRecipes,
    required this.fetchCommunityRecipes,
    required this.isSearching,
    required this.exploreRecipesLimit,
    required this.communityRecipesLimit,
    required this.setExploreRecipesLimit,
    required this.setCommunityRecipesLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for recipes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        clearSearch();
                      },
                    ),
                  ),
                  onSubmitted: (query) {
                    searchRecipes(query);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isSearching)
            Expanded(
              child: ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Explore Recipes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => fetchRandomRecipes(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (exploreRecipes.isNotEmpty)
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: min(exploreRecipes.length, exploreRecipesLimit),
                              itemBuilder: (context, index) {
                                final recipe = exploreRecipes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: recipe['image'] != null &&
                                        recipe['image'].isNotEmpty
                                        ? Image.network(
                                      recipe['image'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported);
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    )
                                        : const Icon(Icons.image_not_supported),
                                    title: Text(recipe['title'] ?? 'Untitled Recipe'),
                                    onTap: () {
                                      if (recipe['id'] != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RecipeDetailsPage(recipeId: recipe['id']),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            if (exploreRecipes.length > 5)
                              TextButton(
                                onPressed: () {
                                  setExploreRecipesLimit(exploreRecipesLimit == 5 ? 10 : 5);
                                },
                                child: Text(exploreRecipesLimit == 5 ? 'Expand' : 'Contract'),
                              ),
                          ],
                        )
                      else
                        const Center(child: Text('No recipes found')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Explore Community Recipes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => fetchCommunityRecipes(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (communityRecipes.isNotEmpty)
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: min(communityRecipes.length, communityRecipesLimit),
                              itemBuilder: (context, index) {
                                final recipe = communityRecipes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: recipe['image'] != null &&
                                        recipe['image'].isNotEmpty
                                        ? Image.network(
                                      recipe['image'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported);
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    )
                                        : const Icon(Icons.image_not_supported),
                                    title: Text(recipe['title'] ?? 'Untitled Recipe'),
                                    onTap: () {
                                      if (recipe['id'] != null) {
                                        if (recipe['source'] == 'user') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => UserRecipeDetailsPage(recipeId: recipe['id']),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RecipeDetailsPage(recipeId: recipe['id']),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            if (communityRecipes.length > 5)
                              TextButton(
                                onPressed: () {
                                  setCommunityRecipesLimit(communityRecipesLimit == 5 ? 10 : 5);
                                },
                                child: Text(communityRecipesLimit == 5 ? 'Expand' : 'Contract'),
                              ),
                          ],
                        )
                      else
                        const Center(child: Text('No community recipes found')),
                    ],
                  ),
                ],
              ),
            ),
          if (isSearching)
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : (isSearching ? recipes : []).isEmpty
                  ? const Center(child: Text('No recipes found'))
                  : ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: recipe['image'] != null &&
                          recipe['image'].isNotEmpty
                          ? Image.network(
                        recipe['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      )
                          : const Icon(Icons.image_not_supported),
                      title: Text(recipe['title'] ?? 'Untitled Recipe'),
                      onTap: () {
                        if (recipe['id'] != null) {
                          if (recipe['source'] == 'user') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserRecipeDetailsPage(recipeId: recipe['id']),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailsPage(recipeId: recipe['id']),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}