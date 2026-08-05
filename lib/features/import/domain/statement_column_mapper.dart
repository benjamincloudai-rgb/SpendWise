/// Shared column mapping for generic statement tables (CSV and Excel).
///
/// Both parsers treat the file as generic tabular data: columns are located
/// heuristically by matching common header names and every value is preserved
/// verbatim as a raw string. When no recognisable header row exists, columns
/// fall back to the positional order Date, Description, Debit, Credit, Balance.
class StatementColumnMapper {
  /// Field -> ordered list of common header aliases (normalised form).
  static const List<List<String>> headerAliases = [
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

  /// Locates the header row, or returns `null` when no recognisable header
  /// exists (positional fallback is then used).
  int? findHeaderIndex(List<List<String>> rows) {
    for (var i = 0; i < rows.length; i++) {
      if (aliasMatchCount(rows[i]) >= 2) return i;
    }
    return null;
  }

  /// Maps each of the five fields to a column index in [rows].
  ///
  /// When [headerIndex] is `null` the positional layout
  /// Date, Description, Debit, Credit, Balance is assumed.
  List<int?> mapColumns(List<List<String>> rows, int? headerIndex) {
    if (headerIndex == null) return [0, 1, 2, 3, 4];

    final header = rows[headerIndex].map(normalize).toList();
    final usedColumns = <int>{};
    final columnIndices = List<int?>.filled(5, null);

    for (final field in _priorityOrder) {
      int? bestColumn;
      var bestScore = -1;
      for (var column = 0; column < header.length; column++) {
        if (usedColumns.contains(column)) continue;
        final score = matchScore(header[column], headerAliases[field]);
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

  /// Whether [row] has no non-empty cells.
  bool isEmptyRow(List<String> row) {
    return row.every((cell) => normalize(cell).isEmpty);
  }

  /// The cell at [index], or `''` when the index is out of range.
  String cellAt(List<String> row, int? index) {
    if (index == null || index >= row.length) return '';
    return row[index];
  }

  /// Normalises a header cell for matching.
  String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// How strongly a normalised header [cell] matches one of [aliases].
  ///
  /// An exact match always outranks a partial match, and longer aliases
  /// outrank shorter ones (e.g. "transaction date" beats "date").
  int matchScore(String cell, List<String> aliases) {
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
  int aliasMatchCount(List<String> row) {
    var matches = 0;
    for (final cell in row) {
      for (final aliases in headerAliases) {
        if (matchScore(normalize(cell), aliases) > 0) {
          matches++;
          break;
        }
      }
    }
    return matches;
  }
}
