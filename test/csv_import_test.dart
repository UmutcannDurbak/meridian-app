import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/domain/services/csv_import.dart';

void main() {
  int idCounter = 0;
  String nextId() => 'row-${idCounter++}';

  setUp(() => idCounter = 0);

  group('date parsing', () {
    List<CsvImportRow> parseOneDate(String date) => CsvImportService.buildRows(
          headers: const ['Title', 'Date'],
          dataRows: [
            ['Lease', date],
          ],
          mapping: const CsvColumnMapping(title: 'Title', expiryDate: 'Date'),
          nextId: nextId,
        );

    test('accepts ISO 8601', () {
      final rows = parseOneDate('2026-03-04');
      expect(rows.single.isValid, isTrue);
      expect(rows.single.obligation!.expiryDate, DateTime(2026, 3, 4));
    });

    test('resolves an unambiguous D/M/Y date (day > 12)', () {
      final rows = parseOneDate('25/3/2026');
      expect(rows.single.isValid, isTrue);
      expect(rows.single.obligation!.expiryDate, DateTime(2026, 3, 25));
    });

    test('resolves an unambiguous M/D/Y date (month position > 12)', () {
      // 3/25/2026: second component (25) > 12, so the first must be the
      // month — 25 March 2026, not a nonsensical month 25.
      final rows = parseOneDate('3/25/2026');
      expect(rows.single.isValid, isTrue);
      expect(rows.single.obligation!.expiryDate, DateTime(2026, 3, 25));
    });

    test('refuses to guess a genuinely ambiguous D/M vs M/D date', () {
      // 3/4/2026 is 4 March to most of the world, 3 April in the US.
      // Silently picking one is exactly what this product must not do.
      final rows = parseOneDate('3/4/2026');
      expect(rows.single.isValid, isFalse);
      expect(rows.single.error, contains('ambiguous'));
    });

    test('accepts a written month', () {
      final rows = parseOneDate('4 March 2026');
      expect(rows.single.isValid, isTrue);
      expect(rows.single.obligation!.expiryDate, DateTime(2026, 3, 4));
    });

    test('rejects a rolled-over invalid date (31 April)', () {
      final rows = parseOneDate('31/4/2026');
      expect(rows.single.isValid, isFalse);
    });

    test('reports a missing date distinctly from an unparseable one', () {
      final rows = parseOneDate('');
      expect(rows.single.error, 'Missing date');
    });
  });

  group('row-level validation', () {
    test('requires a title', () {
      final rows = CsvImportService.buildRows(
        headers: const ['Title', 'Date'],
        dataRows: const [
          ['', '2026-01-01'],
        ],
        mapping: const CsvColumnMapping(title: 'Title', expiryDate: 'Date'),
        nextId: nextId,
      );
      expect(rows.single.isValid, isFalse);
      expect(rows.single.error, 'Missing title');
    });

    test('row numbers are 1-based and start after the header', () {
      final rows = CsvImportService.buildRows(
        headers: const ['Title', 'Date'],
        dataRows: const [
          ['Lease', '2026-01-01'],
          ['', '2026-01-01'],
        ],
        mapping: const CsvColumnMapping(title: 'Title', expiryDate: 'Date'),
        nextId: nextId,
      );
      expect(rows[0].rowNumber, 2);
      expect(rows[1].rowNumber, 3);
    });

    test('assigns a fresh id per row via nextId', () {
      final rows = CsvImportService.buildRows(
        headers: const ['Title', 'Date'],
        dataRows: const [
          ['Lease', '2026-01-01'],
          ['Insurance', '2026-02-01'],
        ],
        mapping: const CsvColumnMapping(title: 'Title', expiryDate: 'Date'),
        nextId: nextId,
      );
      expect(rows[0].obligation!.id, 'row-0');
      expect(rows[1].obligation!.id, 'row-1');
    });
  });

  group('optional field mapping', () {
    test('maps category, counterparty, notice days, value, currency, '
        'auto-renew when columns are provided', () {
      final rows = CsvImportService.buildRows(
        headers: const [
          'Title',
          'Date',
          'Category',
          'Vendor',
          'Notice',
          'Value',
          'Currency',
          'Renews',
        ],
        dataRows: const [
          [
            'Office lease',
            '2026-12-01',
            'Contract',
            'Acme Property',
            '90',
            '1,250,000.50',
            'eur',
            'yes',
          ],
        ],
        mapping: const CsvColumnMapping(
          title: 'Title',
          expiryDate: 'Date',
          category: 'Category',
          counterparty: 'Vendor',
          noticeDays: 'Notice',
          value: 'Value',
          currency: 'Currency',
          autoRenews: 'Renews',
        ),
        nextId: nextId,
      );

      final o = rows.single.obligation!;
      expect(o.category, ObligationCategory.contract);
      expect(o.counterparty, 'Acme Property');
      expect(o.noticeDays, 90);
      expect(o.value!.minorUnits, 125000050);
      expect(o.value!.currency, 'EUR');
      expect(o.autoRenews, isTrue);
    });

    test('falls back to "other" for an unrecognised category', () {
      final rows = CsvImportService.buildRows(
        headers: const ['Title', 'Date', 'Category'],
        dataRows: const [
          ['Something', '2026-01-01', 'not a real category'],
        ],
        mapping: const CsvColumnMapping(
          title: 'Title',
          expiryDate: 'Date',
          category: 'Category',
        ),
        nextId: nextId,
      );
      expect(rows.single.obligation!.category, ObligationCategory.other);
    });

    test('leaves value unset when the amount column is blank or zero', () {
      final rows = CsvImportService.buildRows(
        headers: const ['Title', 'Date', 'Value'],
        dataRows: const [
          ['A', '2026-01-01', ''],
          ['B', '2026-01-01', '0'],
        ],
        mapping: const CsvColumnMapping(
          title: 'Title',
          expiryDate: 'Date',
          value: 'Value',
        ),
        nextId: nextId,
      );
      expect(rows[0].obligation!.value, isNull);
      expect(rows[1].obligation!.value, isNull);
    });

    test('unmapped optional fields default sensibly', () {
      final rows = CsvImportService.buildRows(
        headers: const ['Title', 'Date'],
        dataRows: const [
          ['Minimal row', '2026-01-01'],
        ],
        mapping: const CsvColumnMapping(title: 'Title', expiryDate: 'Date'),
        nextId: nextId,
      );
      final o = rows.single.obligation!;
      expect(o.category, ObligationCategory.other);
      expect(o.counterparty, isNull);
      expect(o.noticeDays, 0);
      expect(o.value, isNull);
      expect(o.autoRenews, isFalse);
      expect(o.createdVia, CaptureSource.import);
    });
  });
}
