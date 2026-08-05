import 'package:csv/csv.dart';

import 'statement_column_mapper.dart';
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
  final StatementColumnMapper _mapper = StatementColumnMapper();

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

    final table = rows
        .map((row) => row.map((cell) => cell.toString().trim()).toList())
        .toList();
    if (_isBankOfBaroda(content, table)) {
      return _parseBankOfBaroda(rows);
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

  bool _isBankOfBaroda(String content, List<List<String>> table) {
    if (_bobMarkers.hasMatch(content)) return true;

    // Secondary heuristic for exports without the bank footer: a header-less
    // statement with an Opening/Closing Balance row and UPI transactions.
    if (_mapper.findHeaderIndex(table) != null) return false;
    final lower = content.toLowerCase();
    return lower.contains('opening balance') &&
        lower.contains('closing balance') &&
        lower.contains('upi');
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
