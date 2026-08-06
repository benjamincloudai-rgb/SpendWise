import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isLoading = false;
  bool _isSuccess = false;

  final TextEditingController _emailController = TextEditingController();

  // Exact Colors from the Login/Register Theme
  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorPrimaryContainer => Theme.of(context).colorScheme.primaryContainer;
  Color get colorOnPrimary => Theme.of(context).colorScheme.onPrimary;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainerLow => Theme.of(context).colorScheme.surfaceContainerLow;
  Color get colorOnSurfaceVariant => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorPrimaryFixed => Theme.of(context).colorScheme.primaryFixed;
  Color get colorSecondaryFixed => Theme.of(context).colorScheme.secondaryFixed;
  Color get colorOutlineVariant => Theme.of(context).colorScheme.outlineVariant;

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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;

        case 'network-request-failed':
          errorMessage = 'No internet connection. Please check your network.';
          break;

        default:
          errorMessage =
              'Unable to send password reset email. Please try again.';
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
                color: colorPrimaryFixed.withOpacity(0.1), size: 500, blur: 100),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: BlurBlob(
                color: colorSecondaryFixed.withOpacity(0.2), size: 400, blur: 80),
          ),

          // --- Header Identity ---
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                  
                  ],
                ),
              ),
            ),
          ),

          // --- Main Content Canvas ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 150),
              child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The Card
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
                          child: _isSuccess ? _buildSuccessState() : _buildResetForm(),
                        ),

                        // Footer
                        const SizedBox(height: 32),
                        
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Floating Context Icon
        Center(
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -5 * _floatController.value),
                child: child,
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorSurfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_reset, color: colorPrimary, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Forgot Password',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email address to receive a password reset link.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        
        // Input Field
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          placeholder: 'name@company.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        // Reset Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimaryContainer,
            foregroundColor: colorOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Reset Password',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        
        // Back Link
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Login'),
          style: TextButton.styleFrom(
            foregroundColor: colorPrimary,
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 48),
        const SizedBox(height: 16),
        Text(
          'Email Sent',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your inbox for a link to reset your password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colorOutlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Return to Login',
              style: GoogleFonts.inter(color: colorOnSurface),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorOnSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: Icon(icon, color: colorOnSurfaceVariant, size: 20),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}