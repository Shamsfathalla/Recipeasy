import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<String> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Validate username format first
      if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
        throw FirebaseAuthException(
          code: 'invalid-username',
          message: 'Username must be 3-20 characters (letters, numbers, _)',
        );
      }

      // Check username availability
      final usernameDoc = await _firestore.collection('usernames').doc(username).get();
      if (usernameDoc.exists) {
        throw FirebaseAuthException(
          code: 'username-exists',
          message: 'Username already taken',
        );
      }

      // Create the user (this will automatically sign them in)
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Batch write for atomic operations
      final batch = _firestore.batch();

      // Create user document with all required fields
      batch.set(_firestore.collection('users').doc(user.uid), {
        'email': email,
        'username': username,
        'followersCount': 0,
        'followingCount': 0,
        'recipesCreatedCount': 0,
        'bookmarksAddedCount': 0,
        'recipesVisitedCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reserve username
      batch.set(_firestore.collection('usernames').doc(username), {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Sign out the user immediately after account creation
      await _firebaseAuth.signOut();

      // Return success message instead of the user
      return 'Account created successfully! Please sign in to continue.';
    } on FirebaseAuthException catch (e) {
      // Re-throw Firebase auth exceptions
      if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email is already in use',
        );
      }
      rethrow;
    } catch (e) {
      // Convert other exceptions to FirebaseAuthException for consistency
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Failed to create user: ${e.toString()}',
      );
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      return false;
    }
    final snapshot = await _firestore.collection('usernames').doc(username).get();
    return !snapshot.exists;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email',
        );
      }
      if (e.code == 'invalid-email') {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email address',
        );
      }
      if (e.code == 'operation-not-allowed') {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Email/password accounts are not enabled',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}