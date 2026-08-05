import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/features/import/domain/xlsx_statement_parser.dart';

/// Builds a minimal but structurally valid `.xlsx` workbook (a ZIP of XML
/// parts) so the parser can be exercised without a spreadsheet library.
Uint8List _buildWorkbook(List<String> rowsXml) {
  final workbookXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
</workbook>''';

  final relsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''';

  final sharedStringsXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <si><t>Cafe Mocha</t></si>
  <si><r><t>UPI</t></r><r><t>-PAY</t></r></si>
</sst>''';

  final stylesXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <cellXfs count="2">
    <xf numFmtId="14" applyNumberFormat="1"/>
    <xf numFmtId="0" applyNumberFormat="0"/>
  </cellXfs>
</styleSheet>''';

  final worksheetXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>${rowsXml.join('\n')}</sheetData>
</worksheet>''';

  final archive = Archive();
  archive.addFile(
    ArchiveFile.bytes('xl/workbook.xml', utf8.encode(workbookXml)),
  );
  archive.addFile(
    ArchiveFile.bytes('xl/_rels/workbook.xml.rels', utf8.encode(relsXml)),
  );
  archive.addFile(
    ArchiveFile.bytes('xl/sharedStrings.xml', utf8.encode(sharedStringsXml)),
  );
  archive.addFile(ArchiveFile.bytes('xl/styles.xml', utf8.encode(stylesXml)));
  archive.addFile(
    ArchiveFile.bytes('xl/worksheets/sheet1.xml', utf8.encode(worksheetXml)),
  );

  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

void main() {
  group('XlsxStatementParser', () {
    // Date cell uses style 0 (numFmtId 14) and the Excel serial for 18-06-2024.
    final serialFor20240618 = DateTime.utc(2024, 6, 18)
        .difference(DateTime.utc(1899, 12, 30))
        .inDays;

    test('maps a header row and preserves shared strings and dates', () {
      final bytes = _buildWorkbook([
        '<row r="1">'
            '<c r="A1" t="inlineStr"><is><t>Date</t></is></c>'
            '<c r="B1" t="inlineStr"><is><t>Description</t></is></c>'
            '<c r="C1" t="inlineStr"><is><t>Debit</t></is></c>'
            '<c r="D1" t="inlineStr"><is><t>Credit</t></is></c>'
            '<c r="E1" t="inlineStr"><is><t>Balance</t></is></c>'
            '</row>',
        '<row r="2">'
            '<c r="A2" s="0"><v>$serialFor20240618</v></c>'
            '<c r="B2" t="s"><v>0</v></c>'
            '<c r="C2"><v>450.5</v></c>'
            '<c r="D2"><v>0</v></c>'
            '<c r="E2"><v>12345.6</v></c>'
            '</row>',
        '<row r="3">'
            '<c r="A3" s="0"><v>${serialFor20240618 + 1}</v></c>'
            '<c r="B3" t="s"><v>1</v></c>'
            '<c r="C3"><v>0</v></c>'
            '<c r="D3"><v>1000</v></c>'
            '<c r="E3"><v>13345.6</v></c>'
            '</row>',
      ]);

      final rows = XlsxStatementParser().parse(bytes);

      expect(rows, hasLength(2));
      expect(rows[0].date, '18-06-2024');
      expect(rows[0].description, 'Cafe Mocha');
      expect(rows[0].debit, '450.5');
      expect(rows[0].credit, '0');
      expect(rows[0].balance, '12345.6');
      expect(rows[1].date, '19-06-2024');
      expect(rows[1].description, 'UPI-PAY');
      expect(rows[1].credit, '1000');
    });

    test('falls back to positional columns when there is no header row', () {
      final bytes = _buildWorkbook([
        '<row r="1">'
            '<c r="A1" t="inlineStr"><is><t>18-06-2024</t></is></c>'
            '<c r="B1" t="inlineStr"><is><t>Rent</t></is></c>'
            '<c r="C1" t="inlineStr"><is><t>20000</t></is></c>'
            '</row>',
      ]);

      final rows = XlsxStatementParser().parse(bytes);

      expect(rows, hasLength(1));
      expect(rows[0].date, '18-06-2024');
      expect(rows[0].description, 'Rent');
      expect(rows[0].debit, '20000');
    });

    test('skips empty rows', () {
      final bytes = _buildWorkbook([
        '<row r="1">'
            '<c r="A1" t="inlineStr"><is><t>Date</t></is></c>'
            '<c r="B1" t="inlineStr"><is><t>Description</t></is></c>'
            '<c r="C1" t="inlineStr"><is><t>Debit</t></is></c>'
            '<c r="D1" t="inlineStr"><is><t>Credit</t></is></c>'
            '<c r="E1" t="inlineStr"><is><t>Balance</t></is></c>'
            '</row>',
        '<row r="2"></row>',
        '<row r="3">'
            '<c r="A3" s="0"><v>$serialFor20240618</v></c>'
            '<c r="B3" t="s"><v>0</v></c>'
            '<c r="C3"><v>120</v></c>'
            '<c r="D3"><v>0</v></c>'
            '<c r="E3"><v>50</v></c>'
            '</row>',
      ]);

      final rows = XlsxStatementParser().parse(bytes);

      expect(rows, hasLength(1));
      expect(rows[0].debit, '120');
    });

    test('throws a friendly exception for non-xlsx bytes', () {
      expect(
        () => XlsxStatementParser().parse(
          Uint8List.fromList(utf8.encode('this is not a zip file')),
        ),
        throwsA(isA<Object>()),
      );
    });
  });
}
