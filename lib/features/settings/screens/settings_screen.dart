import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/theme/app_colors.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isBiometricEnabled = true;

  // Strict colors matching the SpendWise design system
  final Color colorPrimary = AppColors.primary;
  final Color colorPrimaryContainer = AppColors.primaryContainer;
  final Color colorBackground = AppColors.background;
  final Color colorSurfaceContainerLowest = AppColors.surfaceContainerLowest;
  final Color colorSurfaceContainerLow = AppColors.surfaceContainerLow;
  final Color colorSurfaceContainer = AppColors.surfaceContainer;
  final Color colorOnSurfaceVariant = AppColors.onSurfaceVariant;
  final Color colorOnSurface = AppColors.onSurface;
  final Color colorPrimaryFixed = AppColors.primaryFixed;
  final Color colorSecondaryFixed = AppColors.secondaryFixed;
  final Color colorOutlineVariant = AppColors.outlineVariant;

  // Secondary, Tertiary, and Error colors matching specs
  final Color colorSecondary = AppColors.secondary;
  final Color colorTertiary = AppColors.tertiary;
  final Color colorError = AppColors.error;
  final Color colorErrorContainer = AppColors.errorContainer;

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

            // --- Scrollable Form Content ---
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                  top: 92, // Clears top sticky App Bar with subtitle spacing
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 100,
                          child: _buildPreferencesSection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 180,
                          child: _buildPrivacySection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 240,
                          child: _buildDataSection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 300,
                          child: _buildAboutSection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 360,
                          child: _buildDangerZoneSection(),
                        ),
                        const SizedBox(height: 32),
                        EntranceAnimation(delayMs: 440, child: _buildFooter()),
                      ],
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

  // Header Component (Sticky Top App Bar with Subtitle)
  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      color: colorBackground.withOpacity(0.95),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Formatted strictly in black
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your app preferences',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Preferences Section Widget
  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'PREFERENCES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorOnSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
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
              _buildSettingsRow(
                icon: Icons.payments_outlined,
                title: 'Currency',
                suffixText: 'INR ₹',
                onTap: () {
                  // Placeholder onTap
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Privacy & Security Section Widget
  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'PRIVACY & SECURITY',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorOnSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
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
              _buildSettingsRow(
                icon: Icons.screen_lock_portrait_outlined,
                title: 'App Lock',
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.fingerprint,
                title: 'Biometric Authentication',
                trailingWidget: Switch(
                  value: _isBiometricEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: colorPrimaryContainer,
                  inactiveThumbColor: colorSecondary,
                  inactiveTrackColor: colorSurfaceContainerLow,
                  onChanged: (val) {
                    setState(() {
                      _isBiometricEnabled = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Data Section Widget
  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'DATA',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorOnSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
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
              _buildSettingsRow(
                icon: Icons.download_outlined,
                title: 'Export Transactions',
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.cloud_upload_outlined,
                title: 'Cloud Backup',
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.cleaning_services_outlined,
                title: 'Clear Cache',
                onTap: () {
                  // Placeholder onTap
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. About Section Widget
  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'ABOUT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorOnSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
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
              _buildSettingsRow(
                title: 'Privacy Policy',
                trailingWidget: Icon(
                  Icons.open_in_new,
                  color: colorOutlineVariant,
                  size: 20,
                ),
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Terms & Conditions',
                trailingWidget: Icon(
                  Icons.open_in_new,
                  color: colorOutlineVariant,
                  size: 20,
                ),
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Open Source Licenses',
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Rate SpendWise',
                trailingWidget: Icon(
                  Icons.star_outline,
                  color: colorOutlineVariant,
                  size: 20,
                ),
                onTap: () {
                  // Placeholder onTap
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Version',
                suffixText: 'SpendWise v1.0.0',
                trailingWidget: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Danger Zone Section Widget
  Widget _buildDangerZoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'DANGER ZONE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorError,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorError.withOpacity(0.1)),
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
              _buildSettingsRow(
                icon: Icons.delete_forever_outlined,
                iconColor: colorError,
                iconBgColor: colorErrorContainer,
                textColor: colorError,
                title: 'Delete Account',
                trailingWidget: const SizedBox.shrink(),
                onTap: () {
                  // Placeholder onTap
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Footer Component
  Widget _buildFooter() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SpendWise',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Made with ❤️ in India',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Helper row builder inside cards
  Widget _buildSettingsRow({
    IconData? icon,
    required String title,
    String? suffixText,
    Widget? trailingWidget,
    VoidCallback? onTap,
    Color? iconColor,
    Color? iconBgColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor ?? colorPrimaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor ?? colorPrimary, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? colorOnSurface,
                ),
              ),
            ),
            if (suffixText != null) ...[
              Text(
                suffixText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorSecondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (trailingWidget != null)
              trailingWidget
            else
              Icon(Icons.chevron_right, color: colorOutlineVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      color: colorOutlineVariant.withOpacity(0.2),
    );
  }
}

