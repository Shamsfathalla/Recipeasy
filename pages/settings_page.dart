import 'package:flutter/material.dart';
import '/auth.dart'; // Import your Auth class
import '/pages/login_register_page.dart'; // Import the LoginPage

class SettingsPage extends StatelessWidget {
  final Auth _auth = Auth();

  SettingsPage({super.key}); // Create an instance of your Auth class

  // Function to show the sign-out confirmation dialog
  Future<void> _showSignOutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Sign Out'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to sign out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Sign Out'),
              onPressed: () async {
                await _auth.signOut(); // Sign out the user
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
                // Show a SnackBar to confirm sign out
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You have been signed out.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // Adds a back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Sign-out icon
            onPressed: () {
              _showSignOutConfirmationDialog(context); // Show sign-out confirmation dialog
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Settings Page'),
      ),
    );
  }
}