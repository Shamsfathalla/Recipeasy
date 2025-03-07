import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';

class SettingsPage extends StatelessWidget {
  final User? user;

  const SettingsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAccountSection(),
            _buildPreferencesSection(),
            _buildSupportSection(),
            _buildSignOutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.deepOrange),
            title: const Text('Account Settings'),
            subtitle: Text(user?.email ?? 'No email associated'),
          ),
          const Divider(height: 1),
          _buildSettingsOption(Icons.email, 'Change Email'),
          _buildSettingsOption(Icons.lock, 'Change Password'),
          _buildSettingsOption(Icons.delete, 'Delete Account'),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.settings, color: Colors.deepOrange),
            title: Text('Preferences'),
          ),
          _buildSettingsOption(Icons.notifications, 'Notification Settings'),
          _buildSettingsOption(Icons.palette, 'App Theme'),
          _buildSettingsOption(Icons.shopping_basket, 'Shopping List Preferences'),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.help, color: Colors.deepOrange),
            title: Text('Support'),
          ),
          _buildSettingsOption(Icons.help_center, 'Help & FAQ'),
          _buildSettingsOption(Icons.description, 'Terms of Service'),
          _buildSettingsOption(Icons.security, 'Privacy Policy'),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange.withOpacity(0.7)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Add functionality for each setting
        debugPrint('$title tapped');
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Auth().signOut();
          },
        ),
      ),
    );
  }
}