import 'package:spendwise/core/utils/aggregations.dart';
import 'package:spendwise/models/transaction_model.dart';

/// Date scope options for the transaction filter.
enum TransactionDateFilter { all, currentMonth, custom }

/// Immutable, value-style transaction filter state.
///
/// Every field is optional; active filters combine with AND logic. Filtering
/// itself is performed locally by [filterTransactions] over the already-loaded
/// transaction stream, so no additional Firestore queries are introduced.
class TransactionFilters {
  /// Restricts to a single transaction type; null means all types.
  final TransactionType? type;

  /// Restricts to a single category identifier; null means all categories.
  ///
  /// Matches against `TransactionModel.categoryId` exactly, which is the same
  /// identifier used by the transaction cards.
  final String? selectedCategory;

  /// Date scope for the filter.
  final TransactionDateFilter dateFilter;

  /// Inclusive custom range start (only meaningful for [TransactionDateFilter.custom]).
  final DateTime? customStart;

  /// Inclusive custom range end (only meaningful for [TransactionDateFilter.custom]).
  final DateTime? customEnd;

  /// Lower bound on the numeric amount; null means no lower bound.
  final double? minAmount;

  /// Upper bound on the numeric amount; null means no upper bound.
  final double? maxAmount;

  const TransactionFilters({
    this.type,
    this.selectedCategory,
    this.dateFilter = TransactionDateFilter.all,
    this.customStart,
    this.customEnd,
    this.minAmount,
    this.maxAmount,
  });

  /// Whether any filter (type, category, date, or amount) is applied.
  bool get isActive =>
      type != null ||
      selectedCategory != null ||
      dateFilter != TransactionDateFilter.all ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilters copyWith({
    TransactionType? type,
    bool clearType = false,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    TransactionDateFilter? dateFilter,
    DateTime? customStart,
    bool clearCustomStart = false,
    DateTime? customEnd,
    bool clearCustomEnd = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
  }) {
    return TransactionFilters(
      type: clearType ? null : type ?? this.type,
      selectedCategory: clearSelectedCategory
          ? null
          : selectedCategory ?? this.selectedCategory,
      dateFilter: dateFilter ?? this.dateFilter,
      customStart: clearCustomStart ? null : customStart ?? this.customStart,
      customEnd: clearCustomEnd ? null : customEnd ?? this.customEnd,
      minAmount: clearMinAmount ? null : minAmount ?? this.minAmount,
      maxAmount: clearMaxAmount ? null : maxAmount ?? this.maxAmount,
    );
  }
}

/// Applies [filters] and the [searchQuery] to [transactions] locally.
///
/// Deterministic and side-effect free: the original [transactions] list is
/// never mutated and its ordering is preserved. Active filters combine with
/// AND logic, then the existing search query (lowercased substring against
/// category, note, or amount string) is applied last, matching the original
/// Transactions screen behaviour.
List<TransactionModel> filterTransactions(
  List<TransactionModel> transactions,
  TransactionFilters filters,
  String searchQuery,
) {
  final query = searchQuery.trim().toLowerCase();
  final double? minAmount = filters.minAmount;
  final double? maxAmount = filters.maxAmount;
  final DateTime? customStart = filters.customStart;
  final DateTime? customEnd = filters.customEnd;
  final bool hasCustomRange =
      filters.dateFilter == TransactionDateFilter.custom &&
      customStart != null &&
      customEnd != null;

  return transactions.where((tx) {
    if (filters.type != null && tx.type != filters.type) {
      return false;
    }

    if (filters.selectedCategory != null &&
        tx.categoryId != filters.selectedCategory) {
      return false;
    }

    if (filters.dateFilter == TransactionDateFilter.currentMonth) {
      if (!isInMonth(tx, DateTime.now())) {
        return false;
      }
    } else if (hasCustomRange) {
      final startDay = DateTime(
        customStart.year,
        customStart.month,
        customStart.day,
      );
      final endDay = DateTime(customEnd.year, customEnd.month, customEnd.day);
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (txDay.isBefore(startDay) || txDay.isAfter(endDay)) {
        return false;
      }
    }

    if (minAmount != null && tx.amount < minAmount) {
      return false;
    }
    if (maxAmount != null && tx.amount > maxAmount) {
      return false;
    }

    if (query.isNotEmpty) {
      final categoryMatch = tx.categoryId.toLowerCase().contains(query);
      final noteMatch = tx.note?.toLowerCase().contains(query) ?? false;
      final amountMatch = tx.amount.toString().contains(query);
      return categoryMatch || noteMatch || amountMatch;
    }

    return true;
  }).toList();
}
