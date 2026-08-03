class DashboardSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double currentBalance;
  final double savings;

  const DashboardSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalance,
    required this.savings,
  });

  /// Factory constructor to initialize an empty/zero state representation.
  /// This is used as initial data for the StreamBuilder while waiting for the stream to emit.
  factory DashboardSummaryModel.zero() {
    return const DashboardSummaryModel(
      totalIncome: 0.0,
      totalExpense: 0.0,
      currentBalance: 0.0,
      savings: 0.0,
    );
  }

  /// Facilitates safe state cloning without mutating original models.
  DashboardSummaryModel copyWith({
    double? totalIncome,
    double? totalExpense,
    double? currentBalance,
    double? savings,
  }) {
    return DashboardSummaryModel(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      currentBalance: currentBalance ?? this.currentBalance,
      savings: savings ?? this.savings,
    );
  }
}
