import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/features/import/domain/pdf_statement_parser.dart';
import 'package:spendwise/features/import/domain/pdf_text_extractor.dart';

/// Returns [content] as the document's text layer; [throwError] makes the
/// extractor fail like a password-protected or unreadable PDF.
class _FakeExtractor extends PdfTextExtractor {
  _FakeExtractor(this.content, {this.throwError});

  final String content;
  final String? throwError;

  @override
  Future<String> extractText(
    Uint8List bytes, {
    FutureOr<String?> Function()? passwordProvider,
  }) async {
    if (throwError != null) {
      throw PdfTextExtractionException(throwError!);
    }
    return content;
  }
}

void main() {
  group('PdfStatementParser', () {
    test('maps a header row from the text layer', () async {
      const content = '''
Bank Statement
Date Description Debit Credit Balance
18-06-2024 Cafe Mocha 450.5 0 12345.6
19-06-2024 UPI-PAY 0 1000 13345.6
''';

      final rows = await PdfStatementParser(
        extractor: _FakeExtractor(content),
      ).parse(Uint8List.fromList([1, 2, 3]));

      expect(rows, hasLength(2));
      expect(rows[0].date, '18-06-2024');
      expect(rows[0].description, 'Cafe Mocha');
      expect(rows[0].debit, '450.5');
      expect(rows[0].credit, '0');
      expect(rows[0].balance, '12345.6');
      expect(rows[1].date, '19-06-2024');
      expect(rows[1].description, 'UPI-PAY');
      expect(rows[1].credit, '1000');
      expect(rows[1].balance, '13345.6');
    });

    test('detects and parses a Bank of Baroda PDF via the shared parser',
        () async {
      const content = '''
Bank of Baroda e-Statement
Opening Balance 12,345.60 Cr
04-06-2024 UPI/PHONEPE 500.00 12,845.60 Cr
05-06-2024 POS/Coffee 250.00 12,595.60 Cr
Closing Balance 12,595.60 Cr
''';

      final rows = await PdfStatementParser(
        extractor: _FakeExtractor(content),
      ).parse(Uint8List.fromList([1, 2, 3]));

      expect(rows, hasLength(2));
      expect(rows[0].date, '04-06-2024');
      expect(rows[0].description, 'UPI/PHONEPE');
      expect(rows[0].credit, '500.00');
      expect(rows[0].debit, '');
      expect(rows[0].balance, '12845.60');
      expect(rows[1].date, '05-06-2024');
      expect(rows[1].description, 'POS/Coffee');
      expect(rows[1].debit, '250.00');
      expect(rows[1].credit, '');
      expect(rows[1].balance, '12595.60');
    });

    test('parses wrapped-narration BoB PDF transactions into one row each',
        () async {
      const content = '''
Bank of Baroda e-Statement
Statement of transactions in Savings Account for the period Jun 01, 2026 - Jun 30, 2026
Opening Balance 139,240.62 Cr
01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@
ybl/UPI 40.00 139200.62 Cr
02-06-2026 NEFT-IN42615754789619-IG INFOSYSTEMS
(INDIA) PVT L 18000.00 157200.62 Cr
30-06-2026 UPI/654798324714/17:51:16/UPI/paytmqr6uvkr
8@ptys/ 20.00 157180.62 Cr
Closing Balance 157180.62 Cr
''';

      final rows = await PdfStatementParser(
        extractor: _FakeExtractor(content),
      ).parse(Uint8List.fromList([1, 2, 3]));

      expect(rows, hasLength(3));
      expect(rows[0].date, '01-06-2026');
      expect(
        rows[0].description,
        'UPI/651854963136/15:37:18/UPI/q294833438@ ybl/UPI',
      );
      expect(rows[0].debit, '40.00');
      expect(rows[0].credit, '');
      expect(rows[0].balance, '139200.62');
      expect(rows[1].date, '02-06-2026');
      expect(
        rows[1].description,
        'NEFT-IN42615754789619-IG INFOSYSTEMS (INDIA) PVT L',
      );
      expect(rows[1].debit, '');
      expect(rows[1].credit, '18000.00');
      expect(rows[1].balance, '157200.62');
      expect(rows[2].date, '30-06-2026');
      expect(
        rows[2].description,
        'UPI/654798324714/17:51:16/UPI/paytmqr6uvkr 8@ptys/',
      );
      expect(rows[2].debit, '20.00');
      expect(rows[2].credit, '');
      expect(rows[2].balance, '157180.62');
    });

    test('ignores repeating page headers and folds a three-line narration '
        'in a BoB PDF', () async {
      const content = '''
Bank of Baroda e-Statement
Opening Balance 10,000.00 Cr
01-06-2026 UPI/651854963136/15:37:18/UPI/q294833438@
ybl/UPI 40.00 9960.00 Cr
Statement of transactions in Savings Account for the period Jun 01, 2026 - Jun 30, 2026
BENJAMIN SAVINGS ACCOUNT - 45820100009218
DATE NARRATION CHQ.NO. WITHDRAWAL (DR) DEPOSIT (CR) BALANCE
02-06-2026 POS Restaurant The Grand
Summerset Avenue branch
DELHI 240.00 9720.00 Cr
Page 2 of 2
Closing Balance 9720.00 Cr
''';

      final rows = await PdfStatementParser(
        extractor: _FakeExtractor(content),
      ).parse(Uint8List.fromList([1, 2, 3]));

      expect(rows, hasLength(2));
      expect(
        rows[0].description,
        'UPI/651854963136/15:37:18/UPI/q294833438@ ybl/UPI',
      );
      expect(rows[0].debit, '40.00');
      expect(rows[1].date, '02-06-2026');
      expect(
        rows[1].description,
        'POS Restaurant The Grand Summerset Avenue branch DELHI',
      );
      expect(rows[1].debit, '240.00');
      expect(rows[1].balance, '9720.00');
      expect(rows[0].description, isNot(contains('Statement of transactions')));
      expect(rows[1].description, isNot(contains('DATE NARRATION')));
      expect(rows[1].description, isNot(contains('Page 2')));
    });

    test('rejects a scanned (text-less) PDF with a friendly error', () async {
      expect(
        () => PdfStatementParser(
          extractor: _FakeExtractor(''),
        ).parse(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<PdfFormatException>().having(
            (e) => e.message,
            'message',
            contains('This PDF contains no extractable text'),
          ),
        ),
      );
    });

    test('wraps an extraction failure (e.g. password) in a friendly error',
        () async {
      expect(
        () => PdfStatementParser(
          extractor: _FakeExtractor('', throwError: 'password-protected'),
        ).parse(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<PdfFormatException>().having(
            (e) => e.message,
            'message',
            'password-protected',
          ),
        ),
      );
    });
  });
}
