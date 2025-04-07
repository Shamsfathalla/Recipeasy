import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipeasy/pages/user_recipe_details_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final User currentUser;

  const UserProfilePage({required this.userId, required this.currentUser});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? username;
  int followersCount = 0;
  int followingCount = 0;
  bool isLoading = true;
  bool isFollowing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfFollowing();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (!mounted) return;
      setState(() {
        username = userDoc.data()?['username'] ?? '@${userDoc.data()?['displayName'] ?? 'user'}';
        followersCount = userDoc.data()?['followersCount'] ?? 0;
        followingCount = userDoc.data()?['followingCount'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    if (widget.currentUser.uid == widget.userId) {
      setState(() => isFollowing = false);
      return;
    }

    try {
      final followingDoc = await _firestore
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('following')
          .doc(widget.userId)
          .get();
      if (!mounted) return;
      setState(() {
        isFollowing = followingDoc.exists;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isFollowing = false);
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollowStatus() async {
    if (widget.currentUser.uid == widget.userId) return;

    try {
      final currentUserId = widget.currentUser.uid;
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final currentUsername = currentUserDoc.data()?['username'] ??
          widget.currentUser.displayName ??
          widget.currentUser.email?.split('@').first ??
          'user';

      final targetUserDoc = await _firestore.collection('users').doc(widget.userId).get();
      final targetUsername = targetUserDoc.data()?['username'] ??
          targetUserDoc.data()?['displayName'] ??
          'user';

      final batch = _firestore.batch();

      if (isFollowing) {
        batch.delete(
          _firestore.collection('users').doc(currentUserId).collection('following').doc(widget.userId),
        );
        batch.delete(
          _firestore.collection('users').doc(widget.userId).collection('followers').doc(currentUserId),
        );
      } else {
        batch.set(
          _firestore.collection('users').doc(currentUserId).collection('following').doc(widget.userId),
          {
            'username': targetUsername,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
        batch.set(
          _firestore.collection('users').doc(widget.userId).collection('followers').doc(currentUserId),
          {
            'username': currentUsername,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }

      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {'followingCount': FieldValue.increment(isFollowing ? -1 : 1)},
      );
      batch.update(
        _firestore.collection('users').doc(widget.userId),
        {'followersCount': FieldValue.increment(isFollowing ? -1 : 1)},
      );

      await batch.commit();
      if (!mounted) return;

      setState(() {
        isFollowing = !isFollowing;
      });

      await Future.wait([
        _loadUserData(),
        _checkIfFollowing(),
      ]);
    } catch (e) {
      debugPrint('Error toggling follow status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showFollowersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListPage(
          userId: widget.userId,
          currentUser: widget.currentUser,
          isFollowersList: true,
        ),
      ),
    );
  }

  void _showFollowingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListPage(
          userId: widget.userId,
          currentUser: widget.currentUser,
          isFollowersList: false,
        ),
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
        iconTheme: const IconThemeData(color: Colors.white),
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsRow(context),
            if (widget.currentUser.uid != widget.userId) _buildFollowButton(),
            _buildCreatedRecipes(context),
          ],
        ),
      ),
    );
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
            backgroundColor: Color.fromRGBO(120, 60, 219, 1),
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
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
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
              color: Color.fromRGBO(120, 60, 219, 1),
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

  Widget _buildFollowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton.icon(
        icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add, color: Colors.white),
        label: Text(isFollowing ? 'Unfollow' : 'Follow', style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(120, 60, 219, 1),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: _toggleFollowStatus,
      ),
    );
  }

  Widget _buildCreatedRecipes(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Created Recipes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('recipes').where('userId', isEqualTo: widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No recipes found',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromRGBO(120, 60, 219, 1),
                        child: Icon(Icons.book, color: Colors.white),
                      ),
                      title: Text(
                        doc['title'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserRecipeDetailsPage(recipeId: doc.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class FollowListPage extends StatefulWidget {
  final String userId;
  final User currentUser;
  final bool isFollowersList;

  const FollowListPage({
    required this.userId,
    required this.currentUser,
    required this.isFollowersList,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        return user['username'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadUsers() async {
    try {
      final collectionPath = widget.isFollowersList
          ? 'users/${widget.userId}/followers'
          : 'users/${widget.userId}/following';

      final querySnapshot = await _firestore.collection(collectionPath).get();

      final usersData = await Future.wait(
        querySnapshot.docs.map((doc) async {
          String username = doc.data()['username'] ?? '';
          if (username.isEmpty) {
            final userDoc = await _firestore.collection('users').doc(doc.id).get();
            username = userDoc.data()?['username'] ??
                userDoc.data()?['displayName'] ??
                widget.currentUser.uid == doc.id
                ? (widget.currentUser.displayName ?? widget.currentUser.email?.split('@').first ?? 'You')
                : 'User';
          }

          return {
            'id': doc.id,
            'username': username,
            'isFollowing': await _checkIfFollowing(doc.id),
          };
        }),
      );

      if (mounted) {
        setState(() {
          users = usersData;
          filteredUsers = usersData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint('Error loading users: $e');
    }
  }

  Future<bool> _checkIfFollowing(String targetUserId) async {
    if (widget.currentUser.uid == targetUserId) return false;

    final doc = await _firestore
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('following')
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  Future<void> _toggleFollowStatus(String targetUserId, String username) async {
    if (widget.currentUser.uid == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't follow yourself")),
      );
      return;
    }

    try {
      final isFollowing = users.firstWhere((u) => u['id'] == targetUserId)['isFollowing'];
      final batch = _firestore.batch();

      if (isFollowing) {
        batch.delete(
          _firestore.collection('users').doc(widget.currentUser.uid)
              .collection('following').doc(targetUserId),
        );
        batch.delete(
          _firestore.collection('users').doc(targetUserId)
              .collection('followers').doc(widget.currentUser.uid),
        );
      } else {
        batch.set(
          _firestore.collection('users').doc(widget.currentUser.uid)
              .collection('following').doc(targetUserId),
          {
            'username': username,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
        batch.set(
          _firestore.collection('users').doc(targetUserId)
              .collection('followers').doc(widget.currentUser.uid),
          {
            'username': widget.currentUser.displayName ??
                widget.currentUser.email?.split('@').first ??
                'user',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
      }

      batch.update(
        _firestore.collection('users').doc(widget.currentUser.uid),
        {'followingCount': FieldValue.increment(isFollowing ? -1 : 1)},
      );
      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {'followersCount': FieldValue.increment(isFollowing ? -1 : 1)},
      );

      await batch.commit();

      if (mounted) {
        setState(() {
          final userIndex = users.indexWhere((u) => u['id'] == targetUserId);
          if (userIndex != -1) {
            users[userIndex]['isFollowing'] = !isFollowing;
          }
          _filterUsers();
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow status: $e');
    }
  }

  void _viewUserProfile(String userId) {
    if (userId == widget.currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're already viewing your own profile")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFollowersList ? 'Followers' : 'Following',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${widget.isFollowersList ? 'followers' : 'following'}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color.fromRGBO(120, 60, 219, 1),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    user['username'],
                    style: TextStyle(
                      fontWeight: user['id'] == widget.currentUser.uid
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: user['id'] == widget.currentUser.uid
                          ? isDarkMode ? Colors.white : Colors.black
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  trailing: widget.currentUser.uid != user['id']
                      ? IconButton(
                    icon: Icon(
                      user['isFollowing'] ? Icons.person_remove : Icons.person_add,
                      color: const Color.fromRGBO(120, 60, 219, 1),
                    ),
                    onPressed: () => _toggleFollowStatus(user['id'], user['username']),
                  )
                      : null,
                  onTap: () => _viewUserProfile(user['id']),
                  enabled: widget.currentUser.uid != user['id'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}