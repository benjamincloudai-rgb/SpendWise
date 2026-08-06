import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/help_scaffold.dart';

class _AboutEntry {
  const _AboutEntry(this.icon, this.title);

  final IconData icon;
  final String title;
}

const String _aboutDescription =
    'SpendWise is a smart personal finance manager that helps you track your '
    'income and expenses, set budgets, and understand your spending habits — '
    'all from a single, beautifully simple app. Your data stays in sync '
    'across your devices and is always under your control.';

const List<_AboutEntry> _aboutFeatures = [
  _AboutEntry(Icons.swap_vert, 'Transaction Management'),
  _AboutEntry(Icons.savings_outlined, 'Budget Tracking'),
  _AboutEntry(Icons.bar_chart_outlined, 'Statistics'),
  _AboutEntry(Icons.upload_file_outlined, 'CSV Import'),
  _AboutEntry(Icons.table_chart_outlined, 'Excel Import'),
  _AboutEntry(Icons.file_download_outlined, 'Export Data'),
  _AboutEntry(Icons.category_outlined, 'Categories'),
  _AboutEntry(Icons.dark_mode_outlined, 'Dark Mode'),
];

const List<_AboutEntry> _aboutStack = [
  _AboutEntry(Icons.flutter_dash, 'Flutter'),
  _AboutEntry(Icons.local_fire_department_outlined, 'Firebase'),
  _AboutEntry(Icons.cloud_outlined, 'Firestore'),
  _AboutEntry(Icons.verified_user_outlined, 'Firebase Authentication'),
];

/// In-app About SpendWise screen.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      title: 'About',
      subtitle: 'Everything about SpendWise.',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorPrimary = colorScheme.primary;
    final colorOnSurface = colorScheme.onSurface;
    final colorOnSurfaceVariant = colorScheme.onSurfaceVariant;
    final colorPrimaryContainer = colorScheme.primaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Image.asset('assets/images/spendwise_logo.png', height: 88),
              const SizedBox(height: 12),
              Text(
                'SpendWise',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorOnSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorPrimaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(colorPrimary, Icons.auto_awesome_outlined, 'ABOUT'),
        _buildCard(
          colorScheme,
          child: Text(
            _aboutDescription,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: colorOnSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(colorPrimary, Icons.person_outline, 'DEVELOPER'),
        _buildCard(
          colorScheme,
          child: _buildEntryRow(colorScheme, const _AboutEntry(Icons.code, 'Benjamin Arockiaraj')),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(colorPrimary, Icons.stars_outlined, 'FEATURES'),
        _buildCard(
          colorScheme,
          child: Column(
            children: [
              for (var i = 0; i < _aboutFeatures.length; i++) ...[
                if (i > 0) _buildDivider(colorScheme),
                _buildEntryRow(colorScheme, _aboutFeatures[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(colorPrimary, Icons.handyman_outlined, 'TECHNOLOGY STACK'),
        _buildCard(
          colorScheme,
          child: Column(
            children: [
              for (var i = 0; i < _aboutStack.length; i++) ...[
                if (i > 0) _buildDivider(colorScheme),
                _buildEntryRow(colorScheme, _aboutStack[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(colorPrimary, Icons.description_outlined, 'LICENSE'),
        _buildCard(
          colorScheme,
          child: Text(
            'SpendWise is released under the MIT License. You are free to use, '
            'copy, modify and distribute the software, provided the original '
            'copyright notice is retained.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: colorOnSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(Color colorPrimary, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: colorPrimary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ColorScheme colorScheme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.surfaceContainerLow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }

  Widget _buildEntryRow(ColorScheme colorScheme, _AboutEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
