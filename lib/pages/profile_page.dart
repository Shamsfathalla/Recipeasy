import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  int followersCount = 0;
  int followingCount = 0;
  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        username = userDoc.data()?['username'] ?? '@${widget.user.displayName ?? 'user'}';
        followersCount = userDoc.data()?['followersCount'] ?? 0;
        followingCount = userDoc.data()?['followingCount'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorSnackbar('Error loading profile: ${e.toString()}');
    }
  }

  Future<void> _addFriend(String friendId, String friendUsername) async {
    try {
      final currentUserId = widget.user.uid;

      if (friendId == currentUserId) {
        _showErrorSnackbar('You cannot follow yourself');
        return;
      }

      final followingDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(friendId)
          .get();

      if (followingDoc.exists) {
        _showErrorSnackbar('You already follow $friendUsername');
        return;
      }

      final batch = _firestore.batch();

      batch.set(
        _firestore.collection('users').doc(currentUserId).collection('following').doc(friendId),
        {
          'username': friendUsername,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        _firestore.collection('users').doc(friendId).collection('followers').doc(currentUserId),
        {
          'username': username,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {'followingCount': FieldValue.increment(1)},
      );

      batch.update(
        _firestore.collection('users').doc(friendId),
        {'followersCount': FieldValue.increment(1)},
      );

      await batch.commit();

      if (!mounted) return;
      setState(() => followingCount++);
      _showSuccessSnackbar('You are now following $friendUsername');
    } catch (e) {
      _showErrorSnackbar('Error following user: ${e.toString()}');
    }
  }

  Future<void> _unfollowUser(String userId, String friendUsername) async {
    try {
      final currentUserId = widget.user.uid;
      final batch = _firestore.batch();

      batch.delete(
        _firestore.collection('users').doc(currentUserId).collection('following').doc(userId),
      );

      batch.delete(
        _firestore.collection('users').doc(userId).collection('followers').doc(currentUserId),
      );

      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {'followingCount': FieldValue.increment(-1)},
      );

      batch.update(
        _firestore.collection('users').doc(userId),
        {'followersCount': FieldValue.increment(-1)},
      );

      await batch.commit();

      if (!mounted) return;
      setState(() => followingCount--);
      _showSuccessSnackbar('You unfollowed $friendUsername');
    } catch (e) {
      _showErrorSnackbar('Error unfollowing user: ${e.toString()}');
    }
  }

  Future<void> _removeFollower(String userId, String followerUsername) async {
    try {
      final currentUserId = widget.user.uid;
      final batch = _firestore.batch();

      batch.delete(
        _firestore.collection('users').doc(currentUserId).collection('followers').doc(userId),
      );

      batch.delete(
        _firestore.collection('users').doc(userId).collection('following').doc(currentUserId),
      );

      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {'followersCount': FieldValue.increment(-1)},
      );

      batch.update(
        _firestore.collection('users').doc(userId),
        {'followingCount': FieldValue.increment(-1)},
      );

      await batch.commit();

      if (!mounted) return;
      setState(() => followersCount--);
      _showSuccessSnackbar('Removed $followerUsername from followers');
    } catch (e) {
      _showErrorSnackbar('Error removing follower: ${e.toString()}');
    }
  }

  void _showFollowingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FriendsListScreen(
          userId: widget.user.uid,
          type: 'following',
          onUnfollow: _unfollowUser,
        ),
      ),
    );
  }

  void _showFollowersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FriendsListScreen(
          userId: widget.user.uid,
          type: 'followers',
          onRemove: _removeFollower,
        ),
      ),
    );
  }

  void _showAddFriendPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddFriendPage(
          currentUserId: widget.user.uid,
          currentUsername: username ?? 'user',
          onAddFriend: _addFriend,
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsRow(context),
            _buildAddFriendButton(),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
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
          const SizedBox(height: 16),
          Text(
            username ?? '@user',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(followersCount.toString(), 'Followers', _showFollowersList),
          _buildStatItem(followingCount.toString(), 'Following', _showFollowingList),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(110, 59, 226, 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Friend', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: _showAddFriendPage,
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group,
                  size: 50,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your friends\' activity will appear here',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsListScreen extends StatefulWidget {
  final String userId;
  final String type;
  final Function(String, String)? onUnfollow;
  final Function(String, String)? onRemove;

  const _FriendsListScreen({
    required this.userId,
    required this.type,
    this.onUnfollow,
    this.onRemove,
  });

  @override
  State<_FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<_FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'following' ? 'Following' : 'Followers',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search ${widget.type}',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.userId)
                  .collection(widget.type)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${widget.type} found',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final username = doc['username'].toString().toLowerCase();
                  return username.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color.fromRGBO(110, 59, 226, 1),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          doc['username'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: widget.type == 'following'
                            ? IconButton(
                          icon: const Icon(Icons.person_remove,
                              color: Colors.red),
                          onPressed: () {
                            widget.onUnfollow?.call(doc.id, doc['username']);
                          },
                        )
                            : widget.onRemove != null
                            ? IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            widget.onRemove?.call(
                                doc.id, doc['username']);
                          },
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AddFriendPage extends StatefulWidget {
  final String currentUserId;
  final String currentUsername;
  final Function(String, String) onAddFriend;

  const _AddFriendPage({
    required this.currentUserId,
    required this.currentUsername,
    required this.onAddFriend,
  });

  @override
  State<_AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<_AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _errorMessage = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _errorMessage = '';
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      // Use a set to ensure unique users by ID
      final uniqueUserIds = <String>{};
      for (var doc in querySnapshot.docs) {
        if (doc.id != widget.currentUserId) {
          uniqueUserIds.add(doc.id);
        }
      }
      // Fetch user details for unique IDs
      final userDetails = await Future.wait(uniqueUserIds.map((id) => _firestore.collection('users').doc(id).get()));
      setState(() {
        _searchResults = userDetails.map((doc) => {
          'id': doc.id,
          'username': doc['username'],
        }).toList();
        _isSearching = false;
        if (_searchResults.isEmpty) {
          _errorMessage = 'No users found with "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching users: ${e.toString()}';
      });
      debugPrint('Error searching users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Friend',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults.clear();
                      _errorMessage = '';
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) => _searchUsers(value),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return InkWell(
                  onTap: () {
                    // TODO: Implement profile viewing
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Viewing ${user['username']}\'s profile'),
                        backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color.fromRGBO(110, 59, 226, 1),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              user['username'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              widget.onAddFriend(user['id'], user['username']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(110, 59, 226, 1),
                            ),
                            child: const Text('Follow',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}