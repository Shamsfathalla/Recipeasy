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

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
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

    // Create the user
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user?.uid;
    if (uid == null) throw Exception('User creation failed');

    // Batch write for atomic operations
    final batch = _firestore.batch();

    // Create user document
    batch.set(_firestore.collection('users').doc(uid), {
      'email': email,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Reserve username
    batch.set(_firestore.collection('usernames').doc(username), {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // REMOVED THE SIGN OUT CALL - THIS WAS CAUSING THE ISSUE
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
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}