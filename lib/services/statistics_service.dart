import 'package:flutter/widgets.dart';
import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/features/categories/domain/category_visuals.dart';
import 'package:spendwise/models/category_model.dart';
import 'package:spendwise/models/statistics_summary_model.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/category_service.dart';
import 'package:spendwise/services/transaction_service.dart';

/// Aggregates Firestore data for the Statistics screen.
///
/// Follows the [DashboardService] pattern: the screen subscribes to the raw
/// streams and the service exposes pure computations for the selected month.
class StatisticsService {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  Stream<List<TransactionModel>> getTransactions() {
    return _transactionService.getTransactions();
  }

  Stream<List<CategoryModel>> getCategories() {
    return _categoryService.getCategories();
  }

  /// Computes the income, expense, and savings totals for [month].
  ///
  /// Delegates to the shared aggregation helpers ([isInMonth] and
  /// [expenseTotalForMonth]) so the Dashboard Monthly Spending card and the
  /// Statistics screen use exactly the same month/expense calculation.
  StatisticsSummaryModel computeMonthSummary(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    final double income = sumIncome(
      transactions.where((tx) => isInMonth(tx, month)).toList(),
    );
    final double expense = expenseTotalForMonth(transactions, month);

    return StatisticsSummaryModel(
      income: income,
      expense: expense,
      savings: income - expense,
    );
  }

  /// Counts the transactions of [month] and computes the average expense per
  /// expense transaction.
  ///
  /// Reuses [sumExpense]; returns 0.0 for the average when the month has no
  /// expense transactions.
  MonthActivity computeMonthActivity(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    final monthTransactions = _monthTransactions(transactions, month);
    final expenseCount = _monthExpenses(monthTransactions).length;
    final double totalExpense = sumExpense(monthTransactions);

    return MonthActivity(
      totalTransactions: monthTransactions.length,
      expenseCount: expenseCount,
      averageExpense: expenseCount > 0 ? totalExpense / expenseCount : 0.0,
    );
  }

  /// The largest single expense transaction of [month], or null when the month
  /// has no expense transactions.
  TransactionModel? computeLargestExpense(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    final expenses = _monthExpenses(_monthTransactions(transactions, month));
    if (expenses.isEmpty) return null;

    return expenses.reduce(
      (a, b) => b.amount > a.amount ? b : a,
    );
  }

  /// The number of distinct calendar days of [month] that contain at least one
  /// expense transaction.
  int computeSpendingDays(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    final expenses = _monthExpenses(_monthTransactions(transactions, month));
    return expenses
        .map((tx) => DateTime(tx.date.year, tx.date.month, tx.date.day))
        .toSet()
        .length;
  }

  /// The expense transactions of [month] (single source of truth for every
  /// expense-specific statistics computation).
  List<TransactionModel> _monthExpenses(List<TransactionModel> monthTransactions) {
    return monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
  }

  /// Compares the income, expense, and savings of [month] against the previous
  /// calendar month.
  ///
  /// Reuses [computeMonthSummary] (and therefore the shared month helpers) for
  /// both months so no filtering logic is duplicated. Percent changes are
  /// computed by the shared [percentChange] helper, which guards against
  /// division by zero.
  MonthComparison computeMonthComparison(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    final DateTime previousMonthDate = previousMonth(month);
    final StatisticsSummaryModel current = computeMonthSummary(transactions, month);
    final StatisticsSummaryModel previous =
        computeMonthSummary(transactions, previousMonthDate);

    return MonthComparison(
      income: MonthDelta(
        current: current.income,
        previous: previous.income,
        percentChange: percentChange(current.income, previous.income),
      ),
      expense: MonthDelta(
        current: current.expense,
        previous: previous.expense,
        percentChange: percentChange(current.expense, previous.expense),
      ),
      savings: MonthDelta(
        current: current.savings,
        previous: previous.savings,
        percentChange: percentChange(current.savings, previous.savings),
      ),
    );
  }

  /// The transactions belonging to [month] (single source of truth for every
  /// statistics computation). Delegates to the shared [isInMonth] helper.
  List<TransactionModel> _monthTransactions(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    return transactions.where((tx) => isInMonth(tx, month)).toList();
  }

  /// Groups the expense transactions of [month] by category and resolves each
  /// group's display metadata (name, icon, color) from [categories].
  ///
  /// Returns one entry per category ordered by descending amount, powering both
  /// the Expense Breakdown legend and the Top Categories list. Categories that
  /// were deleted after their transactions were created fall back to the same
  /// visual handling used elsewhere in the app ([categoryVisualFor]) so they
  /// render gracefully instead of breaking the screen.
  List<CategorySpending> computeCategoryBreakdown(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
    DateTime month,
  ) {
    final monthExpenses = _monthTransactions(transactions, month)
        .where((tx) => tx.type == TransactionType.expense)
        .toList();

    final categoryById = {
      for (final category in categories) category.id: category,
    };

    final amountsByCategory = <String, double>{};
    final countsByCategory = <String, int>{};
    for (final tx in monthExpenses) {
      amountsByCategory[tx.categoryId] =
          (amountsByCategory[tx.categoryId] ?? 0.0) + tx.amount;
      countsByCategory[tx.categoryId] =
          (countsByCategory[tx.categoryId] ?? 0) + 1;
    }

    final double totalExpense = sumExpense(monthExpenses);

    final breakdown = amountsByCategory.entries.map((entry) {
      final category = categoryById[entry.key];
      final String name;
      final IconData icon;
      final Color color;
      if (category != null) {
        name = category.name;
        icon = categoryIconFor(category.icon);
        color = Color(category.color);
      } else {
        final visual = categoryVisualFor(entry.key);
        name = entry.key;
        icon = visual.icon;
        color = visual.iconColor;
      }

      return CategorySpending(
        categoryId: entry.key,
        name: name,
        icon: icon,
        color: color,
        amount: entry.value,
        count: countsByCategory[entry.key] ?? 0,
        percentage:
            totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0,
      );
    }).toList();

    breakdown.sort((a, b) => b.amount.compareTo(a.amount));
    return breakdown;
  }

  /// Builds the Spending Trend series for [timeframe] over the selected [month].
  ///
  /// The selected month/year is the single source of truth; the series is
  /// never anchored to today's date:
  ///
  /// - `'Week'`: seven daily buckets (Mon-Sun) aggregating the selected
  ///   month's expense transactions by weekday.
  /// - `'Month'`: one bucket per calendar day of the selected month.
  /// - `'Year'`: twelve monthly buckets of the selected month's year.
  List<TrendPoint> computeTrendSeries(
    List<TransactionModel> transactions,
    DateTime month,
    String timeframe,
  ) {
    switch (timeframe) {
      case 'Month':
        return _monthDailyTrend(transactions, month);
      case 'Year':
        return _yearTrend(transactions, month);
      case 'Week':
      default:
        return _weekTrend(transactions, month);
    }
  }

  /// Seven daily buckets (Mon-Sun) for the selected month, keyed by weekday.
  List<TrendPoint> _weekTrend(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final amounts = List<double>.filled(7, 0.0);

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.year != month.year || tx.date.month != month.month) continue;
      amounts[tx.date.weekday - 1] += tx.amount;
    }

    return List.generate(
      7,
      (i) => TrendPoint(label: weekdayLabels[i], amount: amounts[i]),
    );
  }

  /// One bucket per calendar day of the selected month.
  List<TrendPoint> _monthDailyTrend(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final amounts = List<double>.filled(daysInMonth, 0.0);

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.year != month.year || tx.date.month != month.month) continue;
      amounts[tx.date.day - 1] += tx.amount;
    }

    return List.generate(
      daysInMonth,
      (i) => TrendPoint(label: '${i + 1}', amount: amounts[i]),
    );
  }

  /// Twelve monthly buckets for the selected month's year.
  List<TrendPoint> _yearTrend(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final amounts = List<double>.filled(12, 0.0);

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.year != month.year) continue;
      amounts[tx.date.month - 1] += tx.amount;
    }

    return List.generate(
      12,
      (i) => TrendPoint(label: monthLabels[i], amount: amounts[i]),
    );
  }
}
