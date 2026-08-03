import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/features/authentication/screens/login_screen.dart';
//import 'package:spendwise/features/authentication/screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/features/authentication/screens/verify_email_screen.dart';
import 'package:spendwise/core/shell/home_shell.dart';

//import 'dart:math' as math;

/*void main() {
  runApp(const MaterialApp(
    home: SpendWiseSplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}*/

class SpendWiseSplashScreen extends StatefulWidget {
  const SpendWiseSplashScreen({super.key});

  @override
  State<SpendWiseSplashScreen> createState() => _SpendWiseSplashScreenState();
}

class _SpendWiseSplashScreenState extends State<SpendWiseSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Mouse movement offset
  Offset _mouseOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Entry animation: 1.2s cubic-bezier(0.16, 1, 0.3, 1)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Cubic(0.16, 1, 0.3, 1),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Cubic(0.16, 1, 0.3, 1),
      ),
    );

    _mainController.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.reload();

        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                refreshedUser != null && refreshedUser.emailVerified
                ? const HomeShell()
                : const VerifyEmailScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from Tailwind Config
    const colorBg = Color(0xFFF0FDF4); // rgb(240, 253, 244)
    const colorPrimary = Color(0xFF006E2F);
    const colorPrimaryContainer = Color(0xFF22C55E);
    const colorSecondaryContainer = Color(0xFFDAE2FD);
    //const colorOnBackground = Color(0xFF1A1C1C);

    return Scaffold(
      backgroundColor: colorBg,
      body: MouseRegion(
        onHover: (event) {
          // Micro-interaction: Calculate offset based on mouse position
          final size = MediaQuery.of(context).size;
          setState(() {
            _mouseOffset = Offset(
              (event.position.dx / size.width - 0.5) * 8,
              (event.position.dy / size.height - 0.5) * 8,
            );
          });
        },
        child: Stack(
          children: [
            // --- Atmospheric Gradient Layer ---
            Positioned(
              bottom: -150,
              left: -100,
              child: _BlurCircle(
                color: colorPrimaryContainer.withOpacity(0.1),
                size: 600,
                blur: 130,
              ),
            ),
            Positioned(
              top: -125,
              right: -125,
              child: _BlurCircle(
                color: colorSecondaryContainer.withOpacity(0.15),
                size: 500,
                blur: 110,
              ),
            ),

            // --- Main Content ---
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _mouseOffset,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Image.asset(
                        'assets/images/spendwise_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Wordmark
                    /*Text(
                      '',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: colorOnBackground,
                        letterSpacing: -0.32,
                      ),
                    ), */

                    const SizedBox(height: 40),

                    // Refined Loading Indicator
                    const DotLoader(color: colorPrimaryContainer),
                    
                    const SizedBox(height: 90),
                    
                    Text(
                      'Your Journey to Smarter Spending',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: colorPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const _BlurCircle({required this.color, required this.size, required this.blur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
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

class DotLoader extends StatefulWidget {
  final Color color;
  const DotLoader({super.key, required this.color});

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Logic to replicate dotBounce keyframe delays
            double delay = index * 0.16;
            double progress = (_controller.value - delay) % 1.0;
            if (progress < 0) progress += 1.0;

            double scale = 0.6;
            double opacity = 0.4;

            if (progress > 0.0 && progress < 0.4) {
              // Scaling up
              double t = progress / 0.4;
              scale = 0.6 + (0.5 * t); // 0.6 to 1.1
              opacity = 0.4 + (0.6 * t); // 0.4 to 1.0
            } else if (progress >= 0.4 && progress < 1.0) {
              // Scaling down
              double t = (progress - 0.4) / 0.6;
              scale = 1.1 - (0.5 * t); // 1.1 to 0.6
              opacity = 1.0 - (0.6 * t); // 1.0 to 0.4
            }

            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          },
        );
      }),
    );
  }
}