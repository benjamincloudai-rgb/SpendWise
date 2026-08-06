import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendwise/core/widgets/animated_press_card.dart';
import 'package:spendwise/core/widgets/blur_blob.dart';
import 'package:spendwise/core/widgets/bottom_sheet_handle.dart';
import 'package:spendwise/core/widgets/entrance_animation.dart';
import 'package:spendwise/features/notifications/domain/notification_sounds.dart';
import 'package:spendwise/services/notification_settings_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;

  NotificationSettingsController get _controller =>
      NotificationSettingsController.instance;

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
  Color get colorErrorContainer => Theme.of(context).colorScheme.errorContainer;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Load the persisted preferences (idempotent) before rendering toggles.
    _controller.init();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  // Reactive computed empty state getter
  bool get _allNotificationsOff => _controller.allNotificationsOff;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // --- Atmospheric Background Blurs (Aligned with your other screens) ---
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
              child: AnimatedBuilder(
                // Rebuilds toggles / values when the persisted settings change
                // or finish loading, so no temporary defaults flash.
                animation: _controller,
                builder: (context, child) {
                  if (!_controller.loaded) {
                    return Center(
                      child: CircularProgressIndicator(color: colorPrimary),
                    );
                  }

                  final isOff = _allNotificationsOff;

                  return SingleChildScrollView(
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
                            isOff
                                ? EntranceAnimation(
                                    delayMs: 100,
                                    child: _buildEmptyState(),
                                  )
                                : Column(
                                    children: [
                                      EntranceAnimation(
                                        delayMs: 100,
                                        child: _buildGeneralSection(),
                                      ),
                                      const SizedBox(height: 24),
                                      EntranceAnimation(
                                        delayMs: 180,
                                        child: _buildSecuritySection(),
                                      ),
                                      const SizedBox(height: 24),
                                      EntranceAnimation(
                                        delayMs: 240,
                                        child: _buildSmartInsightsSection(),
                                      ),
                                      const SizedBox(height: 24),
                                      EntranceAnimation(
                                        delayMs: 300,
                                        child: _buildPreferencesSection(),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
                      'Notifications',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorSecondary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4), // Increased spacing for accessibility
                    Text(
                      'Manage reminders and important financial alerts.',
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

  // Section 1: General Toggles Card
  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.notifications_active_outlined, 'Alerts'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _buildSwitchRow(
                title: 'Budget Alerts',
                description: 'Get notified when you approach budget limits',
                value: _controller.budgetAlerts,
                onChanged: _controller.setBudgetAlerts,
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: 'Daily Reminder',
                description: "A gentle nudge to log today's expenses",
                value: _controller.dailyReminder,
                onChanged: _controller.setDailyReminder,
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: 'Weekly Summary',
                description: 'Review your spending habits every Sunday',
                value: _controller.weeklySummary,
                onChanged: _controller.setWeeklySummary,
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: 'Monthly Summary',
                description: "Detailed insights into your month's finances",
                value: _controller.monthlyReport,
                onChanged: _controller.setMonthlyReport,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 2: Security Toggles Card (Forced state)
  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.security_outlined, 'Security'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _buildSwitchRow(
                title: 'Security Alerts',
                description: 'Alert me of logins from new devices',
                value: true,
                onChanged: null, // Disabled matching mandatory specs
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: 'App Updates',
                description: 'Critical account and security notices',
                value: true,
                onChanged: null, // Disabled matching mandatory specs
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 3: Smart Insights Card (With renamed label)
  Widget _buildSmartInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.lightbulb_outline, 'Insights'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _buildSwitchRow(
                title: 'Smart Spending Insights',
                description: 'Receive personalized spending insights and saving recommendations.',
                value: _controller.smartInsights,
                onChanged: _controller.setSmartInsights,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 4: Preferences Tappable Selector Cards
  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.tune, 'Preferences'),
        Container(
          padding: const EdgeInsets.all(12),
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
              _buildPreferenceRow(
                title: 'Reminder Time',
                value: _controller.reminderTimeLabel,
                onTap: _pickReminderTime,
              ),
              _buildDivider(),
              _buildPreferenceRow(
                title: 'Notification Sound',
                value: _controller.notificationSoundLabel,
                onTap: _pickNotificationSound,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper title row generator for sections
  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: colorPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper switch row builder (Accessibility compliant with 48dp min height)
  Widget _buildSwitchRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final bool isDisabled = onChanged == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? colorOnSurface.withOpacity(0.5) : colorOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDisabled ? colorSecondary.withOpacity(0.5) : colorSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Opacity(
            opacity: isDisabled ? 0.6 : 1.0,
            child: SizedBox(
              height: 48, // Accessibility target height
              child: Switch(
                value: value,
                activeColor: Colors.white,
                activeTrackColor: colorPrimaryContainer,
                inactiveThumbColor: colorSecondary,
                inactiveTrackColor: colorSurfaceContainerLow,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper row builder inside cards
  Widget _buildPreferenceRow({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return AnimatedPressCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorOnSurface,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: colorOutline, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: colorOutlineVariant.withOpacity(0.2),
    );
  }

  // Picks the daily reminder time using Flutter's built-in time picker
  Future<void> _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _controller.reminderTime,
      helpText: 'Daily Reminder Time',
    );
    if (picked != null) {
      _controller.setReminderTime(picked);
    }
  }

  // Opens the notification sound selector bottom sheet
  Future<void> _pickNotificationSound() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: colorSurfaceContainerLowest,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BottomSheetHandle(),
                const SizedBox(height: 24),
                Text(
                  'Notification Sound',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorOnSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the sound used for your notifications.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: notificationSoundOptions.map((option) {
                        final bool selected =
                            option.key == _controller.notificationSound;
                        return AnimatedPressCard(
                          onTap: () {
                            _controller.setNotificationSound(option.key);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option.icon,
                                  size: 22,
                                  color: colorPrimary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: colorOnSurface,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check_circle,
                                      color: colorPrimary, size: 22),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
              Icons.notifications_off_outlined,
              size: 56,
              color: colorOutlineVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Notifications are disabled',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable notifications to stay informed about your finances.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _controller.enableAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Text(
              'Enable Notifications',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
