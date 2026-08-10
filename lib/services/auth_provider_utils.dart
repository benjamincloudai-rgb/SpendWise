/// Firebase Authentication provider identifiers used across the auth flows.
const String passwordProviderId = 'password';
const String googleProviderId = 'google.com';

/// Whether [providerIds] includes the email/password provider.
bool hasPasswordProvider(List<String> providerIds) =>
    providerIds.contains(passwordProviderId);

/// Whether [providerIds] includes the Google provider.
bool hasGoogleProvider(List<String> providerIds) =>
    providerIds.contains(googleProviderId);

/// The kind of existing account Firebase reports for an email address, based
/// on the sign-in providers returned by
/// `FirebaseAuth.fetchSignInMethodsForEmail`.
enum ExistingAccountKind {
  /// No account exists for the email.
  none,

  /// An email/password account exists, but Google has not been linked.
  passwordOnly,

  /// A Google-only account exists (no password set).
  googleOnly,

  /// Both email/password and Google are already linked to the account.
  both,
}

/// Classifies the providers Firebase reports for an email into the
/// [ExistingAccountKind] used to guide the user to the correct next step.
ExistingAccountKind existingAccountKind(List<String> providerIds) {
  final hasPassword = hasPasswordProvider(providerIds);
  final hasGoogle = hasGoogleProvider(providerIds);

  if (hasPassword && hasGoogle) return ExistingAccountKind.both;
  if (hasPassword) return ExistingAccountKind.passwordOnly;
  if (hasGoogle) return ExistingAccountKind.googleOnly;
  return ExistingAccountKind.none;
}
