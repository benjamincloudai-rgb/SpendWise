import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart' as models;
import 'merchant_categorizer.dart';
import 'statement_row_info.dart';
import 'transaction_type.dart';

/// Pure planning logic for a statement import.
///
/// Decides which preview rows become transactions and which are skipped as
/// duplicates. No Firestore access happens here — [plan] works from the
/// existing transactions and categories that the caller already loaded, so
/// the result can be inspected and written out separately.
class StatementImportPlanner {
  /// Plans the import for [rows] against [existing] transactions.
  ///
  /// Every duplicate is detected up front: a fingerprint built from
  /// `normalizedDate + amount + description + transactionType` is matched
  /// against the existing transactions, and also against rows already planned
  /// in this file, so re-importing a statement never creates duplicates.
  ///
  /// Rows that are not importable (unknown type, missing amount, or an
  /// unparseable date) are ignored.
  StatementImportPlan plan({
    required List<models.TransactionModel> existing,
    required List<CategoryModel> categories,
    required List<StatementRowInfo> rows,
  }) {
    final existingKeys = existing
        .map(_transactionFingerprint)
        .whereType<String>()
        .toSet();

    final categoryNameByKey = <String, String>{
      for (final category in categories)
        category.name.trim().toLowerCase(): category.name,
    };

    final planned = <models.TransactionModel>[];
    var duplicates = 0;
    final seenKeys = <String>{};

    for (final info in rows) {
      final date = _parseStatementDate(info.row.date);
      final amount = info.amount;
      if (date == null || amount == null || info.isUnknown) continue;

      // The persisted description (note) is the classifier's merchant, so the
      // fingerprint uses the same value that will be stored — this keeps
      // duplicate detection consistent across imports.
      final key = _fingerprint(date, amount, info.merchant, info.type);
      if (existingKeys.contains(key) || seenKeys.contains(key)) {
        duplicates++;
        continue;
      }

      final categoryName =
          categoryNameByKey[info.category.trim().toLowerCase()] ??
              MerchantCategorizer.others;
      final note = info.merchant.trim();

      planned.add(
        models.TransactionModel(
          id: '',
          amount: amount,
          categoryId: categoryName,
          note: note.isEmpty ? null : note,
          type: info.isIncome
              ? models.TransactionType.income
              : models.TransactionType.expense,
          source: models.TransactionSource.bankImport,
          date: date,
          createdAt: DateTime.now(),
        ),
      );

      seenKeys.add(key);
    }

    return StatementImportPlan(transactions: planned, duplicates: duplicates);
  }

  /// Fingerprint for an already-persisted transaction, mirroring the value
  /// stored by [plan] (description = note).
  String? _transactionFingerprint(models.TransactionModel transaction) {
    final type = transaction.type == models.TransactionType.income
        ? TransactionType.income
        : TransactionType.expense;
    return _fingerprint(
      transaction.date,
      transaction.amount,
      transaction.note ?? '',
      type,
    );
  }

  /// `normalizedDate | amount | description | transactionType`.
  String _fingerprint(
    DateTime date,
    double amount,
    String description,
    TransactionType type,
  ) {
    final descriptionKey = description
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    return '${_dateKey(date)}|${amount.toStringAsFixed(2)}|'
        '$descriptionKey|${type.name}';
  }

  /// Calendar date key (`yyyy-MM-dd`) so fingerprints are unaffected by the
  /// exact time-of-day a transaction was stored.
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Parses the raw statement date string (already normalised to `DD-MM-YYYY`
  /// for Bank of Baroda exports) into a [DateTime], or `null` when the value
  /// is not a recognised date.
  DateTime? _parseStatementDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{1,4})$',
    ).firstMatch(trimmed);
    if (match == null) return null;

    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    final third = int.parse(match.group(3)!);

    late final int year;
    late final int month;
    late final int day;
    if (third >= 1000) {
      year = third;
      if (first > 12) {
        day = first;
        month = second;
      } else if (second > 12) {
        month = first;
        day = second;
      } else {
        // Ambiguous `dd-mm-yyyy`/`mm-dd-yyyy` — default to day-first, which is
        // what Bank of Baroda exports use.
        day = first;
        month = second;
      }
    } else if (first >= 1000) {
      year = first;
      month = second;
      day = third;
    } else {
      return null;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
}

/// The outcome of one [StatementImportPlanner.plan] call.
class StatementImportPlan {
  final List<models.TransactionModel> transactions;
  final int duplicates;

  const StatementImportPlan({
    required this.transactions,
    required this.duplicates,
  });

  int get imported => transactions.length;
}
