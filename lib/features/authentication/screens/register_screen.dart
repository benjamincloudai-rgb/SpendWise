import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/features/authentication/screens/verify_email_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Exact Colors from the Login Theme
  final Color colorPrimary = const Color(0xFF006E2F);
  final Color colorPrimaryContainer = const Color(0xFF22C55E);
  final Color colorBackground = const Color(0xFFF9F9F9);
  final Color colorSurfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color colorSurfaceContainerLow = const Color(0xFFF3F3F3);
  final Color colorOnSurfaceVariant = const Color(0xFF3D4A3D);
  final Color colorOnSurface = const Color(0xFF1A1C1C);
  final Color colorPrimaryFixed = const Color(0xFF6BFF8F);
  final Color colorSecondaryFixed = const Color(0xFFDAE2FD);
  final Color colorOutlineVariant = const Color(0xFFBCCBB9);

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
            child: _BlurBlob(color: colorPrimaryFixed.withOpacity(0.1), size: 500, blur: 100),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _BlurBlob(color: colorSecondaryFixed.withOpacity(0.2), size: 400, blur: 80),
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
                                setState(() => _isPasswordVisible = !_isPasswordVisible);
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
                                setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                              },
                            ),
                            const SizedBox(height: 32),

                            // Create Account Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                            ),

                            // Social Buttons
                            Row(
                              children: [
                                Expanded(child: _buildSocialButton('Google', 'assets/icons/google.png',)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildSocialButton('Apple', 'assets/icons/apple.png',)),
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
                                Text("Already have an account?", style: GoogleFonts.inter(color: colorOnSurfaceVariant)),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },  
                                  child: Text(
                                    "Log In",
                                    style: GoogleFonts.inter(color: colorPrimary, fontWeight: FontWeight.bold),
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

      // Send verification email
      await userCredential.user!.sendEmailVerification();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

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
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, size: 20),
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

  Widget _buildSocialButton(String label, String imagePath) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: colorOutlineVariant.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: colorOnSurface, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const _BlurBlob({required this.color, required this.size, required this.blur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }
}