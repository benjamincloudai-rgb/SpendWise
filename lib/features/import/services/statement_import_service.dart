import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/csv_statement_parser.dart';
import '../domain/pdf_statement_parser.dart';
import '../domain/pdf_text_extractor.dart';
import '../domain/statement_classifier.dart';
import '../domain/statement_row_info.dart';
import '../domain/xlsx_statement_parser.dart';

/// Orchestrates the statement import flow: opens the native file picker, reads
/// the selected file's bytes, parses them into raw [StatementRow]s, and
/// classifies each row into an enriched [StatementRowInfo] for the preview.
///
/// Nothing is persisted and no Firestore logic is performed here — parsing is
/// delegated to [CsvStatementParser], [XlsxStatementParser] or
/// [PdfStatementParser] depending on the file type, classification to
/// [StatementClassifier], and the UI only ever sees a [StatementImportResult].
class StatementImportService {
  final CsvStatementParser _csvParser;
  final XlsxStatementParser _excelParser;
  final PdfStatementParser _pdfParser;
  final StatementClassifier _classifier;

  StatementImportService({
    CsvStatementParser? csvParser,
    XlsxStatementParser? excelParser,
    PdfStatementParser? pdfParser,
    StatementClassifier? classifier,
  })  : _csvParser = csvParser ?? CsvStatementParser(),
        _excelParser = excelParser ?? XlsxStatementParser(),
        _pdfParser = pdfParser ?? PdfStatementParser(),
        _classifier = classifier ?? StatementClassifier();

  /// Runs one CSV import attempt and returns a result that is either a
  /// success (with parsed rows), a user cancellation, or a friendly failure.
  Future<StatementImportResult> importCsv() async {
    final FilePickerResult? pickResult;
    try {
      pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not open the file picker. Please try again.',
      );
    }

    if (pickResult == null) {
      return const StatementImportResult.cancelled();
    }

    final bytes = pickResult.files.single.bytes;
    if (bytes == null) {
      return const StatementImportResult.failed(
        'Could not read the selected file. Please try again.',
      );
    }

    final String content;
    try {
      content = _decode(bytes);
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not read the selected file. Please try again.',
      );
    }

    try {
      final rows = _csvParser.parse(content);
      if (rows.isEmpty) {
        return const StatementImportResult.failed(
          'No transaction rows were found in this CSV file.',
        );
      }
      final classified = rows.map(_classifier.classify).toList();
      return StatementImportResult.success(classified);
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not parse this CSV file. Please choose a valid .csv file.',
      );
    }
  }

  /// Runs one Excel import attempt and returns a result that is either a
  /// success (with parsed rows), a user cancellation, or a friendly failure.
  Future<StatementImportResult> importExcel() async {
    final FilePickerResult? pickResult;
    try {
      pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not open the file picker. Please try again.',
      );
    }

    if (pickResult == null) {
      return const StatementImportResult.cancelled();
    }

    final bytes = pickResult.files.single.bytes;
    if (bytes == null) {
      return const StatementImportResult.failed(
        'Could not read the selected file. Please try again.',
      );
    }

    try {
      final rows = _excelParser.parse(bytes);
      if (rows.isEmpty) {
        return const StatementImportResult.failed(
          'No transaction rows were found in this Excel file.',
        );
      }
      final classified = rows.map(_classifier.classify).toList();
      return StatementImportResult.success(classified);
    } on XlsxFormatException catch (error) {
      return StatementImportResult.failed(error.message);
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not parse this Excel file. Please choose a valid .xlsx file.',
      );
    }
  }

  /// Runs one PDF import attempt and returns a result that is either a
  /// success (with parsed rows), a user cancellation, or a friendly failure.
  ///
  /// [passwordProvider] is forwarded to the pdfrx layer so a password-protected
  /// PDF can prompt the user for its password. Dismissing that prompt yields a
  /// silent [StatementImportResult.cancelled], mirroring the file-picker
  /// cancel behaviour.
  Future<StatementImportResult> importPdf({
    FutureOr<String?> Function()? passwordProvider,
  }) async {
    final FilePickerResult? pickResult;
    try {
      pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not open the file picker. Please try again.',
      );
    }

    if (pickResult == null) {
      return const StatementImportResult.cancelled();
    }

    final bytes = pickResult.files.single.bytes;
    if (bytes == null) {
      return const StatementImportResult.failed(
        'Could not read the selected file. Please try again.',
      );
    }

    try {
      final rows = await _pdfParser.parse(
        bytes,
        passwordProvider: passwordProvider,
      );
      if (rows.isEmpty) {
        return const StatementImportResult.failed(
          'No transaction rows were found in this PDF file.',
        );
      }
      final classified = rows.map(_classifier.classify).toList();
      return StatementImportResult.success(classified);
    } on PdfImportCancellationException {
      return const StatementImportResult.cancelled();
    } on PdfFormatException catch (error) {
      return StatementImportResult.failed(error.message);
    } catch (_) {
      return const StatementImportResult.failed(
        'Could not parse this PDF file. Please choose a valid .pdf file.',
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

/// The outcome of a single statement import attempt.
class StatementImportResult {
  final List<StatementRowInfo> rows;
  final bool cancelled;
  final String? error;

  const StatementImportResult._(this.rows, {this.cancelled = false, this.error});

  const StatementImportResult.success(List<StatementRowInfo> rows)
      : this._(rows);

  const StatementImportResult.cancelled()
      : this._(const [], cancelled: true);

  const StatementImportResult.failed(String error)
      : this._(const [], error: error);

  bool get isSuccess => !cancelled && error == null;
}
