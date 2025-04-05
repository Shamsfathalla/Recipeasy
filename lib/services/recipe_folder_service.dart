// recipe_folder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipeasy/models/recipe_model.dart';

class RecipeFolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Folder-related methods
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
    required Object recipeId, // Updated to accept both int and String
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

  // Recipe-related methods
  Future<void> createUserRecipe(Recipe recipe) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final doc = await _firestore.collection('recipes').add({
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'instructions': recipe.instructions,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the recipe ID with the generated document ID
    await _firestore.collection('recipes').doc(doc.id).update({'id': doc.id});
  }

  Future<List<Recipe>> getUserRecipes() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('recipes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Recipe.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  Future<void> updateUserRecipe(Recipe recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).update({
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'instructions': recipe.instructions,
    });
  }

  Future<void> deleteUserRecipe(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  Future<Map<String, dynamic>?> getUserRecipeDetails(String recipeId) async {
    final snapshot = await _firestore.collection('recipes').doc(recipeId).get();
    if (snapshot.exists) {
      return {
        'id': snapshot.id,
        ...snapshot.data()!,
      };
    }
    return null;
  }
}