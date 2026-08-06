import 'dart:io';

import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/transaction_model.dart';
import '../../../services/transaction_service.dart';

/// Outcome of an export attempt, used by the UI to pick the right feedback.
enum TransactionExportStatus { success, noTransactions, failure }

/// Result returned from [TransactionExportService.export] so the caller can
/// show a confirmation or an error without inspecting exceptions.
class TransactionExportResult {
  const TransactionExportResult.success(this.count)
      : status = TransactionExportStatus.success,
        message = null;

  const TransactionExportResult.noTransactions()
      : status = TransactionExportStatus.noTransactions,
        count = 0,
        message = null;

  const TransactionExportResult.failure(this.message)
      : status = TransactionExportStatus.failure,
        count = 0;

  final TransactionExportStatus status;
  final int count;
  final String? message;
}

/// Generates a CSV export of the current user's transactions and hands the
/// file off to the platform share sheet.
///
/// Reuses [TransactionService] for the Firestore query so the export never
/// duplicates a transaction fetch, and the `csv` package for a standards
/// compliant CSV (comma delimiter, `\r\n` line endings and a UTF-8 BOM so
/// Excel, Google Sheets and LibreOffice Calc all open it correctly).
class TransactionExportService {
  TransactionExportService({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService();

  final TransactionService _transactionService;

  static const String fileName = 'spendwise_transactions.csv';

  static final Csv _csv = Csv(addBom: true);

  /// Exports every transaction belonging to the signed-in user by writing a
  /// temporary CSV file and opening the native share sheet. Never throws;
  /// problems are reported through [TransactionExportResult].
  Future<TransactionExportResult> export() async {
    try {
      final transactions = await _transactionService.getTransactions().first;

      if (transactions.isEmpty) {
        return const TransactionExportResult.noTransactions();
      }

      final file = await _writeTempFile(buildCsv(transactions));

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          title: 'SpendWise Export',
        ),
      );

      return TransactionExportResult.success(transactions.length);
    } on FileSystemException catch (e) {
      return TransactionExportResult.failure(
        'Could not save the export file. ${e.message}',
      );
    } on Exception catch (e) {
      return TransactionExportResult.failure(
        'Export failed. ${e.toString()}',
      );
    } catch (e) {
      return TransactionExportResult.failure('Export failed. $e');
    }
  }

  /// Writes [content] to a unique temporary CSV file shared by the share sheet.
  Future<File> _writeTempFile(String content) async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      '${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    await file.writeAsString(content, flush: true);
    return file;
  }

  /// Renders [transactions] as a CSV string with a header row. Exposes every
  /// model field required by the export format; no columns are invented.
  String buildCsv(List<TransactionModel> transactions) {
    final rows = <List<dynamic>>[
      ['Date', 'Type', 'Category', 'Amount', 'Note', 'Source', 'Created At'],
      for (final transaction in transactions)
        [
          _formatDate(transaction.date),
          transaction.type.name,
          transaction.categoryId,
          transaction.amount.toString(),
          transaction.note ?? '',
          transaction.source.name,
          _formatDateTime(transaction.createdAt),
        ],
    ];
    return _csv.encode(rows);
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  /// ISO date, e.g. `2026-08-07`, so spreadsheet apps parse it as a date.
  static String _formatDate(DateTime date) =>
      '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

  /// ISO date and time, e.g. `2026-08-07 14:30:05`.
  static String _formatDateTime(DateTime dateTime) =>
      '${_formatDate(dateTime)} '
      '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:'
      '${_twoDigits(dateTime.second)}';
}
