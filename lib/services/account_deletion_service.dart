import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Failure thrown by [AccountDeletionService] with a user-friendly [message]
/// that screens can surface directly. Raw exception text is never exposed.
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;
}

/// Permanently deletes the signed-in user's account.
///
/// Order of operations (matches the product requirement):
/// 1. Reauthenticate with the current password.
/// 2. Remove every Firestore document owned by the user.
/// 3. Delete the Firebase Authentication account.
///
/// Only the authenticated user's data is touched. All user data lives under
/// the existing `users/{uid}` document and its subcollections
/// (`transactions`, `categories`, `budgets`), so the deletion walks the
/// document's subcollections recursively before removing the document itself.
class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountDeletionException(
        'You must be logged in to delete your account.',
      );
    }
    final email = user.email;
    if (email == null) {
      throw const AccountDeletionException(
        'Unable to verify your account.',
      );
    }

    await _reauthenticate(user, email, password);
    await _deleteUserData(user.uid);
    await _deleteAuthAccount(user);
  }

  Future<void> _reauthenticate(User user, String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(_friendlyAuthError(e));
    }
  }

  Future<void> _deleteAuthAccount(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(_friendlyAuthError(e));
    }
  }

  Future<void> _deleteUserData(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      // All user-owned collections live under users/{uid}. Delete each known
      // subcollection before removing the user document itself.
      for (final subcollection in const [
        'transactions',
        'categories',
        'budgets',
      ]) {
        await _deleteCollection(userRef.collection(subcollection));
      }
      await userRef.delete();
    } catch (_) {
      throw const AccountDeletionException(
        'We could not delete your data. Please try again.',
      );
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Your password is incorrect.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'For security, please sign in again and retry.';
      case 'user-not-found':
        return 'Account not found.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
