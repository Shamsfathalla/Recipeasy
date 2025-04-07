import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_page.dart';
import 'package:recipeasy/pages/user_recipe_details_page.dart';
import 'package:recipeasy/services/analytics_service.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {
  String? username;
  int followersCount = 0;
  int followingCount = 0;
  int recipesCreatedCount = 0;
  int bookmarksAddedCount = 0;
  int recipesVisitedCount = 0;
  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (mounted) setState(() => isLoading = true);
      final userDoc = await _firestore.collection('users').doc(widget.user.uid).get();
      if (!mounted) return;
      setState(() {
        username = userDoc.data()?['username'] ?? '@${widget.user.displayName ?? 'user'}';
        followersCount = userDoc.data()?['followersCount'] ?? 0;
        followingCount = userDoc.data()?['followingCount'] ?? 0;
        recipesCreatedCount = userDoc.data()?['recipesCreatedCount'] ?? 0;
        bookmarksAddedCount = userDoc.data()?['bookmarksAddedCount'] ?? 0;
        recipesVisitedCount = userDoc.data()?['recipesVisitedCount'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _addFriend(String friendId, String friendUsername) async {
    try {
      final currentUserId = widget.user.uid;
      if (friendId == currentUserId) return;
      final followingDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(friendId)
          .get();
      if (followingDoc.exists) return;
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(currentUserId).collection('following').doc(friendId),
        {'username': friendUsername, 'timestamp': FieldValue.serverTimestamp()},
      );
      batch.set(
        _firestore.collection('users').doc(friendId).collection('followers').doc(currentUserId),
        {'username': username, 'timestamp': FieldValue.serverTimestamp()},
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
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;
      _loadUserData();
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
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;
      _loadUserData();
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
        {'followersCount': FieldValue.increment(-1)},
      );
      await batch.commit();
      if (!mounted) return;
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;
      _loadUserData();
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
          onAddFriend: _addFriend,
          currentUser: widget.user,
        ),
      ),
    ).then((_) => _loadUserData());
  }

  void _showFollowersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FriendsListScreen(
          userId: widget.user.uid,
          type: 'followers',
          onRemove: _removeFollower,
          currentUser: widget.user,
        ),
      ),
    ).then((_) => _loadUserData());
  }

  void _showAddFriendPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddFriendPage(
          currentUserId: widget.user.uid,
          currentUsername: username ?? 'user',
          onAddFriend: _addFriend,
          onUnfollow: _unfollowUser,
          currentUser: widget.user,
        ),
      ),
    ).then((_) => _loadUserData());
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
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
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            username ?? '@user',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
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
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _buildAnalyticsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics,
                    color: theme.brightness == Brightness.dark
                        ? Color.fromARGB(255, 110, 59, 226)
                        : theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'My Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnalyticItem(
                  context,
                  'Created',
                  recipesCreatedCount,
                  Icons.create_rounded,
                ),
                _buildAnalyticItem(
                  context,
                  'Bookmarked',
                  bookmarksAddedCount,
                  Icons.bookmark_rounded,
                ),
                _buildAnalyticItem(
                  context,
                  'Viewed',
                  recipesVisitedCount,
                  Icons.visibility_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(
      BuildContext context, String label, int value, IconData icon) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 110, 59, 226).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Color.fromARGB(255, 110, 59, 226) : theme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Color.fromARGB(255, 110, 59, 226) : theme.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsRow(context),
            _buildAddFriendButton(),
            _buildAnalyticsSection(context),
          ],
        ),
      ),
    );
  }
}

class _FriendsListScreen extends StatefulWidget {
  final String userId;
  final String type;
  final Function(String, String)? onUnfollow;
  final Function(String, String)? onRemove;
  final Function(String, String)? onAddFriend;
  final User currentUser;
  const _FriendsListScreen({
    required this.userId,
    required this.type,
    this.onUnfollow,
    this.onRemove,
    this.onAddFriend,
    required this.currentUser,
  });

  @override
  State<_FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<_FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> _followingStatus = {};
  List<DocumentSnapshot> _cachedFollowingList = [];
  bool _shouldRefreshOnResume = false;

  @override
  void initState() {
    super.initState();
    _loadFollowingStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldRefreshOnResume) {
      _loadFollowingStatus();
      _shouldRefreshOnResume = false;
    }
  }

  Future<void> _loadFollowingStatus() async {
    try {
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();
      final statusMap = <String, bool>{};
      for (var doc in followingSnapshot.docs) {
        statusMap[doc.id] = true;
      }
      setState(() {
        _followingStatus = statusMap;
        if (_shouldRefreshOnResume) {
          _cachedFollowingList = followingSnapshot.docs;
        }
      });
    } catch (e) {
      debugPrint('Error loading following status: $e');
    }
  }

  Future<void> _toggleFollowStatus(String userId, String username) async {
    try {
      final isFollowing = _followingStatus[userId] ?? false;
      setState(() {
        _followingStatus[userId] = !isFollowing;
      });
      if (isFollowing) {
        await widget.onUnfollow!(userId, username);
      } else {
        await widget.onAddFriend!(userId, username);
      }
    } catch (e) {
      setState(() {
        _followingStatus[userId] = !(_followingStatus[userId] ?? false);
      });
      debugPrint('Error toggling follow status: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                Color.fromRGBO(161, 63, 190, 1),
                Color.fromRGBO(120, 60, 219, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
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
                if (!_shouldRefreshOnResume) {
                  _cachedFollowingList = snapshot.data!.docs;
                }
                final filteredDocs = _cachedFollowingList.where((doc) {
                  final username = doc['username'].toString().toLowerCase();
                  return username.contains(_searchQuery.toLowerCase());
                }).toList();
                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final isFollowing = _followingStatus[doc.id] ?? true;
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
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(
                                userId: doc.id,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          ).then((_) {
                            setState(() {
                              _shouldRefreshOnResume = true;
                            });
                          });
                        },
                        trailing: widget.type == 'following'
                            ? ElevatedButton(
                          onPressed: () => _toggleFollowStatus(
                              doc.id, doc['username']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? Colors.grey
                                : const Color.fromRGBO(110, 59, 226, 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(color: Colors.white),
                          ),
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
}

class _AddFriendPage extends StatefulWidget {
  final String currentUserId;
  final String currentUsername;
  final Function(String, String) onAddFriend;
  final Function(String, String) onUnfollow;
  final User currentUser;
  const _AddFriendPage({
    required this.currentUserId,
    required this.currentUsername,
    required this.onAddFriend,
    required this.onUnfollow,
    required this.currentUser,
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
  Map<String, bool> _followingStatus = {};

  @override
  void initState() {
    super.initState();
    _loadFollowingStatus();
  }

  Future<void> _loadFollowingStatus() async {
    try {
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(widget.currentUserId)
          .collection('following')
          .get();
      final statusMap = <String, bool>{};
      for (var doc in followingSnapshot.docs) {
        statusMap[doc.id] = true;
      }
      setState(() {
        _followingStatus = statusMap;
      });
    } catch (e) {
      debugPrint('Error loading following status: $e');
    }
  }

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
      final uniqueUserIds = <String>{};
      for (var doc in querySnapshot.docs) {
        if (doc.id != widget.currentUserId) {
          uniqueUserIds.add(doc.id);
        }
      }
      final userDetails = await Future.wait(
          uniqueUserIds.map((id) => _firestore.collection('users').doc(id).get()));
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

  Future<void> _toggleFollowStatus(String userId, String username) async {
    try {
      final isFollowing = _followingStatus[userId] ?? false;
      setState(() {
        _followingStatus[userId] = !isFollowing;
      });
      if (isFollowing) {
        await widget.onUnfollow(userId, username);
      } else {
        await widget.onAddFriend(userId, username);
      }
      await _loadFollowingStatus();
    } catch (e) {
      setState(() {
        _followingStatus[userId] = !(_followingStatus[userId] ?? false);
      });
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
                Color.fromRGBO(161, 63, 190, 1),
                Color.fromRGBO(120, 60, 219, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
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
                final isFollowing = _followingStatus[user['id']] ?? false;
                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          userId: user['id'],
                          currentUser: widget.currentUser,
                        ),
                      ),
                    );
                    await _loadFollowingStatus();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                            onPressed: () => _toggleFollowStatus(
                                user['id'], user['username']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey
                                  : const Color.fromRGBO(110, 59, 226, 1),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(color: Colors.white),
                            ),
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