import 'package:spendwise/models/dashboard_summary_model.dart';
import 'package:spendwise/models/transaction_model.dart';
import 'package:spendwise/services/transaction_service.dart';

class DashboardService {
  final TransactionService _transactionService = TransactionService();

  /// Listens to the raw transactions stream, aggregates metrics,
  /// and exposes a reactive stream of computed DashboardSummaryModel.
  Stream<DashboardSummaryModel> getDashboardSummary() {
    return _transactionService.getTransactions().map((transactions) {
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var tx in transactions) {
        if (tx.type == TransactionType.income) {
          totalIncome += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          totalExpense += tx.amount;
        }
      }

      // Calculations reflecting the business logic requirements
      final double currentBalance = totalIncome - totalExpense;
      final double savings = totalIncome - totalExpense; // Income - Expenses

      return DashboardSummaryModel(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        currentBalance: currentBalance,
        savings: savings,
      );
    });
  }
}
