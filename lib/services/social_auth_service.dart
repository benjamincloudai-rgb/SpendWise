import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    as auth_platform;
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_error_messages.dart';
import 'category_service.dart';

/// Thrown when the user cancels the Google sign-in sheet (or it is interrupted
/// for a reason that is not a failure). Screens should treat this as a no-op.
class SocialAuthCancelledException implements Exception {
  const SocialAuthCancelledException();
}

/// Thrown by [SocialAuthService] with a user-friendly [message] that screens
/// can surface directly. Raw exception text is never exposed.
class SocialAuthException implements Exception {
  const SocialAuthException(this.message, {this.code});

  final String message;

  /// Optional original error code, useful for diagnostics.
  final String? code;
}

/// Thrown when Google sign-in hits `account-exists-with-different-credential`:
/// an email/password account already exists for the same email. The pending
/// Google credential and email are carried so the UI can ask for the existing
/// account password and link the Google credential to that same UID.
class GoogleLinkPasswordRequiredException implements Exception {
  const GoogleLinkPasswordRequiredException({
    required this.email,
    required this.pendingCredential,
  });

  final String email;
  final AuthCredential pendingCredential;
}

/// Google (OAuth) authentication built on `google_sign_in` v7 and Firebase
/// Authentication, including same-email account linking.
///
/// Responsibilities:
/// * Sign in with Google via `initialize()` -> `authenticate()` and exchange
///   the resulting ID token for a Firebase credential.
/// * Detect user cancellation through the package's exception-based API
///   ([GoogleSignInException]) and surface it as [SocialAuthCancelledException]
///   so screens can ignore it quietly.
/// * Prevent duplicate accounts: when Google sign-in targets an email that
///   already belongs to an email/password account, link the Google credential
///   to that existing account (same UID) instead of creating a second one.
/// * Bootstrap a Firestore `users/{uid}` document for brand-new Google users
///   without ever overwriting existing user data.
class SocialAuthService {
  SocialAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static bool _googleSignInInitialized = false;

  /// Signs the user in with Google and returns the authenticated Firebase
  /// [User].
  ///
  /// If the email already belongs to an email/password account, throws
  /// [GoogleLinkPasswordRequiredException] so the caller can collect the
  /// existing password and call
  /// [linkGoogleCredentialToExistingAccount] to link providers on the same
  /// UID. User cancellation throws [SocialAuthCancelledException].
  Future<User> signInWithGoogle() async {
    final credential = await _googleAuthentication();

    try {
      final userCredential = await _auth.signInWithCredential(
        credential.credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const SocialAuthException('Sign-in failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final email = e.email;
        if (email == null) {
          throw const SocialAuthException(
            'An account already exists with this email. Please sign in with '
            'your existing method.',
          );
        }
        throw GoogleLinkPasswordRequiredException(
          email: email,
          pendingCredential: e.credential ?? credential.credential,
        );
      }
      throw SocialAuthException(friendlyAuthErrorMessage(e.code), code: e.code);
    }
  }

  /// Re-authenticates the current user with Google.
  ///
  /// Used to satisfy Firebase's `requires-recent-login` requirement (e.g. when
  /// setting a password on a Google-only account). The selected Google account
  /// must match the signed-in user's email; a mismatch throws
  /// [SocialAuthException] instead of crossing credentials.
  Future<AuthCredential> reauthenticateWithGoogle() async {
    final googleAuth = await _googleAuthentication();

    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const SocialAuthException('You must be logged in to continue.');
    }

    if (googleAuth.email.toLowerCase() != user.email!.toLowerCase()) {
      throw const SocialAuthException(
        'Please choose the same Google account that is signed in.',
      );
    }

    return googleAuth.credential;
  }

  /// Completes the account-linking flow started by a
  /// [GoogleLinkPasswordRequiredException].
  ///
  /// Signs in with the existing email/password credentials (which authenticates
  /// the original account and keeps its UID), then links the pending Google
  /// credential to that same account. All Firestore data stays attached to the
  /// original UID.
  Future<User> linkGoogleCredentialToExistingAccount({
    required GoogleLinkPasswordRequiredException pending,
    required String password,
  }) async {
    final emailCredential = EmailAuthProvider.credential(
      email: pending.email,
      password: password,
    );

    try {
      final result = await _auth.signInWithCredential(emailCredential);
      final user = result.user;
      if (user == null) {
        throw const SocialAuthException('Sign-in failed. Please try again.');
      }
      await user.linkWithCredential(pending.pendingCredential);
      return user;
    } on FirebaseAuthException catch (e) {
      throw SocialAuthException(friendlyAuthErrorMessage(e.code), code: e.code);
    }
  }

  /// Fetches the sign-in providers Firebase knows for [email] (e.g. `password`,
  /// `google.com`). Empty when no account exists.
  ///
  /// `firebase_auth` does not expose this on its app-facing [FirebaseAuth]
  /// class, so it is read through the platform interface.
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      return await auth_platform.FirebaseAuthPlatform.instance
          .fetchSignInMethodsForEmail(email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email' || e.code == 'user-not-found') {
        return const [];
      }
      throw SocialAuthException(friendlyAuthErrorMessage(e.code), code: e.code);
    }
  }

  /// Ensures a Firestore `users/{uid}` document exists for the currently signed
  /// in user, creating it with the same shape the email/password registration
  /// flow uses.
  ///
  /// This is a no-op when the document already exists, so existing user data
  /// (transactions, categories, budgets, profile, settings) is never
  /// overwritten or duplicated.
  Future<void> ensureUserProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (snapshot.exists) return;

    await userRef.set({
      'fullName': (displayName == null || displayName.trim().isEmpty)
          ? 'User'
          : displayName.trim(),
      'email': user.email ?? '',
      'currency': 'INR',
      'monthlyBudget': 0,
      'profileCompleted': false,
      'onboardingCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Seeding failures must never block a successful Google sign-in.
    try {
      await CategoryService().seedDefaultCategories();
    } catch (_) {}
  }

  Future<_GoogleAuthData> _googleAuthentication() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // The v7 API reports cancellation as an exception; treat it as a quiet
      // no-op instead of an error message.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const SocialAuthCancelledException();
      }
      throw SocialAuthException(
        _googleSignInErrorMessage(e.code),
        code: e.code.name,
      );
    }

    return _GoogleAuthData(
      email: account.email,
      credential: GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      ),
    );
  }

  String _googleSignInErrorMessage(GoogleSignInExceptionCode code) {
    switch (code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In is not configured for this app. Please contact '
            'support.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In is not available right now. Please try again.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'The selected Google account does not match this account. '
            'Please use the same account.';
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.unknownError:
        return 'Google Sign-In failed. Please try again.';
    }
  }
}

/// Google account email plus the Firebase [AuthCredential] derived from its ID
/// token.
class _GoogleAuthData {
  const _GoogleAuthData({required this.email, required this.credential});

  final String email;
  final AuthCredential credential;
}
