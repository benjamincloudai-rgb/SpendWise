import '../../../models/budget_model.dart';
import '../../../models/transaction_model.dart';

/// Pure spend calculations for the Budget feature.
///
/// Spent amounts are always derived from the user's transactions at render
/// time — the stored [BudgetModel.spentAmount] is a legacy field and is never
/// used for UI calculations.
class BudgetSpendCalculator {
  /// The month period key (`year * 100 + month`) used by budgets and by the
  /// transaction matching in [spentFor].
  int periodOf(DateTime date) => date.year * 100 + date.month;

  /// Total spent for [budget]: the sum of expense transactions that belong to
  /// the budget's period and whose category matches the budget's category
  /// name (case-insensitive).
  double spentFor(BudgetModel budget, List<TransactionModel> transactions) {
    final period = budget.period;
    final categoryKey = budget.categoryName.trim().toLowerCase();
    if (categoryKey.isEmpty) return 0.0;

    var total = 0.0;
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (periodOf(tx.date) != period) continue;
      if (tx.categoryId.trim().toLowerCase() != categoryKey) continue;
      total += tx.amount;
    }
    return total;
  }

  /// Sums the computed spend across every [budgets] entry.
  double totalSpent(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    var total = 0.0;
    for (final budget in budgets) {
      total += spentFor(budget, transactions);
    }
    return total;
  }
}
