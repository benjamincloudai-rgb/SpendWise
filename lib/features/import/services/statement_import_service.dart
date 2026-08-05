import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/csv_statement_parser.dart';
import '../domain/statement_classifier.dart';
import '../domain/statement_row_info.dart';

/// Orchestrates the CSV import flow: opens the native file picker, reads the
/// selected file's bytes, parses them into raw [StatementRow]s, and classifies
/// each row into an enriched [StatementRowInfo] for the preview.
///
/// Nothing is persisted and no Firestore logic is performed here — parsing is
/// delegated to [CsvStatementParser], classification to
/// [StatementClassifier], and the UI only ever sees an [ImportCsvResult].
class StatementImportService {
  final CsvStatementParser _parser;
  final StatementClassifier _classifier;

  StatementImportService({
    CsvStatementParser? parser,
    StatementClassifier? classifier,
  })  : _parser = parser ?? CsvStatementParser(),
        _classifier = classifier ?? StatementClassifier();

  /// Runs one CSV import attempt and returns a result that is either a
  /// success (with parsed rows), a user cancellation, or a friendly failure.
  Future<ImportCsvResult> importCsv() async {
    final FilePickerResult? pickResult;
    try {
      pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      return const ImportCsvResult.failed(
        'Could not open the file picker. Please try again.',
      );
    }

    if (pickResult == null) {
      return const ImportCsvResult.cancelled();
    }

    final bytes = pickResult.files.single.bytes;
    if (bytes == null) {
      return const ImportCsvResult.failed(
        'Could not read the selected file. Please try again.',
      );
    }

    final String content;
    try {
      content = _decode(bytes);
    } catch (_) {
      return const ImportCsvResult.failed(
        'Could not read the selected file. Please try again.',
      );
    }

    try {
      final rows = _parser.parse(content);
      if (rows.isEmpty) {
        return const ImportCsvResult.failed(
          'No transaction rows were found in this CSV file.',
        );
      }
      final classified = rows.map(_classifier.classify).toList();
      return ImportCsvResult.success(classified);
    } catch (_) {
      return const ImportCsvResult.failed(
        'Could not parse this CSV file. Please choose a valid .csv file.',
      );
    }
  }

  /// Decodes file bytes as UTF-8 (stripping any byte-order mark) and falls
  /// back to Latin-1 for legacy spreadsheet exports.
  String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes).replaceFirst('\uFEFF', '');
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}

/// The outcome of a single CSV import attempt.
class ImportCsvResult {
  final List<StatementRowInfo> rows;
  final bool cancelled;
  final String? error;

  const ImportCsvResult._(this.rows, {this.cancelled = false, this.error});

  const ImportCsvResult.success(List<StatementRowInfo> rows) : this._(rows);

  const ImportCsvResult.cancelled() : this._(const [], cancelled: true);

  const ImportCsvResult.failed(String error) : this._(const [], error: error);

  bool get isSuccess => !cancelled && error == null;
}
