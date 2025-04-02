import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/theme_provider.dart';
import '../pages/login_register_page.dart';
import 'meal_details.dart';
import '/services/firestore_services.dart';

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
            fontWeight: FontWeight.bold,
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
    _buildSettingsOption(
        context, Icons.lock, 'Change Password', () => _changePassword(context)),
    _buildSettingsOption(context, Icons.person_outline, 'Change Username',
            () => _changeUsername(context)),
    _buildSettingsOption(
        context, Icons.delete, 'Delete Account', () => _deleteAccount(context)),
  ]);

  Widget _buildPreferencesSection(BuildContext context) => _buildCard([
    ListTile(
      leading:
      const Icon(Icons.settings, color: Color.fromRGBO(110, 59, 226, 1)),
      title: Text(
        'Preferences',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
    _buildSettingsOption(context, Icons.restaurant_menu, 'Meal Plan Preferences',
            () => _openMealPlanPreferences(context)),
    _buildSettingsOption(
        context, Icons.notifications, 'Notification Settings', () {}),
    _buildThemeToggleOption(context),
    _buildSettingsOption(context, Icons.shopping_basket,
        'Shopping List Preferences', () {}),
  ]);

  Widget _buildSupportSection(BuildContext context) => _buildCard([
    ListTile(
      leading: const Icon(Icons.help, color: Color.fromRGBO(110, 59, 226, 1)),
      title: Text(
        'Support',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
    _buildSettingsOption(context, Icons.help_center, 'Help & FAQ', () {}),
    _buildSettingsOption(
        context, Icons.description, 'Terms of Service', () {}),
    _buildSettingsOption(context, Icons.security, 'Privacy Policy', () {}),
  ]);

  Widget _buildSignOutButton(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
            );
          }
        },
      ),
    ),
  );

  Widget _buildCard(List<Widget> children) => Card(
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(children: children),
  );

  Widget _buildTile(
      BuildContext context, IconData icon, String title, String subtitle) =>
      ListTile(
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

  Widget _buildSettingsOption(
      BuildContext context, IconData icon, String title, Function() onTap) =>
      ListTile(
        leading: Icon(icon, color: const Color.fromRGBO(110, 59, 226, 0.7)),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      );

  Widget _buildThemeToggleOption(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          secondary:
          const Icon(Icons.palette, color: Color.fromRGBO(110, 59, 226, 0.7)),
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

  Future<void> _changePassword(BuildContext context) async {
    final result = await _showPasswordChangeDialog(context);
    if (result != null) {
      final oldPassword = result['oldPassword'];
      final newPassword = result['newPassword'];
      final confirmPassword = result['confirmPassword'];
      if (newPassword != null &&
          confirmPassword != null &&
          newPassword == confirmPassword) {
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
          const SnackBar(
              content: Text('Passwords do not match. Please try again.')),
        );
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Step 1: Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Step 2: Reauthenticate
      final password = await _showInputDialog(
        context,
        'Confirm Deletion',
        'Enter your password to confirm',
        isPassword: true,
      );
      if (password == null) return;

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user!.reauthenticateWithCredential(credential);

      // Step 3: Show loading
      final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Deleting account...'),
            ],
          ),
          duration: Duration(minutes: 5), // Prevents auto-hide
        ),
      );

      // Step 4: Fetch all data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!userDoc.exists) throw Exception('User document not found');
      final username = userDoc.data()?['username'];

      // Fetch all subcollections in parallel
      final [postsSnapshot, followersSnapshot, followingSnapshot] = await Future.wait([
        FirebaseFirestore.instance.collection('users/${user!.uid}/posts').get(),
        FirebaseFirestore.instance.collection('users/${user!.uid}/followers').get(),
        FirebaseFirestore.instance.collection('users/${user!.uid}/following').get(),
      ]);

      // Step 5: Batch delete everything
      final batch = FirebaseFirestore.instance.batch();

      // Delete all posts
      for (final doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all followers
      for (final doc in followersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all following
      for (final doc in followingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete username reference (if exists)
      if (username != null && username.isNotEmpty) {
        batch.delete(FirebaseFirestore.instance.collection('usernames').doc(username));
      }

      // Finally, delete the user document
      batch.delete(FirebaseFirestore.instance.collection('users').doc(user!.uid));

      // Commit the batch (atomic operation)
      await batch.commit();

      // Step 6: Delete Firebase Auth account
      await user!.delete();

      // Step 7: Navigate to login
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      String message = 'Deletion failed: ${e.message}';
      if (e.code == 'requires-recent-login') {
        message = 'Please sign in again before deleting';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _changeUsername(BuildContext context) async {
    if (user == null) return;

    // Get current username
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final currentUsername = userDoc.data()?['username'] ?? '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UsernameChangeDialog(currentUsername: currentUsername),
    );

    if (result == null || !result['valid']) return;

    final newUsername = result['username'] as String;
    final password = result['password'] as String;

    try {
      // Reauthenticate user before making changes
      final credential = EmailAuthProvider.credential(
          email: user!.email!, password: password);
      await user!.reauthenticateWithCredential(credential);

      // Show loading indicator
      final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Updating username...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Create a batch to perform atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Delete old username reference if it exists
      if (currentUsername.isNotEmpty) {
        batch.delete(FirebaseFirestore.instance
            .collection('usernames')
            .doc(currentUsername));
      }

      // Add new username reference
      batch.set(
          FirebaseFirestore.instance.collection('usernames').doc(newUsername),
          {'uid': user!.uid, 'updatedAt': FieldValue.serverTimestamp()});

      // Update user document with new username
      batch.update(
          FirebaseFirestore.instance.collection('users').doc(user!.uid),
          {
            'username': newUsername,
            'updatedAt': FieldValue.serverTimestamp()
          });

      // Commit all operations
      await batch.commit();

      // Hide loading indicator and show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username: ${e.toString()}')),
      );
    }
  }

  Future<void> _openMealPlanPreferences(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to set preferences')),
      );
      return;
    }

    try {
      // Show loading indicator
      final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Loading your preferences...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Load preferences from Firestore
      final prefs = await FirestoreServices().getMealPreferences(user!.uid);

      // Dismiss loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MealDetailsPage(
            initialPreferences: prefs.isNotEmpty
                ? prefs
                : {
              'timeFrame': 'day',
              'diet': 'None',
              'targetCalories': 2000,
              'minProtein': 50,
              'minCarbs': 130,
              'minFat': 30,
              'include': '',
              'exclude': '',
            },
            onSave: (preferences) async {
              try {
                // Show saving indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Saving preferences...'),
                      ],
                    ),
                  ),
                );

                await FirestoreServices().saveMealPreferences(
                  userId: user!.uid,
                  preferences: preferences,
                );

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferences saved successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save: ${e.toString()}'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            userId: user!.uid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load preferences: ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<Map<String, String>?> _showPasswordChangeDialog(
      BuildContext context) async {
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter new password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Confirm new password',
                border: OutlineInputBorder(),
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
              if (oldPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
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
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (confirmHint != null)
              TextField(
                obscureText: isPassword,
                decoration: InputDecoration(
                  hintText: confirmHint,
                  border: const OutlineInputBorder(),
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

class UsernameChangeDialog extends StatefulWidget {
  final String currentUsername;
  const UsernameChangeDialog({super.key, required this.currentUsername});

  @override
  _UsernameChangeDialogState createState() => _UsernameChangeDialogState();
}

class _UsernameChangeDialogState extends State<UsernameChangeDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isChecking = false;
  bool _isAvailable = false;
  bool _isValid = false;
  bool _isSameAsCurrent = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_checkUsername);
    _passwordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {});
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();

    // Check if empty
    if (username.isEmpty) {
      setState(() {
        _isAvailable = false;
        _isValid = false;
        _isSameAsCurrent = false;
      });
      return;
    }

    // Check if same as current
    final isSame = username == widget.currentUsername;
    setState(() {
      _isSameAsCurrent = isSame;
    });

    if (isSame) {
      setState(() {
        _isAvailable = false;
        _isValid = false;
      });
      return;
    }

    // Validate format
    final isValid = RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
    setState(() {
      _isValid = isValid;
    });

    if (!isValid) return;

    setState(() {
      _isChecking = true;
    });

    // Check availability
    final snapshot = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(username)
        .get();

    setState(() {
      _isAvailable = !snapshot.exists;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _isAvailable &&
        _passwordController.text.isNotEmpty &&
        !_isSameAsCurrent;

    return AlertDialog(
      title: const Text('Change Username'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current username: ${widget.currentUsername}'),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'New Username',
                hintText: 'Enter new username',
                border: const OutlineInputBorder(),
                suffixIcon: _isChecking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : null,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            if (_usernameController.text.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSameAsCurrent)
                    Text(
                      'Please enter a different username',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    )
                  else if (!_isValid)
                    Text(
                      'Must be 3-20 characters (letters, numbers, _)',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    )
                  else if (_isAvailable)
                      Text(
                        'Username available',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        'Username taken',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                ],
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isFormValid
              ? () => Navigator.pop(context, {
            'username': _usernameController.text.trim(),
            'password': _passwordController.text.trim(),
            'valid': true
          })
              : null,
          child: const Text('Update'),
        ),
      ],
    );
  }
}