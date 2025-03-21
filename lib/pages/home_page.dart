import 'package:flutter/material.dart';
import '/auth.dart'; // Import your Auth class
// Import the LoginPage
import '/pages/profile_page.dart'; // Import ProfilePage
import '/pages/shoplist_page.dart'; // Import ShopListPage
import '/pages/create_page.dart'; // Import CreatePage
import '/pages/my_recipes_page.dart'; // Import MyRecipesPage
import '/pages/settings_page.dart'; // Import SettingsPage
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth instance
import '../services/Spoonacular_APi';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Auth _auth = Auth(); // Create an instance of your Auth class
  int _selectedIndex = 0; // Index of the selected bottom navigation bar item

  final SpoonacularService _spoonacularService = SpoonacularService(); // Instance of SpoonacularService
  final TextEditingController _searchController = TextEditingController(); // Controller for search input
  List<dynamic> _recipes = []; // List to store search results
  bool _isLoading = false; // Loading state

  // List of pages/screens corresponding to the bottom navigation bar items
  final List<Widget> _pages = [
    HomeContent(), // Home Page
    CreatePage(), // Create Page
    MyRecipesPage(), // My Recipes Page
    ShopListPage(), // Shop List Page
  ];

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void _searchRecipes() async {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        final recipes = await _spoonacularService.searchRecipes(_searchController.text);
        setState(() {
          _recipes = recipes; // Update the recipes list with results
        });
      } catch (e) {
        print('Error: $e'); // Handle errors
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }

  // Function to clear all notifications (UI-only for now)
  void _clearNotifications() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All notifications cleared.')));
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.person,
            color: Colors.white,
          ), // Profile icon in the top-left
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfilePage(user: FirebaseAuth.instance.currentUser!),
              ),
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ), // Notifications icon
            itemBuilder: (BuildContext context) {
              return [
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
              ];
            },
            onSelected: (String value) {
              if (value == 'clear') {
                _clearNotifications(); // Clear all notifications
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ), // Settings icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(user: FirebaseAuth.instance.currentUser),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(168, 64, 185, 1), // RGB 168, 64, 185
                Color.fromRGBO(110, 59, 226, 1), // RGB 110, 59, 226
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: HomeContent(
        searchRecipes: _searchRecipes,
        recipes: _recipes,
        isLoading: _isLoading,
      ), // Pass data to HomeContent
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Current selected index
        onTap: _onItemTapped, // Handle item taps
        type: BottomNavigationBarType.fixed, // Fixed type for more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.create), label: 'Create'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop List',
          ),
        ],
      ),
    );
  }
}

// Updated HomeContent widget
class HomeContent extends StatelessWidget {
  final Function(String) searchRecipes;
  final List<dynamic> recipes;
  final bool isLoading;

  const HomeContent({
    super.key,
    required this.searchRecipes,
    required this.recipes,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _searchController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for recipes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  searchRecipes(_searchController.text); // Trigger search
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          isLoading
              ? const CircularProgressIndicator()
              : Expanded(
                  child: ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return ListTile(
                        title: Text(recipe['title']),
                        subtitle: Text('ID: ${recipe['id']}'),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}