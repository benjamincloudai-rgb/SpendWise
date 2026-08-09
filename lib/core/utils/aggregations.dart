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

/// Returns whether [tx] belongs to the year and month of [month].
bool isInMonth(TransactionModel tx, DateTime month) {
  return tx.date.year == month.year && tx.date.month == month.month;
}

/// Sums the expense amounts of [transactions] that fall within [month].
///
/// Includes only expense transactions ([TransactionType.expense]) whose date
/// matches the year and month of [month]. Income and other months are ignored.
double expenseTotalForMonth(
  List<TransactionModel> transactions,
  DateTime month,
) {
  return sumExpense(
    transactions.where((tx) => isInMonth(tx, month)).toList(),
  );
}

/// Computes the percentage change from [previous] to [current].
///
/// Returns null when [previous] is zero, since a percentage cannot be
/// meaningfully computed (guards against division by zero).
double? percentChange(double current, double previous) {
  if (previous == 0) return null;
  return (current - previous) / previous * 100;
}

/// The first day of the calendar month preceding [month].
///
/// Dart normalizes month underflow, so January resolves to December of the
/// previous year.
DateTime previousMonth(DateTime month) {
  return DateTime(month.year, month.month - 1, 1);
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
