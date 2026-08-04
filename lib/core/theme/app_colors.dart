import 'package:flutter/material.dart';

/// Single source of truth for the SpendWise Material 3 color palette.
///
/// Every screen previously redeclared these values as instance fields.
/// Keep the values below in sync with the SpendWise design system spec.
abstract final class AppColors {
  static const Color primary = Color(0xFF006E2F);
  static const Color primaryContainer = Color(0xFF22C55E);
  static const Color background = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color onSurfaceVariant = Color(0xFF3D4A3D);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color primaryFixed = Color(0xFF6BFF8F);
  static const Color secondaryFixed = Color(0xFFDAE2FD);
  static const Color outlineVariant = Color(0xFFBCCBB9);

  static const Color secondary = Color(0xFF565E74);
  static const Color tertiary = Color(0xFF505F76);
  static const Color outline = Color(0xFF6D7B6C);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
}
