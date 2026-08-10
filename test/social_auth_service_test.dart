import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/services/auth_error_messages.dart';
import 'package:spendwise/services/auth_provider_utils.dart';

void main() {
  group('hasPasswordProvider', () {
    test('returns true when password provider is present', () {
      expect(hasPasswordProvider(['password']), isTrue);
      expect(hasPasswordProvider(['google.com', 'password']), isTrue);
    });

    test('returns false when password provider is absent', () {
      expect(hasPasswordProvider([]), isFalse);
      expect(hasPasswordProvider(['google.com']), isFalse);
      expect(hasPasswordProvider(['phone']), isFalse);
    });
  });

  group('hasGoogleProvider', () {
    test('returns true when google provider is present', () {
      expect(hasGoogleProvider(['google.com']), isTrue);
      expect(hasGoogleProvider(['password', 'google.com']), isTrue);
    });

    test('returns false when google provider is absent', () {
      expect(hasGoogleProvider([]), isFalse);
      expect(hasGoogleProvider(['password']), isFalse);
    });
  });

  group('existingAccountKind', () {
    test('none when no providers are reported', () {
      expect(existingAccountKind([]), ExistingAccountKind.none);
    });

    test('passwordOnly when only email/password exists', () {
      expect(
        existingAccountKind(['password']),
        ExistingAccountKind.passwordOnly,
      );
    });

    test('googleOnly when only google exists', () {
      expect(
        existingAccountKind(['google.com']),
        ExistingAccountKind.googleOnly,
      );
    });

    test('both when password and google are linked', () {
      expect(
        existingAccountKind(['google.com', 'password']),
        ExistingAccountKind.both,
      );
      expect(
        existingAccountKind(['password', 'google.com']),
        ExistingAccountKind.both,
      );
    });

    test('ignores unknown providers when classifying', () {
      expect(
        existingAccountKind(['phone', 'google.com']),
        ExistingAccountKind.googleOnly,
      );
      expect(
        existingAccountKind(['phone', 'password']),
        ExistingAccountKind.passwordOnly,
      );
    });
  });

  group('friendlyAuthErrorMessage', () {
    test('maps known credential failure codes', () {
      expect(
        friendlyAuthErrorMessage('invalid-credential'),
        'Incorrect email or password.',
      );
      expect(
        friendlyAuthErrorMessage('wrong-password'),
        'Incorrect email or password.',
      );
    });

    test('maps account exists codes', () {
      expect(
        friendlyAuthErrorMessage('email-already-in-use'),
        'An account with this email already exists.',
      );
    });

    test('maps recent login requirement', () {
      expect(
        friendlyAuthErrorMessage('requires-recent-login'),
        'For security, please sign in again and retry.',
      );
    });

    test('maps network failure', () {
      expect(
        friendlyAuthErrorMessage('network-request-failed'),
        'No internet connection. Please check your network.',
      );
    });

    test('maps weak password', () {
      expect(
        friendlyAuthErrorMessage('weak-password'),
        'Password should be at least 6 characters.',
      );
    });

    test('falls back to a generic message for unknown codes', () {
      expect(
        friendlyAuthErrorMessage('some-unknown-code'),
        'Something went wrong. Please try again.',
      );
    });
  });
}
