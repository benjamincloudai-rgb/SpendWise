import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'statement_column_mapper.dart';
import 'statement_row.dart';

/// Parses Microsoft Excel (`.xlsx`) statement content into [StatementRow]s
/// without assuming any specific bank format.
///
/// An `.xlsx` workbook is a ZIP archive of XML parts, so the first worksheet
/// is located through `xl/workbook.xml` and `xl/_rels/workbook.xml.rels`, cell
/// text is resolved through `xl/sharedStrings.xml`, and date-styled numeric
/// cells are detected through `xl/styles.xml`. The worksheet's rows are
/// flattened into a plain table of raw strings and then fed through the same
/// header-based column mapping as the CSV parser ([StatementColumnMapper]).
class XlsxStatementParser {
  /// Built-in Excel `numFmtId`s that render a number as a date/date-time.
  static const Set<int> _builtInDateFormats = {
    14,
    15,
    16,
    17,
    22,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    45,
    46,
    47,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
  };

  /// Markers that identify a Bank of Baroda export (same detection as the CSV
  /// parser: the bank's name, domain or IFSC code).
  static final RegExp _bobMarkers = RegExp(
    r'bank\s*of\s*baroda|bankofbaroda|barbomarmar',
    caseSensitive: false,
  );
  static final RegExp _bobDate = RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}');
  static final RegExp _bobDateOnly = RegExp(r'^\d{2}[/-]\d{2}[/-]\d{4}$');
  static final RegExp _bobBalance = RegExp(
    r'([\d,]+\.\d{2})\s*Cr\b',
    caseSensitive: false,
  );
  static final RegExp _bobNumber = RegExp(r'\b\d+(?:\.\d+)?\b');
  static final RegExp _bobCellWhitespace = RegExp(r'\s+');

  final StatementColumnMapper _mapper;

  XlsxStatementParser({StatementColumnMapper? mapper})
    : _mapper = mapper ?? StatementColumnMapper();

  /// Parses the first worksheet of [bytes] into raw [StatementRow]s.
  ///
  /// Throws an [XlsxFormatException] when the workbook is missing required
  /// parts or has no readable worksheet, so the caller can surface a friendly
  /// error.
  List<StatementRow> parse(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final workbook = _parsePart(archive, 'xl/workbook.xml');
    final rels = _parsePart(archive, 'xl/_rels/workbook.xml.rels');
    final worksheetPath = _worksheetPath(workbook, rels);
    final worksheet = _parsePart(archive, worksheetPath);
    final sharedStrings = _parseSharedStrings(archive);
    final dateStyleIds = _parseDateStyleIds(archive);

    final table = _extractTable(worksheet, sharedStrings, dateStyleIds);
    if (table.isEmpty) return const [];

    // Bank of Baroda statement exports are single-column-ish dumps with no
    // usable header row — detect them first and parse them separately (same
    // strategy as the CSV parser).
    if (_isBankOfBaroda(table)) {
      return _parseBankOfBaroda(table);
    }

    final headerIndex = _mapper.findHeaderIndex(table);
    final columnIndices = _mapper.mapColumns(table, headerIndex);
    final dataStart = headerIndex != null ? headerIndex + 1 : 0;

    final statementRows = <StatementRow>[];
    for (var i = dataStart; i < table.length; i++) {
      final cells = table[i];
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
  // -------------------------------------------------------------------------
  // Bank of Baroda statement exports
  // -------------------------------------------------------------------------
  //
  // BoB e-statements are single-column-ish dumps: several pages of account
  // summary precede the transaction table, there is no header row, and the
  // transaction rows use wildly different column layouts. The layout is
  // therefore ignored entirely — cells are joined into one text blob per row
  // and the date, description, amount and running balance are pulled out of
  // that text. Debit/credit direction is inferred from the running balance
  // delta, since BoB prints both debits and credits with no sign.

  bool _isBankOfBaroda(List<List<String>> table) {
    final content = table.map((row) => row.join(' ')).join('\n');
    if (_bobMarkers.hasMatch(content)) return true;

    // Secondary heuristic for exports without the bank footer: a header-less
    // statement with an Opening/Closing Balance row and UPI transactions.
    if (_mapper.findHeaderIndex(table) != null) return false;
    final lower = content.toLowerCase();
    return lower.contains('opening balance') &&
        lower.contains('closing balance') &&
        lower.contains('upi');
  }

  List<StatementRow> _parseBankOfBaroda(List<List<String>> rows) {
    final statementRows = <StatementRow>[];
    double? previousBalance;
    _BobTxn? pending;

    for (final row in rows) {
      final blob = _joinBobCells(row);
      if (blob.isEmpty) continue;

      final trimmed = blob.trim();
      final lower = trimmed.toLowerCase();

      // BoB occasionally prints the date on the row after the description and
      // amount (a wrapping artifact). Such date-only rows are folded into the
      // pending transaction.
      if (_bobDateOnly.hasMatch(trimmed)) {
        if (pending != null) {
          statementRows.add(
            _emitBobRow(pending, previousBalance, _normalizeBobDate(trimmed)),
          );
          previousBalance = pending.balance;
          pending = null;
        }
        continue;
      }

      final balance = _parseBobBalance(trimmed);
      if (balance == null) continue;

      if (lower.contains('opening balance')) {
        previousBalance = balance;
        continue;
      }
      if (lower.contains('closing balance')) continue;

      final txn = _extractBobTxn(trimmed, balance);
      if (txn == null) continue;

      if (txn.date.isNotEmpty) {
        statementRows.add(_emitBobRow(txn, previousBalance, null));
        previousBalance = txn.balance;
      } else {
        pending = txn;
      }
    }

    if (pending != null) {
      statementRows.add(_emitBobRow(pending, previousBalance, null));
    }

    return statementRows;
  }

  /// Joins the non-empty cells of one row into a single text blob, collapsing
  /// all internal whitespace (including newlines inside shared strings).
  String _joinBobCells(List<String> row) {
    final parts = <String>[];
    for (final cell in row) {
      final text = cell.trim();
      if (text.isNotEmpty) parts.add(text);
    }
    return parts.join(' ').replaceAll(_bobCellWhitespace, ' ');
  }

  double? _parseBobBalance(String blob) {
    final matches = _bobBalance.allMatches(blob);
    if (matches.isEmpty) return null;
    return _toDouble(matches.last.group(1)!);
  }

  _BobTxn? _extractBobTxn(String blob, double balance) {
    final dateMatch = _bobDate.firstMatch(blob);
    final balanceMatches = _bobBalance.allMatches(blob);
    if (balanceMatches.isEmpty) return null;
    final balanceMatch = balanceMatches.last;

    // The printed amount is the last standalone number before the balance.
    double? amount;
    var amountStart = balanceMatch.start;
    final numbers = _bobNumber.allMatches(
      blob.substring(0, balanceMatch.start),
    );
    if (numbers.isNotEmpty) {
      final lastNumber = numbers.last;
      amount = _toDouble(lastNumber.group(0)!);
      amountStart = lastNumber.start;
    }

    final date = dateMatch == null
        ? ''
        : _normalizeBobDate(dateMatch.group(0)!);
    final description = blob
        .substring(dateMatch?.end ?? 0, amountStart)
        .trim()
        .replaceAll(_bobCellWhitespace, ' ');

    return _BobTxn(
      date: date,
      description: description,
      amount: amount,
      balance: balance,
    );
  }

  StatementRow _emitBobRow(
    _BobTxn txn,
    double? previousBalance,
    String? dateOverride,
  ) {
    final date = dateOverride ?? txn.date;
    var isCredit = false;
    var amount = txn.amount;

    if (previousBalance != null) {
      final delta = txn.balance - previousBalance;
      if (delta.abs() > 0.0001) {
        isCredit = delta > 0;
        if (txn.amount != null && (txn.amount! - delta.abs()).abs() > 0.01) {
          // The printed amount disagrees with the balance math — trust the
          // running balance.
          amount = delta.abs();
        } else {
          amount ??= delta.abs();
        }
      }
    }

    final amountText = amount == null ? '' : amount.toStringAsFixed(2);
    return StatementRow(
      date: date,
      description: txn.description,
      debit: isCredit ? '' : amountText,
      credit: isCredit ? amountText : '',
      balance: txn.balance.toStringAsFixed(2),
    );
  }

  /// BoB uses both `DD-MM-YYYY` and `MM/DD/YYYY` in the same file; both are
  /// normalised to `DD-MM-YYYY` so the preview shows one consistent format.
  String _normalizeBobDate(String raw) {
    final match = RegExp(r'(\d{2})([/-])(\d{2})([/-])(\d{4})').firstMatch(raw);
    if (match == null) return raw;
    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(3)!);
    final year = match.group(5)!;
    final isSlashFormat = match.group(2) == '/';
    final day = isSlashFormat ? second : first;
    final month = isSlashFormat ? first : second;
    return '${day.toString().padLeft(2, '0')}-'
        '${month.toString().padLeft(2, '0')}-$year';
  }

  double _toDouble(String value) => double.parse(value.replaceAll(',', ''));

  /// Reads the named part from [archive] and parses it as XML.
  XmlDocument _parsePart(Archive archive, String name) {
    final content = archive.find(name)?.content;
    if (content == null) {
      throw XlsxFormatException('This workbook is missing its $name part.');
    }
    return XmlDocument.parse(utf8.decode(content));
  }

  /// Resolves the first worksheet's part path from [workbook] and [rels].
  String _worksheetPath(XmlDocument workbook, XmlDocument rels) {
    final sheets = workbook.rootElement.findElements('sheets');
    if (sheets.isEmpty) {
      throw const XlsxFormatException(
        'This workbook does not contain any sheets.',
      );
    }
    final sheet = sheets.first.findElements('sheet').firstOrNull;
    if (sheet == null) {
      throw const XlsxFormatException(
        'This workbook does not contain any sheets.',
      );
    }

    final relationshipId = sheet.getAttribute('r:id');
    if (relationshipId == null) {
      throw const XlsxFormatException(
        'This workbook sheet has no relationship.',
      );
    }

    for (final relationship in rels.rootElement.findElements('Relationship')) {
      if (relationship.getAttribute('Id') != relationshipId) continue;
      final target = relationship.getAttribute('Target');
      if (target == null || target.isEmpty) {
        throw const XlsxFormatException(
          'This workbook sheet could not be located.',
        );
      }
      return target.startsWith('/') ? target.substring(1) : 'xl/$target';
    }

    throw const XlsxFormatException(
      'This workbook sheet could not be located.',
    );
  }

  /// Parses `xl/sharedStrings.xml` into the ordered shared string table.
  ///
  /// Rich text runs (`<r><t>…</t></r>`) are concatenated per entry.
  List<String> _parseSharedStrings(Archive archive) {
    final entry = archive.find('xl/sharedStrings.xml');
    if (entry == null) return const [];
    final document = XmlDocument.parse(utf8.decode(entry.content));
    return [
      for (final si in document.rootElement.findElements('si'))
        si.findAllElements('t').map((t) => t.innerText).join(),
    ];
  }

  /// Collects the style indices (`s` attribute values) that render dates.
  Set<int> _parseDateStyleIds(Archive archive) {
    final entry = archive.find('xl/styles.xml');
    if (entry == null) return const {};
    final root = XmlDocument.parse(utf8.decode(entry.content)).rootElement;

    final customDateFormatIds = <String>{};
    final numFmts = root.findElements('numFmts');
    if (numFmts.isNotEmpty) {
      for (final numFmt in numFmts.first.findElements('numFmt')) {
        final formatCode = numFmt.getAttribute('formatCode');
        final numFmtId = numFmt.getAttribute('numFmtId');
        if (numFmtId != null &&
            formatCode != null &&
            _isDateFormatCode(formatCode)) {
          customDateFormatIds.add(numFmtId);
        }
      }
    }

    final cellXfs = root.findElements('cellXfs');
    if (cellXfs.isEmpty) return const {};

    final dateStyleIds = <int>{};
    var styleIndex = 0;
    for (final xf in cellXfs.first.findElements('xf')) {
      final numFmtId = xf.getAttribute('numFmtId');
      final parsedId = numFmtId == null ? null : int.tryParse(numFmtId);
      if (parsedId != null &&
          (_builtInDateFormats.contains(parsedId) ||
              customDateFormatIds.contains(numFmtId))) {
        dateStyleIds.add(styleIndex);
      }
      styleIndex++;
    }
    return dateStyleIds;
  }

  /// Whether a custom [formatCode] renders dates (time-only formats are not
  /// considered dates).
  bool _isDateFormatCode(String formatCode) {
    final lower = formatCode.toLowerCase();
    return lower.contains('y') || lower.contains('d');
  }

  /// Flattens the worksheet's rows into a plain table of raw strings.
  List<List<String>> _extractTable(
    XmlDocument worksheet,
    List<String> sharedStrings,
    Set<int> dateStyleIds,
  ) {
    final sheetData = worksheet.rootElement.findElements('sheetData');
    if (sheetData.isEmpty) return const [];

    final table = <List<String>>[];
    for (final row in sheetData.first.findElements('row')) {
      var rowWidth = 0;
      final values = <int, String>{};
      for (final cell in row.findElements('c')) {
        final columnIndex = _columnIndex(cell.getAttribute('r'));
        if (columnIndex == null) continue;
        values[columnIndex] = _cellText(cell, sharedStrings, dateStyleIds);
        if (columnIndex + 1 > rowWidth) rowWidth = columnIndex + 1;
      }
      if (rowWidth == 0) continue;
      final flat = List<String>.filled(rowWidth, '');
      values.forEach((index, value) => flat[index] = value);
      table.add(flat);
    }
    return table;
  }

  /// Resolves the raw display string for one cell.
  String _cellText(
    XmlElement cell,
    List<String> sharedStrings,
    Set<int> dateStyleIds,
  ) {
    final type = cell.getAttribute('t');
    final vElement = cell.findElements('v');
    final value = vElement.isEmpty ? '' : vElement.first.innerText;

    if (type == 's') {
      final index = int.tryParse(value);
      return index != null && index >= 0 && index < sharedStrings.length
          ? sharedStrings[index]
          : '';
    }
    if (type == 'inlineStr') {
      final isElement = cell.findElements('is');
      if (isElement.isEmpty) return '';
      return isElement.first
          .findAllElements('t')
          .map((t) => t.innerText)
          .join();
    }
    if (type == 'str' || type == 'b' || type == 'e') return value;

    // Plain numbers (no type, or an explicit `n`) — date-styled serials are
    // converted to a readable date so the date column is never a raw number.
    if (_isDateCell(cell, dateStyleIds)) {
      final serial = double.tryParse(value);
      return serial != null ? _formatExcelDate(serial) : value;
    }
    return value;
  }

  /// Whether a numeric cell's style renders it as a date.
  bool _isDateCell(XmlElement cell, Set<int> dateStyleIds) {
    final styleIndex = cell.getAttribute('s');
    final parsedIndex = styleIndex == null ? null : int.tryParse(styleIndex);
    return parsedIndex != null && dateStyleIds.contains(parsedIndex);
  }

  /// Converts an Excel serial date to a `DD-MM-YYYY` string (day-first, which
  /// is what the planner's date parser and the CSV normalisation use).
  String _formatExcelDate(double serial) {
    final days = serial.floor();
    if (days < 1) return '';
    final date = DateTime.utc(1899, 12, 30).add(Duration(days: days));
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Converts an Excel cell reference (`A1`, `BC12`) into a zero-based column
  /// index, or `null` when the reference is absent or malformed.
  int? _columnIndex(String? reference) {
    if (reference == null || reference.isEmpty) return null;
    var index = 0;
    for (final code in reference.codeUnits) {
      if (code < 65 || code > 90) break;
      index = index * 26 + (code - 64);
    }
    return index > 0 ? index - 1 : null;
  }
}

/// Thrown when an `.xlsx` workbook cannot be read as a statement file.
class XlsxFormatException implements Exception {
  final String message;

  const XlsxFormatException(this.message);

  @override
  String toString() => 'XlsxFormatException: $message';
}

/// A single Bank of Baroda transaction extracted from its text blob.
class _BobTxn {
  final String date;
  final String description;
  final double? amount;
  final double balance;

  const _BobTxn({
    required this.date,
    required this.description,
    this.amount,
    required this.balance,
  });
}

/// First-or-null helper for [Iterable]s.
extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
