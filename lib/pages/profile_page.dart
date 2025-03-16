import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart'; // Import Auth class
import '/pages/settings_page.dart'; // Import SettingsPage

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  // Function to clear all notifications (UI-only for now)
  void _clearNotifications(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All notifications cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // Adds a back button
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ), // White title text
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
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
        actions: [
          // Notifications dropdown menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ), // White icon for contrast
            itemBuilder: (BuildContext context) {
              return [
                // Header for notifications
                const PopupMenuItem<String>(
                  value: 'header',
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      Text('Clear All', style: TextStyle(color: Colors.red)),
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
          // Settings icon button
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ), // White icon for contrast
            onPressed: () {
              // Navigate to SettingsPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(user: user),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Set background color to white
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildStatsRow(),
              _buildFriendsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white, // White background for the header
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color.fromRGBO(
              110,
              59,
              226,
              1,
            ), // Avatar background color
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white, // Icon color
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user.displayName ?? 'User Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Black text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email ?? 'No email provided',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87, // Darker black text color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Friends', '136'), // Friends stat
          _buildStatCard('Following', '56'), // Following stat
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(110, 59, 226, 1), // Text color
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Friends',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Black text color
            ),
          ),
          const SizedBox(height: 10),
          _buildFriendList(),
          const SizedBox(height: 10),
          _buildAddFriendButton(),
        ],
      ),
    );
  }

  Widget _buildFriendList() {
    // Replace with your actual list of friends
    final List<String> friends = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve'];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color.fromRGBO(110, 59, 226, 1), // Icon color
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              friends[index],
              style: const TextStyle(color: Colors.black),
            ), // Black text color
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                // Add functionality to remove friend
                _removeFriend(friends[index]);
              },
            ),
            onTap: () {
              // Add functionality to view friend's profile
              _viewFriendProfile(friends[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAddFriendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Friend', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(
            110,
            59,
            226,
            1,
          ), // Button color
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Add functionality to add a friend
          _addFriend();
        },
      ),
    );
  }

  void _addFriend() {
    // Implement logic to add a friend
    print('Add Friend');
  }

  void _removeFriend(String friendName) {
    // Implement logic to remove a friend
    print('Removed $friendName');
  }

  void _viewFriendProfile(String friendName) {
    // Implement logic to view friend's profile
    print('View $friendName\'s profile');
  }
}
