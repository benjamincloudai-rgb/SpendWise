/// Shared aggregation helpers for transactions and categories.
library;

import 'package:spendwise/models/category_model.dart';
import 'package:spendwise/models/transaction_model.dart';

/// Sums the amounts of all [income] transactions.
///
/// Matches the previous `_totalIncome` getters.
double sumIncome(List<TransactionModel> transactions) {
  return transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);
}

/// Sums the amounts of all [expense] transactions.
///
/// Matches the previous `_totalExpenses` getters.
double sumExpense(List<TransactionModel> transactions) {
  return transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);
}

/// Computes income minus expenses for [transactions].
double netBalance(List<TransactionModel> transactions) {
  return sumIncome(transactions) - sumExpense(transactions);
}

/// Computes the savings rate ([savings] as a percentage of [income]).
///
/// Returns 0.0 when [income] is zero or negative to avoid a division-by-zero.
double savingsRate(double savings, double income) {
  if (income <= 0) return 0.0;
  return (savings / income) * 100;
}

/// Returns the next sort order for a new [CategoryModel] of the given [type].
///
/// Matches the previous `_nextSortOrder` implementations.
int nextSortOrder(List<CategoryModel> categories, CategoryType type) {
  final sortOrders = categories
      .where((c) => c.type == type)
      .map((c) => c.sortOrder);
  if (sortOrders.isEmpty) {
    return 0;
  }
  return sortOrders.reduce((a, b) => a > b ? a : b) + 1;
}
