import 'package:csv/csv.dart';

import 'bank_of_baroda_parser.dart';
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
  final BankOfBarodaParser _bankOfBaroda = BankOfBarodaParser();

  /// Decodes [content] into raw [StatementRow]s.
  ///
  /// Empty lines are skipped and cells are never type-coerced, so amounts
  /// and dates stay exactly as they appear in the file. Bank of Baroda
  /// statement exports are detected and parsed separately (see
  /// [BankOfBarodaParser]); all other files take the generic header-based
  /// path below.
  List<StatementRow> parse(String content) {
    final rows = Csv(skipEmptyLines: true, dynamicTyping: false).decode(content);
    if (rows.isEmpty) return const [];

    final table = rows
        .map((row) => row.map((cell) => cell.toString().trim()).toList())
        .toList();
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
}
