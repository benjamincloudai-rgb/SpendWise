import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pdfrx/pdfrx.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_lock_gate.dart';
import 'services/app_lock_controller.dart';
import 'services/theme_controller.dart';
import 'features/authentication/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await pdfrxFlutterInitialize();
  await AppLockController.instance.init();

  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Rebuilds MaterialApp when the persisted dark-mode preference changes
      // so the active theme swaps instantly and app-wide.
      animation: ThemeController.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
          home: const SpendWiseSplashScreen(),
        );
      },
    );
  }
}
