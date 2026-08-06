import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/animated_press_card.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/help/screens/faq_screen.dart';
import 'package:spendwise/features/help/screens/user_guide_screen.dart';
import 'package:spendwise/features/help/services/help_contact_service.dart';

class HelpCentreScreen extends StatefulWidget {
  const HelpCentreScreen({super.key});

  @override
  State<HelpCentreScreen> createState() => _HelpCentreScreenState();
}

class _HelpCentreScreenState extends State<HelpCentreScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  bool _isLoaded = true; // Set to false to preview the Error Empty State

  final HelpContactService _helpContactService = HelpContactService();

  // Strict colors matching the SpendWise design system
  Color get colorPrimary => Theme.of(context).colorScheme.primary;
  Color get colorPrimaryContainer => Theme.of(context).colorScheme.primaryContainer;
  Color get colorBackground => Theme.of(context).colorScheme.surface;
  Color get colorSurfaceContainerLowest =>
      Theme.of(context).colorScheme.surfaceContainerLowest;
  Color get colorSurfaceContainerLow =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  Color get colorOnSurfaceVariant => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get colorOnSurface => Theme.of(context).colorScheme.onSurface;
  Color get colorPrimaryFixed => Theme.of(context).colorScheme.primaryFixed;
  Color get colorSecondaryFixed => Theme.of(context).colorScheme.secondaryFixed;
  Color get colorOutlineVariant => Theme.of(context).colorScheme.outlineVariant;

  // Secondary, Tertiary, and Outline colors matching specs
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorTertiary => Theme.of(context).colorScheme.tertiary;
  Color get colorOutline => Theme.of(context).colorScheme.outline;

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

  // Simulates reloading data
  void _retryLoading() {
    setState(() {
      _isLoaded = true;
    });
  }

  // Opens the device's email app with a prepared subject
  Future<void> _openSupportEmail(String subject) async {
    final launched = await _helpContactService.launchSupportEmail(subject);
    if (!launched && mounted) {
      _showSnackBar('Could not open your email app');
    }
  }

  // Shared inline helper for the "Coming Soon" placeholders
  void _showComingSoon() {
    _showSnackBar('Coming Soon');
  }

  // Consistent Snackbar style used across the app
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
      ),
    );
  }

  // Copies the support email to the clipboard
  void _copySupportEmail() {
    Clipboard.setData(
      const ClipboardData(text: HelpContactService.supportEmail),
    );
    _showSnackBar('Support email copied.');
  }

  // Opens the platform share sheet with the SpendWise invite text
  Future<void> _shareSpendWise() async {
    await _helpContactService.shareSpendWise();
  }

  // Shows the built-in open source licenses page using the app theme
  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'SpendWise',
    );
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
                        
                        // Condition layout showing Empty State or Segmented Cards
                        !_isLoaded
                            ? EntranceAnimation(
                                delayMs: 100,
                                child: _buildEmptyState(),
                              )
                            : Column(
                                children: [
                                  EntranceAnimation(
                                    delayMs: 100,
                                    child: _buildQuickHelpSection(),
                                  ),
                                  const SizedBox(height: 24),
                                  EntranceAnimation(
                                    delayMs: 180,
                                    child: _buildResourcesSection(),
                                  ),
                                  const SizedBox(height: 24),
                                  EntranceAnimation(
                                    delayMs: 240,
                                    child: _buildCommunitySection(),
                                  ),
                                  const SizedBox(height: 24),
                                  EntranceAnimation(
                                    delayMs: 300,
                                    child: _buildContactCard(),
                                  ),
                                ],
                              ),
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
                      'Help Centre',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorSecondary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find answers, contact support and learn more about SpendWise.',
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

  // Section 1: Quick Help Cards Row
  Widget _buildQuickHelpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Help'),
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
                icon: Icons.help_outline,
                title: 'Frequently Asked Questions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.support_agent_outlined,
                title: 'Contact Support',
                onTap: () => _openSupportEmail('SpendWise Support'),
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                onTap: () => _openSupportEmail('Bug Report'),
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.lightbulb_outline,
                title: 'Request a Feature',
                onTap: () => _openSupportEmail('Feature Request'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 2: Resources List Card (Omit leading icons as requested)
  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Resources'),
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
                title: 'User Guide',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserGuideScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Privacy Policy',
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Terms & Conditions',
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Open Source Licenses',
                onTap: _showLicenses,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 3: Community List Card
  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Community'),
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
                title: 'Rate SpendWise',
                trailingWidget: Icon(Icons.star_border, color: colorOutline, size: 20),
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Share SpendWise',
                trailingWidget: Icon(Icons.share_outlined, color: colorOutline, size: 20),
                onTap: _shareSpendWise,
              ),
              _buildDivider(),
              _buildSettingsRow(
                title: 'Follow Updates',
                trailingWidget: Icon(Icons.rss_feed, color: colorOutline, size: 20),
                onTap: _showComingSoon,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 4: Email Support Card Component (Highlighted tint card)
  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorPrimary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorPrimaryContainer.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.mail_outlined, color: colorPrimary, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            'Support Email',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: colorOnSurface),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'support@spendwise.app',
                style: GoogleFonts.inter(fontSize: 16, color: colorPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _copySupportEmail,
                icon: Icon(Icons.copy, color: colorPrimary, size: 16),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Usually within 24 hours',
            style: GoogleFonts.inter(fontSize: 12, color: colorSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper title row generator for sections
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorPrimary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Helper row builder inside cards (Accessibility compliant with 48dp min height)
  Widget _buildSettingsRow({
    IconData? icon,
    required String title,
    String? suffixText,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return AnimatedPressCard(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorPrimaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorPrimary, size: 20),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorOnSurface,
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

  // Clean empty state with illustrative trigger action button
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: colorSurfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_outlined,
              size: 56,
              color: colorOutlineVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unable to load Help Centre',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
