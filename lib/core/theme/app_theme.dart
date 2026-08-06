import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light and dark [ThemeData] for the SpendWise app.
///
/// Light mode reproduces the existing [AppColors] palette 1:1 through the
/// Material 3 [ColorScheme] so migrating screens to `Theme.of(context)`
/// produces zero visual change in light mode. Dark mode is a tasteful
/// green-tinted variant of the same design system.
abstract final class AppTheme {
  static final ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF006E2F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF22C55E),
    onPrimaryContainer: Color(0xFF00391B),
    secondary: Color(0xFF565E74),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE2FD),
    onSecondaryContainer: Color(0xFF121B33),
    tertiary: Color(0xFF505F76),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF9DADC6),
    onTertiaryContainer: Color(0xFF10222E),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF9F9F9),
    onSurface: Color(0xFF1A1C1C),
    onSurfaceVariant: Color(0xFF3D4A3D),
    outline: Color(0xFF6D7B6C),
    outlineVariant: Color(0xFFBCCBB9),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F3F3),
    surfaceContainer: Color(0xFFEEEEEE),
    surfaceContainerHigh: Color(0xFFE7E7E7),
    surfaceContainerHighest: Color(0xFFE0E0E0),
    primaryFixed: Color(0xFF6BFF8F),
    onPrimaryFixed: Color(0xFF00210D),
    primaryFixedDim: Color(0xFF4CE36F),
    onPrimaryFixedVariant: Color(0xFF005321),
    secondaryFixed: Color(0xFFDAE2FD),
    onSecondaryFixed: Color(0xFF121B33),
    secondaryFixedDim: Color(0xFFB8C3E2),
    onSecondaryFixedVariant: Color(0xFF3E4556),
  );

  static final ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF7ED4A8),
    onPrimary: Color(0xFF00391B),
    primaryContainer: Color(0xFF146B34),
    onPrimaryContainer: Color(0xFFC2FFD2),
    secondary: Color(0xFFBEC6DC),
    onSecondary: Color(0xFF29303F),
    secondaryContainer: Color(0xFF3E4556),
    onSecondaryContainer: Color(0xFFDAE2FD),
    tertiary: Color(0xFFAFC6E0),
    onTertiary: Color(0xFF193043),
    tertiaryContainer: Color(0xFF3A4A5E),
    onTertiaryContainer: Color(0xFFD7E7FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF111614),
    onSurface: Color(0xFFE2E5E0),
    onSurfaceVariant: Color(0xFFC2CBC1),
    outline: Color(0xFF8B968D),
    outlineVariant: Color(0xFF3F4941),
    surfaceContainerLowest: Color(0xFF0C100E),
    surfaceContainerLow: Color(0xFF191F1B),
    surfaceContainer: Color(0xFF1E2520),
    surfaceContainerHigh: Color(0xFF28302A),
    surfaceContainerHighest: Color(0xFF323B34),
    primaryFixed: Color(0xFF6BFF8F),
    onPrimaryFixed: Color(0xFF00210D),
    primaryFixedDim: Color(0xFF4CE36F),
    onPrimaryFixedVariant: Color(0xFF005321),
    secondaryFixed: Color(0xFFDAE2FD),
    onSecondaryFixed: Color(0xFF121B33),
    secondaryFixedDim: Color(0xFFB8C3E2),
    onSecondaryFixedVariant: Color(0xFF3E4556),
  );

  /// Light theme. Every value mirrors the existing light-mode palette.
  static final ThemeData light = _buildTheme(_lightScheme);

  /// Dark theme. Green-tinted variant of the SpendWise design system.
  static final ThemeData dark = _buildTheme(_darkScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.interTextTheme(),
    );
  }
}
