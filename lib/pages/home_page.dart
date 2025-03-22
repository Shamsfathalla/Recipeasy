import 'package:flutter/material.dart';
import '/auth.dart';
import '/pages/profile_page.dart';
import '/pages/shoplist_page.dart';
import '/pages/create_page.dart';
import '/pages/my_recipes_page.dart';
import '/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Spoonacular_APi';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Auth _auth = Auth();
  int _selectedIndex = 0;

  final SpoonacularService _spoonacularService = SpoonacularService(); // Ensure this matches the class name
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _recipes = [];
  List<dynamic> _exploreRecipes = [];
  bool _isLoading = false;
  bool _isSearching = false; // New state to track if the user is searching

  @override
  void initState() {
    super.initState();
    _fetchRandomRecipes();
  }

  void _fetchRandomRecipes() async {
    setState(() {
      _isLoading = true;
    });

    final recipes = await _spoonacularService.getRandomRecipes();
    setState(() {
      _exploreRecipes = recipes;
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _searchController.clear();
      _recipes = [];
      _isSearching = false; // Reset search state when switching pages
      _fetchRandomRecipes(); // Reset to explore recipes when switching pages
    });
  }

  void _searchRecipes(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _isSearching = true; // Set search state to true
    });

    try {
      final recipes = await _spoonacularService.searchRecipes(query);
      setState(() {
        _recipes = recipes;
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
      _isSearching = false; // Reset search state
      _fetchRandomRecipes(); // Reset to explore recipes
    });
  }

  void _clearNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared.')),
    );
  }

  // Reset the home page to default state
  void _resetHomePage() {
    setState(() {
      _searchController.clear();
      _recipes = [];
      _isSearching = false;
      _fetchRandomRecipes(); // Fetch random recipes again
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeContent(
        searchRecipes: _searchRecipes,
        recipes: _recipes,
        isLoading: _isLoading,
        searchController: _searchController,
        clearSearch: _clearSearch,
        exploreRecipes: _exploreRecipes,
        fetchRandomRecipes: _fetchRandomRecipes,
        isSearching: _isSearching, // Pass the search state
      ),
      CreatePage(),
      MyRecipesPage(),
      ShopListPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () async {
            // Navigate to profile page and reset home page when returning
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfilePage(user: FirebaseAuth.instance.currentUser!),
              ),
            );
            _resetHomePage(); // Reset home page when returning
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.notifications, color: Colors.white),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'header',
                child: Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'empty',
                child: Text('No new notifications.'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: const [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'clear') {
                _clearNotifications();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              // Navigate to settings page and reset home page when returning
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(user: FirebaseAuth.instance.currentUser),
                ),
              );
              _resetHomePage(); // Reset home page when returning
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
          BottomNavigationBarItem(icon: Icon(Icons.create), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shop List'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(String) searchRecipes;
  final Function clearSearch;
  final Function fetchRandomRecipes;
  final List<dynamic> recipes;
  final List<dynamic> exploreRecipes;
  final bool isLoading;
  final TextEditingController searchController;
  final bool isSearching; // New parameter to track search state

  const HomeContent({
    super.key,
    required this.searchRecipes,
    required this.clearSearch,
    required this.recipes,
    required this.isLoading,
    required this.searchController,
    required this.exploreRecipes,
    required this.fetchRandomRecipes,
    required this.isSearching, // Add this parameter
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
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => searchRecipes(searchController.text),
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => clearSearch(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isSearching) // Only show "Explore Recipes" section when not searching
            Column(
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
              ],
            ),
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : recipes.isEmpty
                ? ListView.builder(
              itemCount: exploreRecipes.length,
              itemBuilder: (context, index) {
                final recipe = exploreRecipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(recipe['title']),
                    subtitle: Text('ID: ${recipe['id']}'),
                  ),
                );
              },
            )
                : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(recipe['title']),
                    subtitle: Text('ID: ${recipe['id']}'),
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