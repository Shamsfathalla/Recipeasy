import 'package:flutter/material.dart';
import '/auth.dart'; // Import your Auth class
// Import the LoginPage
import '/pages/profile_page.dart'; // Import ProfilePage
import '/pages/shoplist_page.dart'; // Import ShopListPage
import '/pages/create_page.dart'; // Import CreatePage
import '/pages/my_recipes_page.dart'; // Import MyRecipesPage
import '/pages/more_page.dart'; // Import MorePage
import '/pages/settings_page.dart'; // Import SettingsPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Auth _auth = Auth(); // Create an instance of your Auth class
  int _selectedIndex = 0; // Index of the selected bottom navigation bar item

  // List of pages/screens corresponding to the bottom navigation bar items
  final List<Widget> _pages = [
    HomeContent(), // Home Page
    CreatePage(), // Create Page
    MyRecipesPage(), // My Recipes Page
    ShopListPage(), // Shop List Page
    MorePage(), // More Page
  ];

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to clear all notifications (UI-only for now)
  void _clearNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Removed the title
        leading: IconButton(
          icon: const Icon(Icons.person), // Profile icon in the top-left
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
        actions: [
          // Notifications dropdown menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.notifications), // Notifications icon
            itemBuilder: (BuildContext context) {
              return [
                // Header for notifications
                const PopupMenuItem<String>(
                  value: 'header',
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Empty state message
                const PopupMenuItem<String>(
                  value: 'empty',
                  child: Text('No new notifications.'),
                ),
                // Divider and Clear All button
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red),
                      ),
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
            icon: const Icon(Icons.settings), // Settings icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Current selected index
        onTap: _onItemTapped, // Handle item taps
        type: BottomNavigationBarType.fixed, // Fixed type for more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// Placeholder for the Home Page content
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Search bar in the center of the home page
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}