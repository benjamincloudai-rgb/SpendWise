import 'statement_row.dart';
import 'transaction_type.dart';

/// A parsed [StatementRow] enriched with inferred information.
///
/// Phase 6C adds the transaction [type], a numeric [amount], a cleaned
/// [merchant], and a suggested [category]. The original raw values remain
/// untouched in [row]. Nothing here is ever persisted.
class StatementRowInfo {
  final StatementRow row;
  final TransactionType type;
  final double? amount;
  final String merchant;
  final String category;

  const StatementRowInfo({
    required this.row,
    required this.type,
    required this.amount,
    required this.merchant,
    required this.category,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isUnknown => type == TransactionType.unknown;
}
