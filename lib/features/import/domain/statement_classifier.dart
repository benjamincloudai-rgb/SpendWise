import 'merchant_categorizer.dart';
import 'statement_row.dart';
import 'statement_row_info.dart';
import 'transaction_type.dart';

/// Turns a raw [StatementRow] into an enriched [StatementRowInfo].
///
/// Pure domain logic: amount parsing, transaction type inference, and
/// merchant/category inference. It never touches Firestore or the transaction
/// service — classification happens entirely in memory for the preview.
class StatementClassifier {
  final MerchantCategorizer _categorizer;

  StatementClassifier({MerchantCategorizer? categorizer})
      : _categorizer = categorizer ?? const MerchantCategorizer();

  /// Classifies a single [row].
  ///
  /// Type rules:
  /// - credit > 0            -> income
  /// - else debit > 0        -> expense
  /// - else                  -> unknown
  ///
  /// The amount is the credit for income, the debit for expense, and `null`
  /// for unknown rows.
  StatementRowInfo classify(StatementRow row) {
    final credit = _parseAmount(row.credit);
    final debit = _parseAmount(row.debit);

    final TransactionType type;
    final double? amount;
    if (credit != null && credit > 0) {
      type = TransactionType.income;
      amount = credit;
    } else if (debit != null && debit > 0) {
      type = TransactionType.expense;
      amount = debit;
    } else {
      type = TransactionType.unknown;
      amount = null;
    }

    final merchant = _categorizer.extractMerchant(row.description);
    return StatementRowInfo(
      row: row,
      type: type,
      amount: amount,
      merchant: merchant,
      category: _categorizer.categorize(merchant),
    );
  }

  /// Parses a raw currency string into a double, or `null` when empty or
  /// unparseable. Handles the rupee symbol, thousands separators, and common
  /// "empty" placeholders such as `--`, `N/A` and `null`.
  double? _parseAmount(String raw) {
    var cleaned = raw
        .trim()
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .replaceAll('−', '-')
        .replaceAll('–', '-');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;
    if (RegExp(r'^(--+|\.+|[Nn]/?[Aa]?|null)$').hasMatch(cleaned)) return null;
    return double.tryParse(cleaned);
  }
}
