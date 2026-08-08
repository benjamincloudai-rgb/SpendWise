import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/features/import/domain/bank_of_baroda_parser.dart';
import 'package:spendwise/features/import/domain/statement_row.dart';

/// Builds the same table shape the statement parsers feed into
/// [BankOfBarodaParser]: one physical line per row, split into
/// whitespace-separated cells.
List<List<String>> _table(List<String> lines) =>
    lines.map((line) => line.split(RegExp(r'\s+'))).toList();

List<StatementRow> _parse(List<String> lines) =>
    BankOfBarodaParser().parse(_table(lines));

void main() {
  group('BankOfBarodaParser', () {
    test('parses a single single-line transaction (CSV/XLSX shape)', () {
      final rows = _parse([
        'Opening Balance 12,345.60 Cr',
        '04-06-2024 UPI/PHONEPE 500.00 12,845.60 Cr',
        'Closing Balance 12,845.60 Cr',
      ]);

      expect(rows, hasLength(1));
      expect(rows[0].date, '04-06-2024');
      expect(rows[0].description, 'UPI/PHONEPE');
      expect(rows[0].debit, '');
      expect(rows[0].credit, '500.00');
      expect(rows[0].balance, '12845.60');
    });

    test('parses multiple single-line transactions into one row each', () {
      final rows = _parse([
        'Opening Balance 12,345.60 Cr',
        '04-06-2024 UPI/PHONEPE 500.00 12,845.60 Cr',
        '05-06-2024 POS/Coffee 250.00 12,595.60 Cr',
        '06-06-2024 UPI/RENT 5000.00 7,595.60 Cr',
        'Closing Balance 7,595.60 Cr',
      ]);

      expect(rows, hasLength(3));
      expect(rows[0].date, '04-06-2024');
      expect(rows[0].credit, '500.00');
      expect(rows[0].balance, '12845.60');
      expect(rows[1].date, '05-06-2024');
      expect(rows[1].debit, '250.00');
      expect(rows[1].balance, '12595.60');
      expect(rows[2].date, '06-06-2024');
      expect(rows[2].debit, '5000.00');
      expect(rows[2].balance, '7595.60');
    });

    test('merges a wrapped transaction into a single row', () {
      final rows = _parse([
        'Opening Balance 139,240.62 Cr',
        '01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@',
        'ybl/UPI 40.00 139200.62 Cr',
        'Closing Balance 139,200.62 Cr',
      ]);

      expect(rows, hasLength(1));
      expect(rows[0].date, '01-06-2026');
      expect(
        rows[0].description,
        'UPI/651854963136/15:37:18/UPI/q294833438@ ybl/UPI',
      );
      expect(rows[0].debit, '40.00');
      expect(rows[0].credit, '');
      expect(rows[0].balance, '139200.62');
    });

    test('parses multiple wrapped transactions into one row each', () {
      final rows = _parse([
        'Opening Balance 139,240.62 Cr',
        '01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@',
        'ybl/UPI 40.00 139200.62 Cr',
        '02-06-2026 UPI/651871364212/08:10:02/UPI/9989000001@',
        'ybl 7.50 139208.12 Cr',
        '03-06-2026 NEFT-IN42615754789619-IG INFOSYSTEMS',
        '(INDIA) PVT L 18000.00 157208.12 Cr',
        'Closing Balance 157,208.12 Cr',
      ]);

      expect(rows, hasLength(3));
      expect(rows[0].date, '01-06-2026');
      expect(rows[0].debit, '40.00');
      expect(rows[0].balance, '139200.62');
      expect(rows[1].date, '02-06-2026');
      expect(rows[1].credit, '7.50');
      expect(rows[1].balance, '139208.12');
      expect(rows[2].date, '03-06-2026');
      expect(
        rows[2].description,
        'NEFT-IN42615754789619-IG INFOSYSTEMS (INDIA) PVT L',
      );
      expect(rows[2].credit, '18000.00');
      expect(rows[2].balance, '157208.12');
    });

    test('infers debit and credit direction for wrapped transactions', () {
      final rows = _parse([
        'Opening Balance 10,000.00 Cr',
        '01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@',
        'ybl/UPI 40.00 9960.00 Cr',
        '02-06-2026 UPI/651871364212/08:10:02/UPI/9989000001@',
        'ybl 200.00 10160.00 Cr',
        'Closing Balance 10,160.00 Cr',
      ]);

      expect(rows, hasLength(2));
      expect(rows[0].debit, '40.00');
      expect(rows[0].credit, '');
      expect(rows[1].debit, '');
      expect(rows[1].credit, '200.00');
    });

    test('folds a three-line narration into one description', () {
      final rows = _parse([
        'Opening Balance 10,000.00 Cr',
        '05-06-2026 POS Restaurant The Grand',
        'Summerset Avenue branch',
        'DELHI 450.00 10,450.00 Cr',
        'Closing Balance 10,450.00 Cr',
      ]);

      expect(rows, hasLength(1));
      expect(
        rows[0].description,
        'POS Restaurant The Grand Summerset Avenue branch DELHI',
      );
      expect(rows[0].credit, '450.00');
    });

    test('ignores repeated page headers and footers', () {
      final rows = _parse([
        'Opening Balance 139,240.62 Cr',
        '01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@',
        'ybl/UPI 40.00 139200.62 Cr',
        'Statement of transactions in Savings Account for the period '
            'Jun 01, 2026 - Jun 30, 2026',
        'BENJAMIN SAVINGS ACCOUNT - 45820100009218',
        'DATE NARRATION CHQ.NO. WITHDRAWAL (DR) DEPOSIT (CR) BALANCE',
        '02-06-2026 UPI/651871364212/08:10:02/UPI/9989000001@',
        'ybl 7.50 139208.12 Cr',
        'Page 2 of 2 https://www.bankofbaroda.bank.in',
        'Closing Balance 139,208.12 Cr',
      ]);

      expect(rows, hasLength(2));
      expect(rows[0].description, contains('UPI/651854963136'));
      expect(rows[1].description, contains('UPI/651871364212'));
      expect(rows[0].description, isNot(contains('Statement of transactions')));
      expect(rows[1].description, isNot(contains('DATE NARRATION')));
      expect(rows[1].description, isNot(contains('Page 2')));
    });

    test('does not import the opening balance as a transaction', () {
      final rows = _parse([
        'Opening Balance 139,240.62 Cr',
        'Closing Balance 139,240.62 Cr',
      ]);

      expect(rows, isEmpty);
    });

    test('does not import the closing balance as a transaction', () {
      final rows = _parse([
        'Opening Balance 139,240.62 Cr',
        '30-06-2026 Closing Balance 139,240.62 Cr',
      ]);

      expect(rows, isEmpty);
    });

    test('keeps the trailing date-only CSV/XLSX quirk resolution', () {
      final rows = _parse([
        'Opening Balance 12,345.60 Cr',
        'UPI/PHONEPE 500.00 12,845.60 Cr',
        '04-06-2024',
        'Closing Balance 12,845.60 Cr',
      ]);

      expect(rows, hasLength(1));
      expect(rows[0].date, '04-06-2024');
      expect(rows[0].description, 'UPI/PHONEPE');
      expect(rows[0].credit, '500.00');
      expect(rows[0].balance, '12845.60');
    });

    test('normalises MM/DD/YYYY dates to DD-MM-YYYY', () {
      final rows = _parse([
        'Opening Balance 12,345.60 Cr',
        '06/04/2024 UPI/PHONEPE 500.00 12,845.60 Cr',
        'Closing Balance 12,845.60 Cr',
      ]);

      expect(rows, hasLength(1));
      expect(rows[0].date, '04-06-2024');
    });

    test('does not emit a trailing incomplete wrapped transaction', () {
      final rows = _parse([
        'Opening Balance 139,240.62 Cr',
        '01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@',
      ]);

      expect(rows, isEmpty);
    });

    test('handles a mix of single-line and wrapped transactions', () {
      final rows = _parse([
        'Opening Balance 10,000.00 Cr',
        '01-06-2026 UPI/PHONEPE 100.00 9,900.00 Cr',
        '02-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@',
        'ybl/UPI 40.00 9,860.00 Cr',
        'Closing Balance 9,860.00 Cr',
      ]);

      expect(rows, hasLength(2));
      expect(rows[0].date, '01-06-2026');
      expect(rows[0].debit, '100.00');
      expect(rows[1].date, '02-06-2026');
      expect(rows[1].debit, '40.00');
      expect(rows[1].balance, '9860.00');
    });

    test('completes a wrap whose date sits alone on the first line', () {
      final rows = _parse([
        'Opening Balance 10,000.00 Cr',
        '05-06-2026',
        'Salaries & Rent 2500.00 12,500.00 Cr',
        'Closing Balance 12,500.00 Cr',
      ]);

      expect(rows, hasLength(1));
      expect(rows[0].date, '05-06-2026');
      expect(rows[0].description, 'Salaries & Rent');
      expect(rows[0].credit, '2500.00');
    });
  });
}
