import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Function to clear all notifications (UI-only for now)
  void _clearNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // Adds a back button
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
                _clearNotifications(context); // Clear all notifications
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Profile Page'),
      ),
    );
  }
}