import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search users by username prefix
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()..['id'] = doc.id)
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Save meal preferences to Firestore
  Future<void> saveMealPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('meal')
          .set(preferences, SetOptions(merge: true));

      final username = await getUsername(userId);
      if (username != null) {
        await _firestore
            .collection('username_checks')
            .doc(username.toLowerCase())
            .collection('preferences')
            .doc('meal')
            .set(preferences, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to save preferences: $e');
    }
  }

  // Get meal preferences from Firestore
  Future<Map<String, dynamic>> getMealPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('meal')
          .get();

      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to load preferences: $e');
    }
  }

  // Get username for a user
  Future<String?> getUsername(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['username'] as String?;
    } catch (e) {
      throw Exception('Failed to get username: $e');
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('username_checks')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Update user's username
  Future<void> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      final available = await isUsernameAvailable(newUsername);
      if (!available) {
        throw Exception('Username is already taken');
      }

      final currentUsername = await getUsername(userId);

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'username': newUsername.toLowerCase(),
      });

      // Update username_checks
      await _firestore
          .collection('username_checks')
          .doc(newUsername.toLowerCase())
          .set({
        'userId': userId,
        'username': newUsername.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Remove old username if it existed
      if (currentUsername != null) {
        await _firestore
            .collection('username_checks')
            .doc(currentUsername.toLowerCase())
            .delete();
      }
    } catch (e) {
      throw Exception('Failed to update username: $e');
    }
  }

  // Get current user's ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get user data by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('username_checks')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userId = query.docs.first.data()['userId'] as String;
        final userDoc = await _firestore.collection('users').doc(userId).get();
        return userDoc.data()?..['id'] = userId;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by username: $e');
    }
  }
}