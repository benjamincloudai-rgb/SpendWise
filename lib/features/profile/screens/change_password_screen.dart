import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/services/auth_provider_utils.dart';
import 'package:spendwise/services/social_auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SocialAuthService _socialAuthService = SocialAuthService();

  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;
  bool _isSaving = false;

  // True when the signed-in account has an email/password credential. False
  // for Google-only accounts, which instead get the "Set Password" flow.
  late bool _hasPasswordProvider;

  // Strict colors matching the SpendWise design system
  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorPrimaryContainer =>
      Theme.of(context).colorScheme.primaryContainer;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainerLow =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  Color get colorOnSurfaceVariant =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorPrimaryFixed => Theme.of(context).colorScheme.primaryFixed;
  Color get colorSecondaryFixed => Theme.of(context).colorScheme.secondaryFixed;
  Color get colorOutlineVariant => Theme.of(context).colorScheme.outlineVariant;

  // Secondary and Error colors matching specs
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorTertiary => Theme.of(context).colorScheme.tertiary;
  Color get colorError => Theme.of(context).colorScheme.error;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    final providerIds =
        user?.providerData.map((provider) => provider.providerId).toList() ??
        const <String>[];
    _hasPasswordProvider = hasPasswordProvider(providerIds);
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to change your password.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_hasPasswordProvider) {
        // Existing email/password account: re-authenticate with the current
        // password before updating it (unchanged behavior).
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newController.text);
        _showSuccess('Password updated successfully');
      } else {
        // Google-only account: add an email/password credential to the SAME
        // Firebase UID. All Firestore data stays intact.
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _newController.text,
        );
        try {
          await user.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // Re-authenticate with Google before retrying the link.
            final googleCredential = await _socialAuthService
                .reauthenticateWithGoogle();
            await user.reauthenticateWithCredential(googleCredential);
            await user.linkWithCredential(credential);
          } else {
            rethrow;
          }
        }
        _showSuccess('Password set successfully');
      }
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } on SocialAuthCancelledException {
      // User dismissed the Google re-auth sheet; keep them on the screen.
    } on SocialAuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    // Never cache passwords: clear controllers after success.
    _currentController.clear();
    _newController.clear();
    _confirmController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please sign in again and try again.';
      case 'provider-already-linked':
        return 'This account already has a password. Please use Change Password instead.';
      default:
        return 'Unable to change password. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with other screens) ---
            Positioned(
              top: -100,
              right: -100,
              child: BlurBlob(
                color: colorPrimaryFixed.withValues(alpha: 0.1),
                size: 500,
                blur: 100,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: BlurBlob(
                color: colorSecondaryFixed.withValues(alpha: 0.2),
                size: 400,
                blur: 80,
              ),
            ),

            // --- Scrollable Form Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 76, // Clears top sticky App Bar
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          EntranceAnimation(
                            delayMs: 100,
                            child: _buildFormCard(),
                          ),
                          const SizedBox(height: 24),
                          EntranceAnimation(
                            delayMs: 180,
                            child: _buildSaveButton(),
                          ),
                          const SizedBox(height: 16),
                          EntranceAnimation(
                            delayMs: 240,
                            child: _buildHelperText(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- Sticky Top App Bar ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EntranceAnimation(
                delayMs: 50,
                child: _buildHeader(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Component (Sticky Top App Bar)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: colorBackground.withValues(alpha: 0.95),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorOnSurface, size: 28),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              Text(
                _hasPasswordProvider ? 'Change Password' : 'Set Password',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorSecondary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Form card with the password fields
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorSurfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google-only accounts have no existing password to verify, so the
          // "Current Password" field is only shown for email/password users.
          if (_hasPasswordProvider) ...[
            Text(
              'Current Password',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _currentController,
              icon: Icons.lock_outline,
              hintText: 'Enter your current password...',
              obscureText: !_isCurrentVisible,
              onToggleVisibility: () {
                setState(() {
                  _isCurrentVisible = !_isCurrentVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
          Text(
            _hasPasswordProvider ? 'New Password' : 'New Password',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _newController,
            icon: Icons.lock_reset,
            hintText: 'Enter a new password...',
            obscureText: !_isNewVisible,
            onToggleVisibility: () {
              setState(() {
                _isNewVisible = !_isNewVisible;
              });
            },
            validator: (value) {
              final password = value ?? '';
              if (password.isEmpty) {
                return 'Please enter a new password.';
              }
              if (password.length < 8) {
                return 'Password must be at least 8 characters.';
              }
              if (password.length > 64) {
                return 'Password must be 64 characters or less.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Confirm Password',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _confirmController,
            icon: Icons.verified_user_outlined,
            hintText: 'Confirm your new password...',
            obscureText: !_isConfirmVisible,
            onToggleVisibility: () {
              setState(() {
                _isConfirmVisible = !_isConfirmVisible;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your new password.';
              }
              if (value != _newController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: colorTertiary, fontSize: 14),
        prefixIcon: Icon(icon, color: colorOnSurfaceVariant, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            size: 20,
            color: colorOnSurfaceVariant,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: colorSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorError, width: 2),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: colorOnSurface),
    );
  }

  // Save button with loading state
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _savePassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 1,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              _hasPasswordProvider ? 'Change Password' : 'Set Password',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildHelperText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        _hasPasswordProvider
            ? 'Use at least 8 characters. Avoid using the same password as other accounts.'
            : 'Your account was created with Google. Set a password to also '
                  'sign in with your email. Your existing data is kept.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 12, color: colorSecondary),
      ),
    );
  }
}
