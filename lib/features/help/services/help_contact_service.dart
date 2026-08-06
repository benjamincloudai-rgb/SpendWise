import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Isolated Help Center actions: launching the email app with a prepared
/// subject and sharing SpendWise. Keeps the platform launch details out of
/// the UI screens.
class HelpContactService {
  static const String supportEmail = 'support@spendwise.app';

  static const String shareText =
      'Check out SpendWise — Smart Personal Finance Manager';

  /// Opens the device's email app addressed to [supportEmail] with [subject].
  ///
  /// Returns `false` when no email client could be launched so the caller can
  /// show a graceful message instead of crashing.
  Future<bool> launchSupportEmail(String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens the platform share sheet with the SpendWise share text.
  Future<void> shareSpendWise() {
    return SharePlus.instance.share(
      ShareParams(text: shareText, subject: shareText),
    );
  }
}
