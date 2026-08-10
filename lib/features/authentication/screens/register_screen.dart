import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/features/authentication/screens/verify_email_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spendwise/services/category_service.dart';
import 'package:spendwise/services/social_auth_service.dart';
import 'package:spendwise/services/auth_provider_utils.dart';
import 'package:spendwise/services/currency_controller.dart';
import 'package:spendwise/services/theme_controller.dart';
import 'package:spendwise/core/shell/home_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CategoryService _categoryService = CategoryService();
  final SocialAuthService _socialAuthService = SocialAuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Exact Colors from the Login Theme
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

  @override
  void initState() {
    super.initState();
    // Replicating the 6s floating animation from login
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // --- Subtle Atmospheric Background (Same as Login) ---
          Positioned(
            top: -100,
            right: -100,
            child: BlurBlob(
              color: colorPrimaryFixed.withOpacity(0.1),
              size: 500,
              blur: 100,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: BlurBlob(
              color: colorSecondaryFixed.withOpacity(0.2),
              size: 400,
              blur: 80,
            ),
          ),

          // --- Main Content ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // Animated Logo Section
                      // Animated Logo Section
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -10 * _floatController.value),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/spendwise_logo.png',
                            height: 120,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Your Account',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start tracking your expenses today.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorOnSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Registration Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorSurfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorSurfaceContainerLow),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: !_isPasswordVisible,
                              onToggleVisibility: () {
                                setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              icon: Icons.security_outlined,
                              isPassword: true,
                              obscureText: !_isConfirmPasswordVisible,
                              onToggleVisibility: () {
                                setState(
                                  () => _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible,
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Create Account Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Create Account",
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward),
                                      ],
                                    ),
                            ),

                            // Social Divider
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                            ),

                            // Social Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSocialButton(
                                    'Google',
                                    'assets/icons/google.png',
                                    onPressed: _isGoogleLoading
                                        ? null
                                        : _signInWithGoogle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSocialButton(
                                    'Apple',
                                    'assets/icons/apple.png',
                                    onPressed: _isGoogleLoading
                                        ? null
                                        : () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Apple will return in '
                                                  'Doomsday',
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: GoogleFonts.inter(
                                    color: colorOnSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Log In",
                                    style: GoogleFonts.inter(
                                      color: colorPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            /*Text(
                              '© 2024 SpendWise Inc. All rights reserved.',
                              style: GoogleFonts.inter(fontSize: 12, color: colorOnSurfaceVariant.withOpacity(0.5)),
                            ),*/
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerUser() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'fullName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'currency': 'INR',
            'monthlyBudget': 0,
            'profileCompleted': false,
            'onboardingCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      try {
        await _categoryService.seedDefaultCategories();
      } catch (_) {
        // Seeding failure must never block or fail registration.
      }

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      // Same-email protection: registering an email that already belongs to a
      // Google-only account must guide the user to Google sign-in (same UID)
      // instead of failing with a generic message.
      if (e.code == 'email-already-in-use') {
        final email = _emailController.text.trim();
        if (email.isNotEmpty) {
          ExistingAccountKind kind = ExistingAccountKind.none;
          try {
            kind = existingAccountKind(
              await _socialAuthService.fetchSignInMethodsForEmail(email),
            );
          } catch (_) {}
          if (kind == ExistingAccountKind.googleOnly) {
            errorMessage =
                'This email is already registered with Google. Please sign in '
                'with Google below.';
          } else if (kind == ExistingAccountKind.both) {
            errorMessage =
                'An account with this email already exists. Please log in.';
          } else {
            errorMessage = 'An account with this email already exists.';
          }
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;

        case 'email-already-in-use':
          errorMessage = 'An account with this email already exists.';
          break;

        case 'weak-password':
          errorMessage = 'Password should be at least 6 characters.';
          break;

        case 'network-request-failed':
          errorMessage = 'No internet connection. Please check your network.';
          break;

        default:
          errorMessage = 'Registration failed. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final user = await _socialAuthService.signInWithGoogle();
      await _completeGoogleSignIn(user);
    } on GoogleLinkPasswordRequiredException catch (pending) {
      final password = await _promptForExistingAccountPassword(pending.email);
      if (password == null || password.isEmpty) return;

      try {
        final user = await _socialAuthService
            .linkGoogleCredentialToExistingAccount(
              pending: pending,
              password: password,
            );
        await _completeGoogleSignIn(user);
      } on SocialAuthException catch (e) {
        _showError(e.message);
      } catch (_) {
        _showError('Google Sign-In failed. Please try again.');
      }
    } on SocialAuthCancelledException {
      // User dismissed the Google sheet; treat as a quiet no-op.
    } on SocialAuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _completeGoogleSignIn(User user) async {
    // Create the Firestore profile only when it does not already exist. Never
    // overwrite an existing user document or its data.
    await _socialAuthService.ensureUserProfile(displayName: user.displayName);

    if (!mounted) return;

    // Google accounts are always email-verified, so go straight to HomeShell.
    await CurrencyController.instance.init();
    await ThemeController.instance.init();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeShell()),
    );
  }

  Future<String?> _promptForExistingAccountPassword(String email) {
    return showDialog<String>(
      context: context,
      builder: (context) => _RegisterExistingPasswordDialog(email: email),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorOnSurfaceVariant, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: colorSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorPrimaryContainer, width: 2),
        ),
        labelStyle: TextStyle(color: colorOnSurfaceVariant),
        floatingLabelStyle: TextStyle(color: colorPrimary),
      ),
    );
  }

  Widget _buildSocialButton(
    String label,
    String imagePath, {
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: colorOutlineVariant.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 20, width: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: colorOnSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown when Google sign-in hits an email that already belongs to an
/// email/password account. Collects that account's password so the Google
/// credential can be linked to the existing account (same UID).
class _RegisterExistingPasswordDialog extends StatefulWidget {
  const _RegisterExistingPasswordDialog({required this.email});

  final String email;

  @override
  State<_RegisterExistingPasswordDialog> createState() =>
      _RegisterExistingPasswordDialogState();
}

class _RegisterExistingPasswordDialogState
    extends State<_RegisterExistingPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Existing account found'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An account already exists for ${widget.email}. Enter its password '
            'to link your Google account. Your existing data will be kept.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Link Account')),
      ],
    );
  }
}
