import 'package:flutter/material.dart';
import 'package:recipeasy/pages/recipe_details.dart';
import 'package:recipeasy/pages/user_recipe_details_page.dart';
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
  int _currentPage = 1;
  bool _hasMoreRecipes = true;
  List<String> _userDietaryRequirements = [];
  List<String> _userAllergies = [];
  bool _includeFilters = false; // Toggle for including filters

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences(); 
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
        data['id'] = doc.id;
        data['source'] = 'user';
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
      _currentPage = 1;
      _hasMoreRecipes = true;
      if (index == 0) {
        _fetchRandomRecipes();
        _fetchCommunityRecipes();
      }
    });
  }

  Future<void> _searchRecipes(String query, {int page = 1, int? maxCookingTime}) async {
    if (query.isEmpty) return;
    setState(() {
      if (page == 1) {
        _isLoading = true;
        _hasMoreRecipes = true;
      }
      _isSearching = true;
    });
    try {
      final apiRecipes = await _spoonacularService.searchRecipes(
        query,
        page: page,
        dietaryRequirements: _includeFilters ? _userDietaryRequirements : null,
        allergies: _includeFilters ? _userAllergies : null,
        maxCookingTime: maxCookingTime, // Pass maxCookingTime to the Spoonacular API
      );

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
        if (page == 1) {
          _recipes = [...apiRecipes, ...userRecipes];
        } else {
          _recipes.addAll([...apiRecipes, ...userRecipes]);
        }
        _currentPage = page;
        _hasMoreRecipes = apiRecipes.isNotEmpty || userRecipes.isNotEmpty;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _fetchUserPreferences() async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        _userDietaryRequirements =
            List<String>.from(userDoc.data()?['dietaryRequirements'] ?? []);
        _userAllergies = List<String>.from(userDoc.data()?['allergies'] ?? []);
      });
    }
  } catch (e) {
    print('Error fetching user preferences: $e');
  }
}

  Future<void> _loadMoreRecipes() async {
    if (!_hasMoreRecipes) return;
    await _searchRecipes(_searchController.text, page: _currentPage + 1);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _recipes = [];
      _isSearching = false;
      _currentPage = 1;
      _hasMoreRecipes = true;
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
      _currentPage = 1;
      _hasMoreRecipes = true;
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
        includeFilters: _includeFilters,
        setIncludeFilters: (value) => setState(() => _includeFilters = value),
        communityRecipes: _communityRecipes,
        fetchRandomRecipes: _fetchRandomRecipes,
        fetchCommunityRecipes: _fetchCommunityRecipes,
        isSearching: _isSearching,
        exploreRecipesLimit: _exploreRecipesLimit,
        communityRecipesLimit: _communityRecipesLimit,
        setExploreRecipesLimit: (limit) => setState(() => _exploreRecipesLimit = limit),
        setCommunityRecipesLimit: (limit) => setState(() => _communityRecipesLimit = limit),
        loadMoreRecipes: _loadMoreRecipes,
        hasMoreRecipes: _hasMoreRecipes,
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
                ));
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

class HomeContent extends StatefulWidget {
  final Function(String, {int page, int? maxCookingTime}) searchRecipes; // Add maxCookingTime here
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
  final Function loadMoreRecipes;
  final bool hasMoreRecipes;
  final bool includeFilters;
  final Function(bool) setIncludeFilters;

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
    required this.loadMoreRecipes,
    required this.hasMoreRecipes,
    required this.includeFilters,
    required this.setIncludeFilters,
  });

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isRefreshingExplore = false;
  bool _isRefreshingCommunity = false;

  int _maxCookingTime = 60; // Default max cooking time in minutes

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        widget.hasMoreRecipes &&
        !_isLoadingMore &&
        widget.isSearching) {
      _loadMoreRecipes();
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (!widget.hasMoreRecipes || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final currentPosition = _scrollController.position.pixels;

    await widget.loadMoreRecipes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(currentPosition);
      setState(() {
        _isLoadingMore = false;
      });
    });
  }

  Future<void> _refreshExploreRecipes() async {
    setState(() => _isRefreshingExplore = true);
    await widget.fetchRandomRecipes();
    setState(() => _isRefreshingExplore = false);
  }

  Future<void> _refreshCommunityRecipes() async {
    setState(() => _isRefreshingCommunity = true);
    await widget.fetchCommunityRecipes();
    setState(() => _isRefreshingCommunity = false);
  }
Widget _buildSearchBar() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.searchController.clear();
                    widget.clearSearch();
                  },
                ),
              ),
              onSubmitted: (query) {
                widget.searchRecipes(query, maxCookingTime: _maxCookingTime);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Include Filters:'),
          Switch(
            value: widget.includeFilters,
            onChanged: (value) {
              widget.setIncludeFilters(value);
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Text('Max Cooking Time:'),
          Expanded(
            child: Slider(
              value: _maxCookingTime.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              label: '$_maxCookingTime min',
              onChanged: (value) {
                setState(() {
                  _maxCookingTime = value.toInt();
                });
              },
            ),
          ),
        ],
      ),
    ],
  );
}
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchBar(), // Use the reusable search bar method
          const SizedBox(height: 16),
          if (!widget.isSearching)
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
                          _isRefreshingExplore
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _refreshExploreRecipes,
                                ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (widget.exploreRecipes.isNotEmpty)
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: min(widget.exploreRecipes.length, widget.exploreRecipesLimit),
                              itemBuilder: (context, index) {
                                final recipe = widget.exploreRecipes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          recipe['image'] != null && recipe['image'].isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  child: Image.network(
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
                                                  ),
                                                )
                                              : const Icon(Icons.image_not_supported),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              recipe['title'] ?? 'Untitled Recipe',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (widget.exploreRecipes.length > 5)
                              TextButton(
                                onPressed: () {
                                  widget.setExploreRecipesLimit(widget.exploreRecipesLimit == 5 ? 10 : 5);
                                },
                                child: Text(widget.exploreRecipesLimit == 5 ? 'Show More' : 'Show Less'),
                              ),
                          ],
                        )
                      else
                        const Center(child: Text('No recipes found')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Community Recipes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          _isRefreshingCommunity
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _refreshCommunityRecipes,
                                ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (widget.communityRecipes.isNotEmpty)
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: min(widget.communityRecipes.length, widget.communityRecipesLimit),
                              itemBuilder: (context, index) {
                                final recipe = widget.communityRecipes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          recipe['image'] != null && recipe['image'].isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  child: Image.network(
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
                                                  ),
                                                )
                                              : const Icon(Icons.image_not_supported),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              recipe['title'] ?? 'Untitled Recipe',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (widget.communityRecipes.length > 5)
                              TextButton(
                                onPressed: () {
                                  widget.setCommunityRecipesLimit(widget.communityRecipesLimit == 5 ? 10 : 5);
                                },
                                child: Text(widget.communityRecipesLimit == 5 ? 'Show More' : 'Show Less'),
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
            if (widget.isSearching)
              Expanded(
                child: widget.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : widget.recipes.isEmpty
                        ? const Center(child: Text('No recipes found'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: widget.recipes.length + (widget.hasMoreRecipes ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= widget.recipes.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final recipe = widget.recipes[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(4),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        recipe['image'] != null && recipe['image'].isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  recipe['image'],
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(Icons.image_not_supported);
                                                  },
                                                ),
                                              )
                                            : const Icon(Icons.image_not_supported),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            recipe['title'] ?? 'Untitled Recipe',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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