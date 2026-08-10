import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendwise/core/utils/formatters.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/settings/screens/settings_screen.dart';
import 'package:spendwise/features/categories/screens/manage_categories_screen.dart';
import 'package:spendwise/features/profile/screens/notifications_screen.dart';
import 'package:spendwise/features/profile/screens/help_centre_screen.dart';
import 'package:spendwise/features/help/screens/about_screen.dart';
import 'package:spendwise/features/help/screens/privacy_policy_screen.dart';
import 'package:spendwise/features/help/screens/terms_screen.dart';
import 'package:spendwise/features/profile/screens/edit_profile_screen.dart';
import 'package:spendwise/features/profile/screens/change_password_screen.dart';
import 'package:spendwise/features/profile/domain/profile_avatars.dart';
import 'package:spendwise/features/settings/screens/currency_selection_screen.dart';
import 'package:spendwise/services/currency_controller.dart';
import 'package:spendwise/services/theme_controller.dart';
import 'package:spendwise/core/currency/currencies.dart';
import 'package:spendwise/features/export/services/transaction_export_service.dart';
import 'package:spendwise/models/dashboard_summary_model.dart';
import 'package:spendwise/services/dashboard_service.dart';
import 'package:spendwise/features/authentication/screens/login_screen.dart';
import 'package:spendwise/services/app_lock_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;

  final DashboardService _dashboardService = DashboardService();

  final TransactionExportService _exportService = TransactionExportService();

  bool _isExporting = false;

  bool _isLoggingOut = false;

  late Stream<DashboardSummaryModel> _summaryStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  // Strict colors matching the SpendWise design system
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

  // Secondary, Tertiary, and Error colors matching specs
  Color get colorSecondary => Theme.of(context).colorScheme.secondary;
  Color get colorTertiary => Theme.of(context).colorScheme.tertiary;
  Color get colorOutline => Theme.of(context).colorScheme.outline;
  Color get colorError => Theme.of(context).colorScheme.error;

  @override
  void initState() {
    super.initState();
    _userStream = _buildUserStream();
    _summaryStream = _dashboardService.getDashboardSummary();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _buildUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  void _retryLoadProfile() {
    setState(() {
      _userStream = _buildUserStream();
    });
  }

  void _retryLoadSummary() {
    setState(() {
      _summaryStream = _dashboardService.getDashboardSummary();
    });
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    // Recreate the user stream so the updated name/avatar shows immediately.
    if (mounted) _retryLoadProfile();
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
                  top: 76, // Clears top header App Bar
                  bottom: 40, // Secure padding at the bottom
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        EntranceAnimation(
                          delayMs: 100,
                          child: _buildProfileCard(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 180,
                          child: _buildFinancialSummary(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 240,
                          child: _buildAccountSection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 300,
                          child: _buildPreferencesSection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 360,
                          child: _buildSupportSection(),
                        ),
                        const SizedBox(height: 24),
                        EntranceAnimation(
                          delayMs: 420,
                          child: _buildLogoutButton(),
                        ),
                        const SizedBox(height: 32),
                        EntranceAnimation(delayMs: 480, child: _buildFooter()),
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

  // Header Component (Sticky Top App Bar)
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
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorSecondary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Large Rounded Profile Card Widget
  Widget _buildProfileCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (_userStream == null) {
          return _buildProfileCardShell(
            child: _buildProfileInfoContent(
              displayName: 'Unnamed User',
              displayEmail: '—',
              memberSince: '—',
              avatarKey: defaultProfileAvatarKey,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildProfileCardShell(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildProfileCardShell(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: _buildProfileErrorContent(),
            ),
          );
        }

        final data = snapshot.data?.data();
        final rawName = data?['fullName'];
        final String displayName =
            rawName is String && rawName.trim().isNotEmpty
            ? rawName
            : 'Unnamed User';
        final String memberSince = _formatMemberSince(data?['createdAt']);
        final String? email = FirebaseAuth.instance.currentUser?.email;
        final String displayEmail = (email == null || email.isEmpty)
            ? '—'
            : email;
        final rawAvatarKey = data?['avatarKey'];
        final String avatarKey =
            rawAvatarKey is String && rawAvatarKey.isNotEmpty
            ? rawAvatarKey
            : defaultProfileAvatarKey;

        return _buildProfileCardShell(
          child: _buildProfileInfoContent(
            displayName: displayName,
            displayEmail: displayEmail,
            memberSince: memberSince,
            avatarKey: avatarKey,
          ),
        );
      },
    );
  }

  Widget _buildProfileCardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: child,
    );
  }

  Widget _buildProfileInfoContent({
    required String displayName,
    required String displayEmail,
    required String memberSince,
    required String avatarKey,
  }) {
    final avatar = profileAvatarFor(avatarKey);

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: profileAvatarDecoration(
                avatarKey,
                ringColor: colorPrimaryContainer,
                ringWidth: 4,
              ),
              child: Icon(avatar.icon, size: 44, color: avatar.color),
            ),
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colorPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorSurfaceContainerLowest,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayEmail,
              style: GoogleFonts.inter(fontSize: 14, color: colorSecondary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.verified, color: colorPrimary, size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          memberSince,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatMemberSince(Object? value) {
    if (value is! Timestamp) return '—';
    final date = value.toDate();
    return 'Member since ${formatMonthYear(date)}';
  }

  Widget _buildProfileErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_outlined, color: colorSecondary, size: 28),
        const SizedBox(height: 8),
        Text(
          'Unable to load profile',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _retryLoadProfile,
          style: TextButton.styleFrom(
            foregroundColor: colorPrimary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // Financial Summary Section Widget
  Widget _buildFinancialSummary() {
    return StreamBuilder<DashboardSummaryModel>(
      stream: _summaryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildSummaryCard(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildSummaryCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: _buildSummaryErrorContent(),
            ),
          );
        }

        final summary = snapshot.data ?? DashboardSummaryModel.zero();

        return _buildSummaryCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCardColumn(
                Icons.account_balance_wallet_outlined,
                'Current Balance',
                CurrencyController.instance.format(summary.currentBalance),
                colorPrimary,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorOutlineVariant.withOpacity(0.3),
              ),
              _buildSummaryCardColumn(
                Icons.trending_up,
                'Total Income',
                CurrencyController.instance.format(summary.totalIncome),
                colorSecondary,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorOutlineVariant.withOpacity(0.3),
              ),
              _buildSummaryCardColumn(
                Icons.trending_down,
                'Total Expenses',
                CurrencyController.instance.format(summary.totalExpense),
                colorError,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
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
      child: child,
    );
  }

  Widget _buildSummaryErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_outlined, color: colorSecondary, size: 24),
        const SizedBox(height: 8),
        Text(
          'Unable to load summary',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorOnSurface,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _retryLoadSummary,
          style: TextButton.styleFrom(
            foregroundColor: colorPrimary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardColumn(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Account Settings Section List
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'ACCOUNT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorPrimary,
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
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _openEditProfile,
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.lock_open,
                title: 'Change Password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.category_outlined,
                title: 'Manage Categories',
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ManageCategoriesScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.linear,
                                    ),
                                  ),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 200),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 200,
                      ),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.linear,
                                    ),
                                  ),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 200),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 200,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Preferences Settings Section List
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
              color: colorPrimary,
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
                suffixText: currencyLabelFor(CurrencyController.instance.code),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CurrencySelectionScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                trailingWidget: Switch(
                  value: ThemeController.instance.isDarkMode,
                  activeColor: Colors.white,
                  activeTrackColor: colorPrimary,
                  inactiveThumbColor: colorSecondary,
                  inactiveTrackColor: colorSurfaceContainerLow,
                  onChanged: (val) {
                    ThemeController.instance.setDarkMode(val);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Support Settings Section List
  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'SUPPORT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorPrimary,
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
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCentreScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.gavel,
                title: 'Privacy Policy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.file_download_outlined,
                title: 'Export Data',
                onTap: _isExporting ? null : _exportData,
              ),
              _buildDivider(),
              _buildSettingsRow(
                icon: Icons.info_outline,
                title: 'About SpendWise',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Outlined Logout Button
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoggingOut ? null : _confirmLogout,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorError.withOpacity(0.2), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: colorError,
        ),
        child: _isLoggingOut
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Confirmation dialog before logging out
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(Icons.logout, color: colorError, size: 40),
          title: Text(
            'Logout',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorOnSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of SpendWise?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorError,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _performLogout();
  }

  Future<void> _performLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();

      // Reset the active theme to default light mode so the Login screen is
      // readable. The saved preference is kept and restored on next login.
      ThemeController.instance.resetToLight();

      // Ensure the App Lock overlay is inactive while logged out. This only
      // drops the overlay; the PIN, biometric preference and enabled state
      // are preserved so App Lock keeps working after the next login.
      AppLockController.instance.unlock();

      if (!mounted) return;

      // Remove the entire authenticated stack so the back button cannot
      // return to HomeShell.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'network-request-failed'
                ? 'Network error. Please check your connection and try again.'
                : 'Unable to log out. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  // Footer Component
  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'SpendWise',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorPrimary.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Version 1.0.0',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorSecondary.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Made with ❤️ in India',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // Helper row builder inside cards
  // Exports every transaction to a shareable CSV file and reports the result
  Future<void> _exportData() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    final result = await _exportService.export();

    if (!mounted) return;
    setState(() => _isExporting = false);

    final messenger = ScaffoldMessenger.of(context);
    switch (result.status) {
      case TransactionExportStatus.success:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Export complete — ${result.count} transactions',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        );
      case TransactionExportStatus.noTransactions:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'No transactions to export yet',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        );
      case TransactionExportStatus.failure:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Export failed',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        );
    }
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? suffixText,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: colorOnSurfaceVariant, size: 22),
            const SizedBox(width: 16),
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
              Icon(Icons.chevron_right, color: colorOutline, size: 20),
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
