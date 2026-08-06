import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/core/shell/home_shell.dart';
import 'package:spendwise/services/currency_controller.dart';
import 'package:spendwise/features/authentication/screens/login_screen.dart';
import 'dart:async';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  Timer? _verificationTimer;
  Timer? _cooldownTimer;
  bool _isLoading = false;
  bool _isResending = false;
  int _cooldownSeconds = 60;

  // Exact Colors from the Login/Register/Forgot Password Theme
  final Color colorPrimary = AppColors.primary;
  final Color colorPrimaryContainer = AppColors.primaryContainer;
  final Color colorBackground = AppColors.background;
  final Color colorSurfaceContainerLowest = AppColors.surfaceContainerLowest;
  final Color colorSurfaceContainerLow = AppColors.surfaceContainerLow;
  final Color colorOnSurfaceVariant = AppColors.onSurfaceVariant;
  final Color colorOnSurface = AppColors.onSurface;
  final Color colorPrimaryFixed = AppColors.primaryFixed;
  final Color colorSecondaryFixed = AppColors.secondaryFixed;
  final Color colorOutlineVariant = AppColors.outlineVariant;

  @override
  void initState() {
    super.initState();
    // 6s Floating animation matching registration and login screens
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Automatic email verification check
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        timer.cancel();
        return;
      }

      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        timer.cancel();
        _cooldownTimer?.cancel();

        if (!mounted) return;

        await CurrencyController.instance.init();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    });

    // Start 60-second cooldown when the screen opens
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = 60;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        if (!mounted) return;

        await CurrencyController.instance.init();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeShell()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email is not verified yet. Please check your inbox.",
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'network-request-failed':
          errorMessage = 'No internet connection. Please check your network.';
          break;

        case 'too-many-requests':
          errorMessage =
              'Too many attempts. Please wait a moment and try again.';
          break;

        default:
          errorMessage = 'Unable to verify your email. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification email resent successfully!"),
        ),
      );

      // Restart the 60-second countdown upon successful dispatch
      _startCooldown();
    } on FirebaseAuthException catch (e) {

        String errorMessage;

        switch (e.code) {
          case 'network-request-failed':
            errorMessage =
                'No internet connection. Please check your network.';
            break;

          case 'too-many-requests':
            errorMessage =
                "You've requested too many emails. Please wait before trying again.";
            break;

          default:
            errorMessage =
                'Unable to resend the verification email.';
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );

      } catch (_) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Something went wrong. Please try again.',
            ),
          ),
        );
      }
  }

  Future<void> _useAnotherEmail() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "";

    final bool isResendDisabled = _isResending || _cooldownSeconds > 0;

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // --- Subtle Atmospheric Background (Same as Login/Register) ---
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // Animated Logo Section
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.04),
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

                      // Heading
                      Text(
                        'Verify your email',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        "We've sent a verification link to your email address. Please verify your email before continuing.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorOnSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorPrimaryContainer.withOpacity(0.1),
                          border: Border.all(
                            color: colorPrimaryContainer.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          userEmail,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Verification Card
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
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorSurfaceContainerLow,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mail_outline,
                                color: colorPrimary,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Check your inbox',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorOnSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "If you don't see the email within a minute, please check your Spam or Junk folder.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Actions Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // "I've Verified My Email" Button
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _checkEmailVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "I've Verified My Email",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // "Resend Verification Email" Button with professional countdown cooldown
                          OutlinedButton(
                            onPressed: isResendDisabled
                                ? null
                                : _resendVerificationEmail,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: isResendDisabled
                                    ? colorOutlineVariant.withOpacity(0.2)
                                    : colorOutlineVariant.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isResending
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: colorPrimary,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    _cooldownSeconds > 0
                                        ? "Resend Verification Email (${_cooldownSeconds}s)"
                                        : "Resend Verification Email",
                                    style: GoogleFonts.inter(
                                      color: isResendDisabled
                                          ? colorOnSurface.withOpacity(0.38)
                                          : colorOnSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // "Use another email" Button
                          Center(
                            child: TextButton(
                              onPressed: _useAnotherEmail,
                              child: Text(
                                "Use another email",
                                style: GoogleFonts.inter(
                                  color: colorPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Footer Support Link
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Need help? ",
                              style: GoogleFonts.inter(
                                color: colorOnSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Action for support contact can be placed here
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Contact Support",
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
}
