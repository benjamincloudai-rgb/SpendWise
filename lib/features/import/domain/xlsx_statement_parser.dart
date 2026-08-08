import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'bank_of_baroda_parser.dart';
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

  final StatementColumnMapper _mapper;
  final BankOfBarodaParser _bankOfBaroda = BankOfBarodaParser();

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
    final content = table.map((row) => row.join(' ')).join('\n');
    if (_bankOfBaroda.isBankOfBaroda(content, table)) {
      return _bankOfBaroda.parse(table);
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
  // XML / worksheet reading
  // -------------------------------------------------------------------------

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

/// First-or-null helper for [Iterable]s.
extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
