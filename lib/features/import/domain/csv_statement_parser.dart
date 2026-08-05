import 'package:csv/csv.dart';

import 'statement_row.dart';

/// Parses CSV statement content into [StatementRow]s without assuming any
/// specific bank format — the file is treated as generic tabular data.
///
/// Columns are located heuristically by matching common header names
/// (e.g. "Date", "Description", "Withdrawal", "Deposit", "Balance") and the
/// cell values are preserved verbatim as raw strings. When no recognisable
/// header row exists, columns fall back to the positional order
/// Date, Description, Debit, Credit, Balance.
class CsvStatementParser {
  /// Field -> ordered list of common header aliases (normalised form).
  static const List<List<String>> _headerAliases = [
    [
      'date',
      'txn date',
      'transaction date',
      'value date',
      'posting date',
    ],
    [
      'description',
      'narrative',
      'particulars',
      'transaction details',
      'details',
      'remarks',
      'memo',
      'narration',
      'payee',
      'counterparty',
      'transaction',
    ],
    [
      'debit',
      'debit amount',
      'debit amt',
      'withdrawal',
      'withdrawal amount',
      'withdrawal amt',
    ],
    [
      'credit',
      'credit amount',
      'credit amt',
      'deposit',
      'deposit amount',
      'deposit amt',
    ],
    [
      'balance',
      'closing balance',
      'running balance',
      'available balance',
      'account balance',
    ],
  ];

  /// Field assignment priority: the most distinctive fields are mapped first
  /// so that ambiguous headers (e.g. "Transaction Date") are never stolen by
  /// a less specific field.
  static const List<int> _priorityOrder = [0, 2, 3, 4, 1];

  /// Decodes [content] into raw [StatementRow]s.
  ///
  /// Empty lines are skipped and cells are never type-coerced, so amounts
  /// and dates stay exactly as they appear in the file.
  List<StatementRow> parse(String content) {
    final rows = Csv(skipEmptyLines: true, dynamicTyping: false).decode(content);
    if (rows.isEmpty) return const [];

    final headerIndex = _findHeaderIndex(rows);
    final columnIndices = _mapColumns(rows, headerIndex);
    final dataStart = headerIndex != null ? headerIndex + 1 : 0;

    final statementRows = <StatementRow>[];
    for (var i = dataStart; i < rows.length; i++) {
      final cells = rows[i];
      if (_isEmptyRow(cells)) continue;
      statementRows.add(
        StatementRow(
          date: _cellAt(cells, columnIndices[0]),
          description: _cellAt(cells, columnIndices[1]),
          debit: _cellAt(cells, columnIndices[2]),
          credit: _cellAt(cells, columnIndices[3]),
          balance: _cellAt(cells, columnIndices[4]),
        ),
      );
    }
    return statementRows;
  }

  /// Locates the header row, or returns `null` when no recognisable header
  /// exists (positional fallback is then used).
  int? _findHeaderIndex(List<List<dynamic>> rows) {
    for (var i = 0; i < rows.length; i++) {
      if (_aliasMatchCount(rows[i]) >= 2) return i;
    }
    return null;
  }

  /// Maps each of the five fields to a column index in the parsed table.
  ///
  /// When [headerIndex] is `null` the positional layout
  /// Date, Description, Debit, Credit, Balance is assumed.
  List<int?> _mapColumns(List<List<dynamic>> rows, int? headerIndex) {
    if (headerIndex == null) return [0, 1, 2, 3, 4];

    final header = rows[headerIndex].map(_normalize).toList();
    final usedColumns = <int>{};
    final columnIndices = List<int?>.filled(5, null);

    for (final field in _priorityOrder) {
      int? bestColumn;
      var bestScore = -1;
      for (var column = 0; column < header.length; column++) {
        if (usedColumns.contains(column)) continue;
        final score = _matchScore(header[column], _headerAliases[field]);
        if (score > bestScore) {
          bestScore = score;
          bestColumn = column;
        }
      }
      if (bestColumn != null) {
        usedColumns.add(bestColumn);
        columnIndices[field] = bestColumn;
      }
    }
    return columnIndices;
  }

  /// How strongly a normalised header [cell] matches one of [aliases].
  ///
  /// An exact match always outranks a partial match, and longer aliases
  /// outrank shorter ones (e.g. "transaction date" beats "date").
  int _matchScore(String cell, List<String> aliases) {
    if (cell.isEmpty) return -1;
    var bestScore = -1;
    for (final alias in aliases) {
      if (cell == alias) {
        final score = 1000 + alias.length;
        if (score > bestScore) bestScore = score;
      } else if (cell.contains(alias)) {
        if (alias.length > bestScore) bestScore = alias.length;
      }
    }
    return bestScore;
  }

  /// Number of header aliases appearing in [row] (used to spot a header row).
  int _aliasMatchCount(List<dynamic> row) {
    final cells = row.map(_normalize).toList();
    var matches = 0;
    for (final cell in cells) {
      for (final aliases in _headerAliases) {
        if (_matchScore(cell, aliases) > 0) {
          matches++;
          break;
        }
      }
    }
    return matches;
  }

  bool _isEmptyRow(List<dynamic> cells) {
    return cells.every((cell) => _normalize(cell).isEmpty);
  }

  String _cellAt(List<dynamic> cells, int? index) {
    if (index == null || index >= cells.length) return '';
    return cells[index].toString().trim();
  }

  String _normalize(dynamic value) {
    return value.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
