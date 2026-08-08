import 'statement_column_mapper.dart';
import 'statement_row.dart';

/// Shared parser for Bank of Baroda e-statements.
///
/// The single source of truth for BoB detection and parsing, reused by the
/// CSV, XLSX and PDF statement parsers so the logic lives in exactly one place.
///
/// BoB e-statements are single-column-ish dumps: several pages of account
/// summary precede the transaction table, there is no header row, and the
/// transaction rows use wildly different column layouts. The layout is
/// therefore ignored entirely — cells are joined into one text blob per row
/// and the date, description, amount and running balance are pulled out of
/// that text. Debit/credit direction is inferred from the running balance
/// delta, since BoB prints both debits and credits with no sign.
class BankOfBarodaParser {
  BankOfBarodaParser({StatementColumnMapper? mapper})
      : _mapper = mapper ?? StatementColumnMapper();

  final StatementColumnMapper _mapper;

  /// Markers that identify a Bank of Baroda statement (bank name, domain or
  /// IFSC code).
  static final RegExp _markers = RegExp(
    r'bank\s*of\s*baroda|bankofbaroda|barbomarmar',
    caseSensitive: false,
  );
  static final RegExp _date = RegExp(r'\d{2}[/-]\d{2}[/-]\d{4}');
  static final RegExp _dateOnly = RegExp(r'^\d{2}[/-]\d{2}[/-]\d{4}$');
  static final RegExp _balance = RegExp(
    r'([\d,]+\.\d{2})\s*Cr\b',
    caseSensitive: false,
  );
  static final RegExp _number = RegExp(r'\b\d+(?:\.\d+)?\b');
  static final RegExp _cellWhitespace = RegExp(r'\s+');

  /// Whether [content] (the raw file text) and [table] describe a Bank of
  /// Baroda statement.
  ///
  /// Primary heuristic: the bank's name, domain or IFSC code anywhere in the
  /// content. Secondary heuristic (exports without the bank footer): a
  /// header-less statement with an Opening/Closing Balance row and UPI
  /// transactions.
  bool isBankOfBaroda(String content, List<List<String>> table) {
    if (_markers.hasMatch(content)) return true;

    if (_mapper.findHeaderIndex(table) != null) return false;
    final lower = content.toLowerCase();
    return lower.contains('opening balance') &&
        lower.contains('closing balance') &&
        lower.contains('upi');
  }

  /// Parses a Bank of Baroda statement table into raw [StatementRow]s.
  ///
  /// One row in [rows] is one physical line of the statement. CSV/XLSX
  /// exports put a complete transaction on each line, but PDF text extraction
  /// can wrap a transaction across several lines (date + narration on the
  /// first line, then the narration continuation + amount + balance). The
  /// pending state machine below reconstructs those wrapped transactions so
  /// exactly one [StatementRow] is produced per real transaction.
  List<StatementRow> parse(List<List<String>> rows) {
    final statementRows = <StatementRow>[];
    double? previousBalance;
    _BobTxn? pending;

    for (final row in rows) {
      final blob = _joinCells(row);
      if (blob.isEmpty) continue;

      final trimmed = blob.trim();
      final lower = trimmed.toLowerCase();
      final balance = _parseBalance(trimmed);

      // Opening balance initialises the running balance; it is not a
      // transaction.
      if (balance != null && lower.contains('opening balance')) {
        previousBalance = balance;
        pending = null;
        continue;
      }

      // Closing balance ends the statement; it is not a transaction and
      // resolves any pending state.
      if (balance != null && lower.contains('closing balance')) {
        pending = null;
        continue;
      }

      // BoB occasionally prints the date on the row after the description and
      // amount (a wrapping artifact). Such date-only rows resolve the pending
      // transaction via its date, preserving the existing CSV/XLSX quirk.
      // A date-only row with nothing pending instead starts a wrapped
      // transaction whose narration follows on the next line.
      if (_dateOnly.hasMatch(trimmed)) {
        final date = _normalizeDate(trimmed);
        if (pending != null && pending.balance != null) {
          statementRows.add(_emitRow(pending, previousBalance, date));
          previousBalance = pending.balance;
          pending = null;
        } else {
          pending = _BobTxn(date: date, description: '', balance: null);
        }
        continue;
      }

      // A line with a date but no balance begins a wrapped transaction: the
      // amount and balance land on a following line. The date and narration
      // are retained as the pending transaction instead of being discarded.
      if (balance == null) {
        final dateMatch = _date.firstMatch(trimmed);
        if (dateMatch != null) {
          if (pending == null || pending.balance == null) {
            pending = _BobTxn(
              date: _normalizeDate(dateMatch.group(0)!),
              description: trimmed.substring(dateMatch.end).trim(),
              balance: null,
            );
          }
        } else if (pending != null && pending.balance == null) {
          // Narration continuation without a date or balance: fold it into the
          // pending wrapped transaction (three-line or longer narrations).
          pending = _BobTxn(
            date: pending.date,
            description: _mergeDescription(pending.description, trimmed),
            balance: null,
          );
        }
        // Otherwise the line is statement furniture (headers, footers, page
        // labels, summary text) and is ignored.
        continue;
      }

      final txn = _extractTxn(trimmed, balance);
      if (txn == null) continue;

      if (txn.date.isNotEmpty) {
        // A complete single-line transaction (the existing CSV/XLSX shape).
        // A fresh transaction boundary always clears any unresolved pending.
        pending = null;
        statementRows.add(_emitRow(txn, previousBalance, null));
        previousBalance = txn.balance;
        continue;
      }

      if (pending != null && pending.balance == null) {
        // Completion of a wrapped transaction: the current line supplies the
        // amount and balance, and its narration merges with the pending one.
        final completed = _BobTxn(
          date: pending.date,
          description: _mergeDescription(pending.description, txn.description),
          amount: txn.amount,
          balance: txn.balance,
        );
        statementRows.add(_emitRow(completed, previousBalance, null));
        previousBalance = completed.balance;
        pending = null;
        continue;
      }

      // Existing CSV/XLSX quirk: the amount and balance arrive before the
      // date, which is printed on a following date-only row.
      pending = txn;
    }

    // Never emit an incomplete wrapped transaction that has no balance.
    if (pending != null && pending.balance != null) {
      statementRows.add(_emitRow(pending, previousBalance, null));
    }

    return statementRows;
  }

  /// Joins the non-empty cells of one row into a single text blob, collapsing
  /// all internal whitespace (including newlines inside quoted fields).
  String _joinCells(List<String> row) {
    final parts = <String>[];
    for (final cell in row) {
      final text = cell.trim();
      if (text.isNotEmpty) parts.add(text);
    }
    return parts.join(' ').replaceAll(_cellWhitespace, ' ');
  }

  double? _parseBalance(String blob) {
    final matches = _balance.allMatches(blob);
    if (matches.isEmpty) return null;
    return _toDouble(matches.last.group(1)!);
  }

  _BobTxn? _extractTxn(String blob, double balance) {
    final dateMatch = _date.firstMatch(blob);
    final balanceMatches = _balance.allMatches(blob);
    if (balanceMatches.isEmpty) return null;
    final balanceMatch = balanceMatches.last;

    // The printed amount is the last standalone number before the balance.
    double? amount;
    var amountStart = balanceMatch.start;
    final numbers = _number.allMatches(blob.substring(0, balanceMatch.start));
    if (numbers.isNotEmpty) {
      final lastNumber = numbers.last;
      amount = _toDouble(lastNumber.group(0)!);
      amountStart = lastNumber.start;
    }

    final date = dateMatch == null ? '' : _normalizeDate(dateMatch.group(0)!);
    final description = blob
        .substring(dateMatch?.end ?? 0, amountStart)
        .trim()
        .replaceAll(_cellWhitespace, ' ');

    return _BobTxn(
      date: date,
      description: description,
      amount: amount,
      balance: balance,
    );
  }

  /// Joins two narration pieces with a single space, trimming each piece and
  /// ignoring empty parts so wrapped descriptions stay readable without
  /// duplicated whitespace.
  String _mergeDescription(String first, String second) {
    final left = first.trim();
    final right = second.trim();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    return '$left $right';
  }

  StatementRow _emitRow(
    _BobTxn txn,
    double? previousBalance,
    String? dateOverride,
  ) {
    assert(txn.balance != null, 'Cannot emit an incomplete transaction');
    final balance = txn.balance!;
    final date = dateOverride ?? txn.date;
    var isCredit = false;
    var amount = txn.amount;

    if (previousBalance != null) {
      final delta = balance - previousBalance;
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
      balance: balance.toStringAsFixed(2),
    );
  }

  /// BoB uses both `DD-MM-YYYY` and `MM/DD/YYYY` in the same file; both are
  /// normalised to `DD-MM-YYYY` so the preview shows one consistent format.
  String _normalizeDate(String raw) {
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
///
/// [balance] is nullable because a wrapped PDF transaction is built from two
/// lines: the first contributes the date and narration, the second the amount
/// and balance. Only completed transactions (with a balance) are ever emitted.
class _BobTxn {
  final String date;
  final String description;
  final double? amount;
  final double? balance;

  const _BobTxn({
    required this.date,
    required this.description,
    this.amount,
    this.balance,
  });
}
