import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/help_scaffold.dart';

class _GuideSection {
  const _GuideSection(this.icon, this.title, this.description);

  final IconData icon;
  final String title;
  final String description;
}

const List<_GuideSection> _guideSections = [
  _GuideSection(
    Icons.space_dashboard_outlined,
    'Dashboard',
    'Your home base. See your account balance, a summary of the current '
        'period, and your most recent transactions at a glance.',
  ),
  _GuideSection(
    Icons.swap_vert,
    'Transactions',
    'Add income and expenses in seconds, search by amount, note or category, '
        'and edit or delete any transaction at any time.',
  ),
  _GuideSection(
    Icons.savings_outlined,
    'Budgets',
    'Set a monthly spending limit for each category and track how close you '
        'are to your limits so you always stay on top of your money.',
  ),
  _GuideSection(
    Icons.bar_chart_outlined,
    'Statistics',
    'Visual charts break down your income and expenses by category and across '
        'months, making it easy to spot spending patterns.',
  ),
  _GuideSection(
    Icons.upload_file_outlined,
    'Import',
    'Bring your bank statements into SpendWise. Upload a CSV or XLSX file, '
        'review the detected transactions, and confirm to add them.',
  ),
  _GuideSection(
    Icons.file_download_outlined,
    'Export',
    'Export all of your transactions to a CSV file that opens in Excel, '
        'Google Sheets or LibreOffice Calc — perfect for keeping a backup.',
  ),
  _GuideSection(
    Icons.account_circle_outlined,
    'Profile',
    'Manage your account: edit your profile, change your password, customise '
        'categories and notifications, switch to Dark Mode and more.',
  ),
];

/// In-app User Guide screen that explains the main SpendWise features.
class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      title: 'User Guide',
      subtitle: 'A simple walkthrough of the SpendWise features.',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorPrimary = colorScheme.primary;
    final colorOnSurface = colorScheme.onSurface;
    final colorSecondary = colorScheme.secondary;
    final colorSurfaceContainerLowest = colorScheme.surfaceContainerLowest;
    final colorSurfaceContainerLow = colorScheme.surfaceContainerLow;
    final colorPrimaryContainer = colorScheme.primaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
          child: Text(
            'Everything you need to get the most out of SpendWise.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: colorSecondary,
            ),
          ),
        ),
        for (var i = 0; i < _guideSections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorSurfaceContainerLow),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorPrimaryContainer.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _guideSections[i].icon,
                    color: colorPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _guideSections[i].title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorOnSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _guideSections[i].description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: colorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
