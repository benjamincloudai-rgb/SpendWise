import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/help_scaffold.dart';

class _FaqEntry {
  const _FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

class _FaqSection {
  const _FaqSection(this.title, this.icon, this.entries);

  final String title;
  final IconData icon;
  final List<_FaqEntry> entries;
}

const List<_FaqSection> _faqSections = [
  _FaqSection(
    'Importing Bank Statements',
    Icons.upload_file_outlined,
    [
      _FaqEntry(
        'How do I import my bank statements?',
        'Open the Import section from the home screen, choose your statement '
            'file, review the detected transactions and confirm. Every imported '
            'transaction is shown for review before it is added.',
      ),
      _FaqEntry(
        'Which file formats are supported?',
        'SpendWise supports CSV and XLSX bank statement files.',
      ),
      _FaqEntry(
        'Are my imported transactions stored safely?',
        'Yes. Imported transactions are stored securely in your account and '
            'are only visible to you.',
      ),
    ],
  ),
  _FaqSection(
    'Budgets',
    Icons.savings_outlined,
    [
      _FaqEntry(
        'How do I create a budget?',
        'Open the Budget screen and tap the add button. Pick a category, set a '
            'monthly limit and SpendWise will track your spending against it.',
      ),
      _FaqEntry(
        'Can I edit or delete a budget?',
        'Yes. Open the budget and use the edit or delete options. Deleting a '
            'budget never removes your transactions.',
      ),
    ],
  ),
  _FaqSection(
    'Categories',
    Icons.category_outlined,
    [
      _FaqEntry(
        'Can I create custom categories?',
        'Yes. Open Manage Categories from the Profile screen and add your own '
            'category with a custom name, icon and colour.',
      ),
      _FaqEntry(
        'How are transactions assigned to categories?',
        'When you add or import a transaction you pick its category. Imported '
            'statements are also matched to categories automatically.',
      ),
    ],
  ),
  _FaqSection(
    'Statistics',
    Icons.bar_chart_outlined,
    [
      _FaqEntry(
        'How do I see my spending breakdown?',
        'Open the Statistics screen to view charts of your income and expenses, '
            'grouped by category and across time.',
      ),
      _FaqEntry(
        'Can I look at a specific month?',
        'Yes. Use the month selector on the Statistics screen to move between '
            'months.',
      ),
    ],
  ),
  _FaqSection(
    'Exporting Data',
    Icons.file_download_outlined,
    [
      _FaqEntry(
        'How do I export my transactions?',
        'Open the Profile screen and tap Export Data. SpendWise creates a CSV '
            'file that you can save or share anywhere you like.',
      ),
      _FaqEntry(
        'Which app can open the export?',
        'The CSV file opens in Microsoft Excel, Google Sheets and LibreOffice '
            'Calc.',
      ),
    ],
  ),
  _FaqSection(
    'Account Settings',
    Icons.account_circle_outlined,
    [
      _FaqEntry(
        'How do I change my password?',
        'Open the Profile screen, tap Change Password, enter your current '
            'password and choose a new one.',
      ),
      _FaqEntry(
        'How do I update my profile?',
        'Open the Profile screen and tap Edit Profile to update your name, '
            'photo and other details.',
      ),
    ],
  ),
  _FaqSection(
    'Notifications',
    Icons.notifications_outlined,
    [
      _FaqEntry(
        'How do I manage notifications?',
        'Open Profile → Notifications. You can switch budget alerts, reminders, '
            'summaries and insights on or off, and choose a reminder time and '
            'notification sound.',
      ),
      _FaqEntry(
        'What are Smart Insights?',
        'Smart Insights are personalised notifications about your spending '
            'habits and saving opportunities.',
      ),
    ],
  ),
  _FaqSection(
    'Dark Mode',
    Icons.dark_mode_outlined,
    [
      _FaqEntry(
        'How do I enable Dark Mode?',
        'Open the Profile screen and use the Dark Mode switch to toggle between '
            'the light and dark themes.',
      ),
    ],
  ),
];

/// In-app FAQ screen built from offline, expandable sections.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      title: 'FAQ',
      subtitle: 'Answers to common questions about SpendWise.',
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
    final colorOutlineVariant = colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        for (var i = 0; i < _faqSections.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          _buildSectionHeader(colorPrimary, _faqSections[i]),
          Container(
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
            child: Column(
              children: [
                for (var j = 0; j < _faqSections[i].entries.length; j++) ...[
                  if (j > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      height: 1,
                      color: colorOutlineVariant.withValues(alpha: 0.2),
                    ),
                  _buildTile(
                    colorPrimary: colorPrimary,
                    colorOnSurface: colorOnSurface,
                    colorSecondary: colorSecondary,
                    entry: _faqSections[i].entries[j],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(Color colorPrimary, _FaqSection section) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(section.icon, color: colorPrimary, size: 18),
          const SizedBox(width: 8),
          Text(
            section.title,
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

  Widget _buildTile({
    required Color colorPrimary,
    required Color colorOnSurface,
    required Color colorSecondary,
    required _FaqEntry entry,
  }) {
    return ExpansionTile(
      key: PageStorageKey<String>(entry.question),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
      iconColor: colorPrimary,
      collapsedIconColor: colorPrimary,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        entry.question,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorOnSurface,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            entry.answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: colorSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
