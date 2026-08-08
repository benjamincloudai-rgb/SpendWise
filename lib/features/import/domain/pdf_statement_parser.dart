import 'dart:async';
import 'dart:typed_data';

import 'bank_of_baroda_parser.dart';
import 'pdf_text_extractor.dart';
import 'statement_column_mapper.dart';
import 'statement_row.dart';

/// Thrown when a PDF cannot be parsed as a statement.
class PdfFormatException implements Exception {
  final String message;

  const PdfFormatException(this.message);

  @override
  String toString() => 'PdfFormatException: $message';
}

/// Parses a text-based PDF statement into [StatementRow]s.
///
/// Text extraction is delegated to [PdfTextExtractor] (the only pdfrx-aware
/// component); this class is pure Dart so its layout and parsing logic can be
/// unit tested with plain text fixtures.
///
/// Bank of Baroda PDFs are detected first and handled by the shared
/// [BankOfBarodaParser]; every other file goes through the generic
/// header-based path ([StatementColumnMapper]), mirroring the CSV/XLSX
/// parsers.
class PdfStatementParser {
  PdfStatementParser({
    PdfTextExtractor? extractor,
    StatementColumnMapper? mapper,
    BankOfBarodaParser? bankOfBarodaParser,
  })  : _extractor = extractor ?? PdfTextExtractor(),
        _mapper = mapper ?? StatementColumnMapper(),
        _bankOfBaroda = bankOfBarodaParser ?? BankOfBarodaParser();

  final PdfTextExtractor _extractor;
  final StatementColumnMapper _mapper;
  final BankOfBarodaParser _bankOfBaroda;

  /// Parses [bytes] into raw [StatementRow]s.
  ///
  /// Encrypted PDFs prompt through [passwordProvider] (forwarded to the
  /// extractor) so password-protected statements unlock interactively.
  ///
  /// Throws a [PdfFormatException] with a user-friendly message when the PDF is
  /// unreadable or contains no extractable text (e.g. scanned/image-based
  /// files), and rethrows [PdfImportCancellationException] when the user
  /// dismisses the password prompt.
  Future<List<StatementRow>> parse(
    Uint8List bytes, {
    FutureOr<String?> Function()? passwordProvider,
  }) async {
    final String content;
    try {
      content = await _extractor.extractText(
        bytes,
        passwordProvider: passwordProvider,
      );
    } on PdfTextExtractionException catch (e) {
      throw PdfFormatException(e.message);
    }

    if (content.trim().isEmpty) {
      throw const PdfFormatException(
        'This PDF contains no extractable text.\n\n'
        'It appears to be a scanned, printed, or flattened PDF.\n\n'
        'SpendWise Version 1 supports text-based PDF statements only.\n\n'
        'Please download the original statement from your bank or import '
        'CSV/XLSX instead.',
      );
    }

    final table = _linesToTable(content);

    if (_bankOfBaroda.isBankOfBaroda(content, table)) {
      return _bankOfBaroda.parse(table);
    }

    final headerIndex = _mapper.findHeaderIndex(table);
    final columnIndices = _mapper.mapColumns(table, headerIndex);
    final dataStart = headerIndex != null ? headerIndex + 1 : 0;
    final trailingCount = columnIndices
        .sublist(2)
        .where((index) => index != null)
        .length;

    final statementRows = <StatementRow>[];
    for (var i = dataStart; i < table.length; i++) {
      final cells = _normalizeRow(table[i], trailingCount);
      if (_mapper.isEmptyRow(cells)) continue;
      statementRows.add(
        StatementRow(
          date: _mapper.cellAt(cells, columnIndices[0]),
          description: _mapper.cellAt(cells, columnIndices[1]),
          debit: _mapper.cellAt(cells, columnIndices[2]),
          credit: _mapper.cellAt(cells, columnIndices[3]),
          balance: _mapper.cellAt(cells, columnIndices[4]),
        ),
      );
    }
    return statementRows;
  }

  /// Reassembles a tokenized line into proper columns.
  ///
  /// A PDF text layer collapses column spacing, so a row like
  /// `18-06-2024 Cafe Mocha 450.5 0 12345.6` arrives as six tokens. The first
  /// token stays the leading column (the date), the last [trailingCount]
  /// tokens stay the amount columns, and every token in between belongs to the
  /// variable-width description.
  List<String> _normalizeRow(List<String> cells, int trailingCount) {
    if (cells.length <= trailingCount + 1) return cells;
    final description = cells.sublist(1, cells.length - trailingCount).join(' ');
    return [
      cells[0],
      description,
      ...cells.sublist(cells.length - trailingCount),
    ];
  }

  /// Flattens the extracted text into a plain table of whitespace-separated
  /// cells, one row per physical line — the same table shape the CSV/XLSX
  /// parsers feed into the column mapper and BoB parser.
  List<List<String>> _linesToTable(String content) {
    final table = <List<String>>[];
    for (final line in content.split('\n')) {
      final cells = line
          .split(RegExp(r'\s+'))
          .where((cell) => cell.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) table.add(cells);
    }
    return table;
  }
}
