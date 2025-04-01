import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';
import '/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (mounted) {
        setState(() {
          if (doc.exists) {
            username = doc.data()?['username'] ?? '@${widget.user.displayName ?? 'user'}';
          } else {
            username = '@${widget.user.displayName ?? 'user'}';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          username = '@${widget.user.displayName ?? 'user'}';
          isLoading = false;
          errorMessage = 'Could not load username';
        });
      }
      debugPrint('Error loading username: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
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
        actions: [
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
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red[400],
                    ),
                  ),
                ),
              _buildProfileHeader(context),
              _buildStatsRow(context),
              _buildFriendsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(25),
      color: theme.cardColor,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color.fromRGBO(110, 59, 226, 1),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            username ?? '@user',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(context, 'Followers', '136', isDarkMode),
          _buildStatCard(context, 'Following', '56', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, bool isDarkMode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color.fromRGBO(110, 59, 226, 1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Friends',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _buildFriendList(context, isDarkMode),
          const SizedBox(height: 10),
          _buildAddFriendButton(),
        ],
      ),
    );
  }

  Widget _buildFriendList(BuildContext context, bool isDarkMode) {
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
              backgroundColor: Color.fromRGBO(110, 59, 226, 1),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              friends[index],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeFriend(friends[index]),
            ),
            onTap: () => _viewFriendProfile(friends[index]),
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
          backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _addFriend,
      ),
    );
  }

  void _addFriend() {
    debugPrint('Add Friend');
    // Implement add friend functionality
  }

  void _removeFriend(String friendName) {
    debugPrint('Removed $friendName');
    // Implement remove friend functionality
  }

  void _viewFriendProfile(String friendName) {
    debugPrint('View $friendName\'s profile');
    // Implement view friend profile functionality
  }
}