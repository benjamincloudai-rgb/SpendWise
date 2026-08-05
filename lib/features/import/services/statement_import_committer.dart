import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../domain/statement_import_planner.dart';
import '../domain/statement_row_info.dart';

/// Writes the classified preview rows into Firestore, reusing the existing
/// [TransactionService] and [TransactionModel].
///
/// The user's existing transactions and categories are loaded exactly once and
/// handed to [StatementImportPlanner], which decides what to write and what to
/// skip as duplicates. Every planned transaction is then persisted through
/// [TransactionService.addTransaction].
class StatementImportCommitter {
  final TransactionService _transactionService;
  final CategoryService _categoryService;
  final StatementImportPlanner _planner;

  StatementImportCommitter({
    TransactionService? transactionService,
    CategoryService? categoryService,
    StatementImportPlanner? planner,
  })  : _transactionService = transactionService ?? TransactionService(),
        _categoryService = categoryService ?? CategoryService(),
        _planner = planner ?? StatementImportPlanner();

  /// Imports every importable [rows] entry and returns how many rows were
  /// actually written and how many were skipped as duplicates.
  Future<StatementImportOutcome> commit(List<StatementRowInfo> rows) async {
    final existing = await _transactionService.getTransactions().first;
    final categories = await _categoryService.getCategories().first;

    final plan = _planner.plan(
      existing: existing,
      categories: categories,
      rows: rows,
    );

    for (final transaction in plan.transactions) {
      await _transactionService.addTransaction(transaction);
    }

    return StatementImportOutcome(
      imported: plan.imported,
      duplicates: plan.duplicates,
    );
  }
}

/// The result of one statement import.
class StatementImportOutcome {
  final int imported;
  final int duplicates;

  const StatementImportOutcome({required this.imported, required this.duplicates});
}
