import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth.dart'; // Import your Auth class
import '/pages/profile_page.dart';
import '/pages/shoplist_page.dart';
import '/pages/create_page.dart';
import '/pages/my_recipes_page.dart';
import '/theme_provider.dart';
import 'package:provider/provider.dart';
import '../pages/login_register_page.dart';

class HomePage extends StatefulWidget {
  final User? user;

  const HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Auth _auth = Auth();
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    CreatePage(),
    MyRecipesPage(),
    ShopListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _clearNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.person,
            color: Colors.white,
          ),
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
            ),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'header',
                  child: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                _clearNotifications(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color.fromRGBO(110, 59, 226, 1)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create, color: Color.fromRGBO(110, 59, 226, 1)),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book, color: Color.fromRGBO(110, 59, 226, 1)),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.shopping_cart,
              color: Color.fromRGBO(110, 59, 226, 1),
            ),
            label: 'Shop List',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.more_horiz,
              color: Color.fromRGBO(110, 59, 226, 1),
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
    );
  }
}

class SettingsPage extends StatelessWidget {
  final User? user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAccountSection(context),
            _buildPreferencesSection(context),
            _buildSupportSection(context),
            _buildSignOutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) => _buildCard([
    _buildTile(
      context,
      Icons.person,
      'Account Settings',
      user?.email ?? 'No email associated',
    ),
    _buildSettingsOption(context, Icons.email, 'Change Email', () => _changeEmail(context)),
    _buildSettingsOption(context, Icons.lock, 'Change Password', () => _changePassword(context)),
    _buildSettingsOption(context, Icons.delete, 'Delete Account', () => _deleteAccount(context)),
  ]);

  Widget _buildPreferencesSection(BuildContext context) => _buildCard([
    ListTile(
      leading: const Icon(Icons.settings, color: Color.fromRGBO(110, 59, 226, 1)),
      title: Text(
        'Preferences',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
    _buildSettingsOption(context, Icons.notifications, 'Notification Settings', () {}),
    _buildThemeToggleOption(context),
    _buildSettingsOption(context, Icons.shopping_basket, 'Shopping List Preferences', () {}),
  ]);

  Widget _buildThemeToggleOption(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.palette, color: Color.fromRGBO(110, 59, 226, 0.7)),
          title: Text(
            'Dark Mode',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme(value);
          },
        );
      },
    );
  }

  Widget _buildSupportSection(BuildContext context) => _buildCard([
    ListTile(
      leading: const Icon(Icons.help, color: Color.fromRGBO(110, 59, 226, 1)),
      title: Text(
        'Support',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
    _buildSettingsOption(context, Icons.help_center, 'Help & FAQ', () {}),
    _buildSettingsOption(context, Icons.description, 'Terms of Service', () {}),
    _buildSettingsOption(context, Icons.security, 'Privacy Policy', () {}),
  ]);

  Widget _buildSignOutButton(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Sign Out'),
        onPressed: () async {
          final confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await FirebaseAuth.instance.signOut(); // ✅ Ensure Firebase Auth signs out

            // ✅ Instead of navigating manually, let StreamBuilder detect the auth change
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false, // Clear all previous routes
            );
          }
        }
    )
    );

  Widget _buildCard(List<Widget> children) => Card(
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(children: children),
  );

  Widget _buildTile(BuildContext context, IconData icon, String title, String subtitle) => ListTile(
    leading: Icon(icon, color: const Color.fromRGBO(110, 59, 226, 1)),
    title: Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    subtitle: Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );

  Widget _buildSettingsOption(BuildContext context, IconData icon, String title, Function() onTap) => ListTile(
    leading: Icon(icon, color: const Color.fromRGBO(110, 59, 226, 0.7)),
    title: Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
  );

  // ... (keep all the remaining methods unchanged)
  Future<void> _changeEmail(BuildContext context) async {
    final newEmail = await _showInputDialog(
      context,
      'Change Email',
      'Enter new email',
      confirmHint: 'Confirm new email',
    );
    if (newEmail != null && newEmail.isNotEmpty) {
      final confirmEmail = await _showInputDialog(
        context,
        'Confirm Email',
        'Re-enter new email',
      );
      if (confirmEmail != null && confirmEmail == newEmail) {
        try {
          await user?.updateEmail(newEmail);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email updated successfully!')),
          );
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'An error occurred. Please try again.';
          if (e.code == 'email-already-in-use') {
            errorMessage = 'The email address is already in use by another account.';
          } else if (e.code == 'requires-recent-login') {
            errorMessage = 'Please re-authenticate to change your email.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emails do not match. Please try again.')),
        );
      }
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final result = await _showPasswordChangeDialog(context);
    if (result != null) {
      final oldPassword = result['oldPassword'];
      final newPassword = result['newPassword'];
      final confirmPassword = result['confirmPassword'];

      if (newPassword != null && confirmPassword != null && newPassword == confirmPassword) {
        // Re-authenticate the user
        try {
          final credential = EmailAuthProvider.credential(
            email: user?.email ?? '',
            password: oldPassword ?? '',
          );
          await user?.reauthenticateWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incorrect old password: ${e.message}')),
          );
          return;
        }

        try {
          await user?.updatePassword(newPassword);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!')),
          );
        } on FirebaseAuthException catch (e) {
          String errorMessage = 'An error occurred. Please try again.';
          if (e.code == 'weak-password') {
            errorMessage = 'The password is too weak.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await user?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully!')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.message}')),
        );
      }
    }
  }

  Future<Map<String, String>?> _showPasswordChangeDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter old password',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter new password',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () {
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields.')),
                );
                return;
              }

              Navigator.pop(context, {
                'oldPassword': oldPassword,
                'newPassword': newPassword,
                'confirmPassword': confirmPassword,
              });
            },
            child: Text(
              'Submit',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showInputDialog(
      BuildContext context,
      String title,
      String hint, {
        String? confirmHint,
        bool isPassword = false,
      }) async {
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              obscureText: isPassword,
              decoration: InputDecoration(hintText: hint),
            ),
            if (confirmHint != null)
              TextField(
                obscureText: isPassword,
                decoration: InputDecoration(hintText: confirmHint),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(
              'Submit',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}