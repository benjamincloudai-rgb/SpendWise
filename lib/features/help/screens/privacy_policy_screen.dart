import 'package:flutter/material.dart';

import '../widgets/help_scaffold.dart';
import '../widgets/legal_sections_view.dart';

const List<LegalSection> _privacySections = [
  LegalSection(
    title: 'Information We Collect',
    icon: Icons.person_outline,
    body: 'We collect the information you provide directly, including your '
        'name, email address and profile details. We also store the financial '
        'records you create or import — transactions, categories, budgets and '
        'settings — so they can be shown and managed inside SpendWise.',
  ),
  LegalSection(
    title: 'How We Use Information',
    icon: Icons.insights_outlined,
    body: 'Your information is used to power the features you use: showing '
        'balances and statistics, calculating budgets, generating '
        'notifications, and keeping your account secure. We never sell your '
        'personal or financial information to anyone.',
  ),
  LegalSection(
    title: 'Data Storage',
    icon: Icons.storage_outlined,
    body: 'Your data is stored securely in the cloud so it stays in sync '
        'across your devices. Deleting a transaction or category removes it '
        'from your account. You can request complete removal of your account '
        'and data at any time.',
  ),
  LegalSection(
    title: 'Firebase Authentication',
    icon: Icons.verified_user_outlined,
    body: 'Sign-in is handled by Firebase Authentication. We only store the '
        'identity details needed to recognise you — your email address and, '
        'if you choose, your display name and photo. We never see or store '
        'your password.',
  ),
  LegalSection(
    title: 'Firestore Storage',
    icon: Icons.cloud_outlined,
    body: 'Your transactions and settings are saved in Cloud Firestore, a '
        'secure Firebase database. Access is protected by your account, and '
        'security rules ensure only you can read and modify your own data.',
  ),
  LegalSection(
    title: 'Bank Statement Imports',
    icon: Icons.upload_file_outlined,
    body: 'When you import a bank statement, the file is parsed on your '
        'device and the recognised transactions are added to your account. '
        'Statement files themselves are not stored or uploaded beyond the '
        'transactions you confirm.',
  ),
  LegalSection(
    title: 'Notifications',
    icon: Icons.notifications_outlined,
    body: 'Notification preferences are stored in your account. Notifications '
        '(budget alerts, reminders, summaries and insights) are only sent in '
        'the way you have chosen. You can turn them off at any time from '
        'Profile → Notifications.',
  ),
  LegalSection(
    title: 'Security',
    icon: Icons.lock_outline,
    body: 'We use industry-standard practices to protect your data, including '
        'encrypted connections, secure authentication and database access '
        'rules. You are responsible for keeping your password and device '
        'secure.',
  ),
  LegalSection(
    title: 'Contact Information',
    icon: Icons.mail_outline,
    body: 'Questions about this policy? Contact us any time at '
        'support@spendwise.app and we will be happy to help.',
  ),
];

/// In-app Privacy Policy screen built from expandable, offline sections.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      title: 'Privacy Policy',
      subtitle: 'How SpendWise collects and protects your data.',
      body: LegalSectionsView(sections: _privacySections),
    );
  }
}
