import 'package:flutter/widgets.dart';
import 'package:spendwise/core/utils/aggregations.dart' as aggregations;

/// Aggregated spending for a single category within the selected month.
///
/// Produced by [StatisticsService.computeCategoryBreakdown] and consumed by
/// both the Expense Breakdown legend and the Top Categories list so both
/// sections always render identical names, icons, colors, and percentages.
class CategorySpending {
  final String categoryId;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final int count;
  final double percentage;

  const CategorySpending({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.count,
    required this.percentage,
  });
}

/// A single bucket in the Spending Trend series.
///
/// Produced by [StatisticsService.computeTrendSeries]. [label] is the axis
/// label for the bucket (weekday, day-of-month, or month abbreviation) and
/// [amount] is the total expense accumulated for that bucket.
class TrendPoint {
  final String label;
  final double amount;

  const TrendPoint({
    required this.label,
    required this.amount,
  });
}

/// Transaction activity totals for the selected month.
///
/// Produced by [StatisticsService.computeMonthActivity] and consumed by the
/// Financial Insights card.
class MonthActivity {
  final int totalTransactions;
  final int expenseCount;
  final double averageExpense;

  const MonthActivity({
    required this.totalTransactions,
    required this.expenseCount,
    required this.averageExpense,
  });
}

/// A single metric compared between the selected month and the previous
/// calendar month.
///
/// [percentChange] is null when [previous] is zero (a percentage cannot be
/// meaningfully computed without division by zero). Produced by
/// [StatisticsService.computeMonthComparison].
class MonthDelta {
  final double current;
  final double previous;
  final double? percentChange;

  const MonthDelta({
    required this.current,
    required this.previous,
    required this.percentChange,
  });

  /// Initializes an empty/zero comparison state used before the transactions
  /// stream emits its first value.
  const MonthDelta.zero()
      : current = 0.0,
        previous = 0.0,
        percentChange = 0.0;
}

/// Income, expense, and savings compared between the selected month and the
/// previous calendar month.
///
/// Produced by [StatisticsService.computeMonthComparison] and consumed by the
/// Financial Insights card.
class MonthComparison {
  final MonthDelta income;
  final MonthDelta expense;
  final MonthDelta savings;

  const MonthComparison({
    required this.income,
    required this.expense,
    required this.savings,
  });

  /// Initializes an empty/zero comparison state used before the transactions
  /// stream emits its first value.
  const MonthComparison.zero()
      : income = const MonthDelta.zero(),
        expense = const MonthDelta.zero(),
        savings = const MonthDelta.zero();
}

class StatisticsSummaryModel {
  final double income;
  final double expense;
  final double savings;

  const StatisticsSummaryModel({
    required this.income,
    required this.expense,
    required this.savings,
  });

  /// Factory constructor to initialize an empty/zero state representation.
  /// This is used as initial data for the Statistics screen while the
  /// transactions stream has not emitted yet.
  factory StatisticsSummaryModel.zero() {
    return const StatisticsSummaryModel(
      income: 0.0,
      expense: 0.0,
      savings: 0.0,
    );
  }

  /// Facilitates safe state cloning without mutating original models.
  StatisticsSummaryModel copyWith({
    double? income,
    double? expense,
    double? savings,
  }) {
    return StatisticsSummaryModel(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      savings: savings ?? this.savings,
    );
  }

  /// Savings as a percentage of income for the period.
  ///
  /// Delegates to the shared [aggregations.savingsRate] helper.
  double get savingsRate => aggregations.savingsRate(savings, income);
}
