// analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> incrementRecipesCreated() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'recipesCreatedCount': FieldValue.increment(1),
    });
  }

  Future<void> incrementBookmarksAdded() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'bookmarksAddedCount': FieldValue.increment(1),
    });
  }

  Future<void> incrementRecipesVisited() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'recipesVisitedCount': FieldValue.increment(1),
    });
  }

  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return {
      'recipesCreated': doc.data()?['recipesCreatedCount'] ?? 0,
      'bookmarksAdded': doc.data()?['bookmarksAddedCount'] ?? 0,
      'recipesVisited': doc.data()?['recipesVisitedCount'] ?? 0,
    };
  }
}