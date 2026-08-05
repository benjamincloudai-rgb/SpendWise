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

  /// Decodes [content] into raw [StatementRow]s.
  ///
  /// Empty lines are skipped and cells are never type-coerced, so amounts
  /// and dates stay exactly as they appear in the file. Bank of Baroda
  /// statement exports are detected and parsed separately (see
  /// [_isBankOfBaroda] and [_parseBankOfBaroda]); all other files take the
  /// generic header-based path below.
  List<StatementRow> parse(String content) {
    final rows = Csv(skipEmptyLines: true, dynamicTyping: false).decode(content);
    if (rows.isEmpty) return const [];

    if (_isBankOfBaroda(content, rows)) {
      return _parseBankOfBaroda(rows);
    }

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

  bool _isBankOfBaroda(String content, List<List<dynamic>> rows) {
    if (_bobMarkers.hasMatch(content)) return true;

    // Secondary heuristic for exports without the bank footer: a header-less
    // statement with an Opening/Closing Balance row and UPI transactions.
    if (_findHeaderIndex(rows) != null) return false;
    final lower = content.toLowerCase();
    return lower.contains('opening balance') &&
        lower.contains('closing balance') &&
        lower.contains('upi');
  }

  List<StatementRow> _parseBankOfBaroda(List<List<dynamic>> rows) {
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
  /// all internal whitespace (including newlines inside quoted fields).
  String _joinBobCells(List<dynamic> row) {
    final parts = <String>[];
    for (final cell in row) {
      final text = cell.toString().trim();
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
    final numbers = _bobNumber.allMatches(blob.substring(0, balanceMatch.start));
    if (numbers.isNotEmpty) {
      final lastNumber = numbers.last;
      amount = _toDouble(lastNumber.group(0)!);
      amountStart = lastNumber.start;
    }

    final date = dateMatch == null ? '' : _normalizeBobDate(dateMatch.group(0)!);
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

  StatementRow _emitBobRow(_BobTxn txn, double? previousBalance, String? dateOverride) {
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
