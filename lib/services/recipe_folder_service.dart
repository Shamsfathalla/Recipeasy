import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeFolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getUserFolders() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  Future<String> createFolder(String name) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .add({
      'name': name,
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> deleteFolder(String folderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // First delete all recipes in the folder
    final recipes = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .doc(folderId)
        .collection('recipes')
        .get();

    final batch = _firestore.batch();
    for (final doc in recipes.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Then delete the folder
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .doc(folderId)
        .delete();
  }

  Future<void> addRecipeToFolder({
    required String folderId,
    required int recipeId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .doc(folderId)
        .collection('recipes')
        .add({
      'recipeId': recipeId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeRecipeFromFolder({
    required String folderId,
    required String recipeDocId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .doc(folderId)
        .collection('recipes')
        .doc(recipeDocId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getRecipesInFolder(String folderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmark_folders')
        .doc(folderId)
        .collection('recipes')
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}