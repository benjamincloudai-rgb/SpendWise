import 'package:flutter/material.dart';

import '../widgets/help_scaffold.dart';
import '../widgets/legal_sections_view.dart';

const List<LegalSection> _termsSections = [
  LegalSection(
    title: 'Acceptance',
    icon: Icons.check_circle_outline,
    body: 'By creating an account or using SpendWise, you agree to these '
        'Terms & Conditions. If you do not agree, please stop using the app. '
        'We may update these terms from time to time; continued use means you '
        'accept the updated terms.',
  ),
  LegalSection(
    title: 'User Responsibilities',
    icon: Icons.person_outline,
    body: 'You are responsible for the information you enter and import into '
        'SpendWise. You agree to use the app lawfully and to keep your login '
        'credentials confidential.',
  ),
  LegalSection(
    title: 'Accuracy of Financial Records',
    icon: Icons.numbers_outlined,
    body: 'SpendWise helps you record and organise your finances, but the '
        'accuracy of your records is your responsibility. Always review '
        'imported statements before confirming and check the figures in your '
        'account.',
  ),
  LegalSection(
    title: 'Data Ownership',
    icon: Icons.copyright_outlined,
    body: 'Your data is yours. You own the transactions, budgets and settings '
        'you create, and you can export or delete them at any time. SpendWise '
        'does not claim ownership of your data.',
  ),
  LegalSection(
    title: 'Limitation of Liability',
    icon: Icons.gavel_outlined,
    body: 'SpendWise is provided "as is" without warranties of any kind. To '
        'the maximum extent permitted by law, we are not liable for any '
        'financial losses or decisions made based on the information in the '
        'app. SpendWise is a tracking tool, not a financial adviser.',
  ),
  LegalSection(
    title: 'Third-Party Services',
    icon: Icons.extension_outlined,
    body: 'SpendWise relies on third-party services including Google Firebase '
        'for authentication and data storage. These services have their own '
        'terms and privacy policies, which we encourage you to review.',
  ),
  LegalSection(
    title: 'Account Security',
    icon: Icons.shield_outlined,
    body: 'You are responsible for safeguarding your account. If you suspect '
        'unauthorised access, change your password immediately and contact '
        'support. We are not liable for losses caused by compromised '
        'credentials.',
  ),
  LegalSection(
    title: 'Updates',
    icon: Icons.update,
    body: 'We may update these Terms & Conditions to reflect changes in the '
        'app or the law. Material changes will be announced within the app. '
        'The latest version always applies.',
  ),
];

/// In-app Terms & Conditions screen built from expandable, offline sections.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      title: 'Terms & Conditions',
      subtitle: 'The rules for using SpendWise.',
      body: LegalSectionsView(sections: _termsSections),
    );
  }
}
