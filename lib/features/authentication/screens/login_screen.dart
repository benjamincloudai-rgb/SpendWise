import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/features/authentication/screens/register_screen.dart';
import 'package:spendwise/features/authentication/screens/forgot_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/features/authentication/screens/dashboard_screen.dart';
import 'package:spendwise/features/authentication/screens/verify_email_screen.dart';
import 'package:spendwise/core/shell/home_shell.dart';
import 'package:spendwise/services/currency_controller.dart';
import 'package:spendwise/services/theme_controller.dart';
import 'package:spendwise/services/social_auth_service.dart';
import 'package:spendwise/services/auth_provider_utils.dart';

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final SocialAuthService _socialAuthService = SocialAuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Colors from the Tailwind Config
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

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
        );

        return;
      }

      print("Login Successful!");
      if (!mounted) return;

      await CurrencyController.instance.init();
      await ThemeController.instance.init();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeShell()),
      );
    } on FirebaseAuthException catch (e) {
      // Reverse-account protection: an email/password attempt against an email
      // that belongs to a Google-only account must not silently fail. Detect it
      // and guide the user to sign in with Google (same Firebase UID).
      if (e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        final email = _emailController.text.trim();
        if (email.isNotEmpty) {
          ExistingAccountKind kind = ExistingAccountKind.none;
          try {
            kind = existingAccountKind(
              await _socialAuthService.fetchSignInMethodsForEmail(email),
            );
          } catch (_) {}
          if (kind == ExistingAccountKind.googleOnly) {
            _showError(
              'This email is linked to a Google account. Please sign in with '
              'Google below.',
            );
            return;
          }
        }
      }

      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;

        case 'invalid-credential':
          errorMessage = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;

        case 'wrong-password':
          errorMessage = 'Incorrect email or password.';
          break;

        case 'network-request-failed':
          errorMessage = 'No internet connection. Please check your network.';
          break;

        default:
          errorMessage = 'Login failed. Please try again.';
      }

      _showError(errorMessage);
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
      // An email/password account already exists for this email. Ask for its
      // password and link the Google credential to that same account instead
      // of creating a duplicate.
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

    if (user.emailVerified) {
      if (!mounted) return;

      await CurrencyController.instance.init();
      await ThemeController.instance.init();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeShell()),
      );
    } else {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
      );
    }
  }

  Future<String?> _promptForExistingAccountPassword(String email) {
    return showDialog<String>(
      context: context,
      builder: (context) => _ExistingAccountPasswordDialog(email: email),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  /*Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }*/

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // --- Subtle Atmospheric Background ---
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
                //physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                    maxWidth: 440,
                  ),
                  child: Column(
                    children: [
                      // Logo Section
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.06),
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
                            height: screenHeight * 0.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome back',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your credentials to access your dashboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorOnSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Login Card
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.07),
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
                            // Email Field
                            _buildTextField(
                              label: 'Email Address',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                            ),
                            const SizedBox(height: 24),

                            // Password Field
                            _buildTextField(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              isPassword: true,
                              obscureText: !_isPasswordVisible,
                              onToggleVisibility: () {
                                setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                );
                              },
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    color: colorPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Sign In Button
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isLoading
                                    ? const Color(0xFF005321)
                                    : colorPrimaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      'Sign In',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ],
                              ),
                            ),

                            // Divider
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.035,
                              ),
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
                      // Footer
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.inter(
                                color: colorOnSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign Up",
                                style: GoogleFonts.inter(
                                  color: colorPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorOnSurfaceVariant),
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
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
class _ExistingAccountPasswordDialog extends StatefulWidget {
  const _ExistingAccountPasswordDialog({required this.email});

  final String email;

  @override
  State<_ExistingAccountPasswordDialog> createState() =>
      _ExistingAccountPasswordDialogState();
}

class _ExistingAccountPasswordDialogState
    extends State<_ExistingAccountPasswordDialog> {
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
