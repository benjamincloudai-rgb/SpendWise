/// Maps a Firebase Authentication error [code] to a user-friendly message that
/// can be shown directly in the UI. Raw exception text is never surfaced.
///
/// Kept as a pure function so it can be unit tested without any platform
/// dependency.
String friendlyAuthErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
      return 'Incorrect email or password.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password should be at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled. Please contact support.';
    case 'requires-recent-login':
      return 'For security, please sign in again and retry.';
    case 'provider-already-linked':
      return 'This sign-in method is already linked to your account.';
    case 'provider-linked-to-other-user':
      return 'This credential is already linked to a different account.';
    case 'credential-already-in-use':
      return 'This credential is already linked to another account.';
    case 'invalid-action-code':
      return 'This link is invalid or has expired.';
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
      return 'Sign-in was cancelled.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
