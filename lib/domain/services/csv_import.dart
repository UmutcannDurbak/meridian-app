import 'package:intl/intl.dart';

import '../entities/obligation.dart';

/// Which CSV column (by header name) feeds each obligation field. Title and
/// expiryDate are required; everything else is optional.
class CsvColumnMapping {
  const CsvColumnMapping({
    required this.title,
    required this.expiryDate,
    this.category,
    this.counterparty,
    this.noticeDays,
    this.value,
    this.currency,
    this.autoRenews,
  });

  final String title;
  final String expiryDate;
  final String? category;
  final String? counterparty;
  final String? noticeDays;
  final String? value;
  final String? currency;
  final String? autoRenews;
}

/// One row's outcome. Either a ready-to-import obligation or a reason it
/// wasn't — a spreadsheet import is exactly the kind of bulk operation
/// where a silently-skipped or silently-wrong row is easy to miss, so every
/// row gets an explicit result the preview screen can show.
class CsvImportRow {
  const CsvImportRow({required this.rowNumber, this.obligation, this.error});

  /// 1-based, matching what a user sees in a spreadsheet (header is row 1).
  final int rowNumber;
  final Obligation? obligation;
  final String? error;

  bool get isValid => obligation != null;
}

/// Turns parsed CSV rows into draft [Obligation]s using a [CsvColumnMapping].
///
/// The one rule that matters here: never guess an ambiguous date. "3/4/2026"
/// is 4 March to most of the world and 3 April in the US — silently picking
/// one is exactly the kind of wrong-but-confident answer this product exists
/// to prevent. Rows with an ambiguous date are reported as errors, not
/// guessed.
abstract final class CsvImportService {
  static List<CsvImportRow> buildRows({
    required List<String> headers,
    required List<List<Object?>> dataRows,
    required CsvColumnMapping mapping,
    required String Function() nextId,
  }) {
    final titleIdx = headers.indexOf(mapping.title);
    final dateIdx = headers.indexOf(mapping.expiryDate);
    final categoryIdx = _indexOf(headers, mapping.category);
    final counterpartyIdx = _indexOf(headers, mapping.counterparty);
    final noticeDaysIdx = _indexOf(headers, mapping.noticeDays);
    final valueIdx = _indexOf(headers, mapping.value);
    final currencyIdx = _indexOf(headers, mapping.currency);
    final autoRenewsIdx = _indexOf(headers, mapping.autoRenews);

    final out = <CsvImportRow>[];
    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNumber = i + 2; // row 1 is the header

      String cell(int idx) =>
          idx >= 0 && idx < row.length ? '${row[idx] ?? ''}'.trim() : '';

      final title = cell(titleIdx);
      if (title.isEmpty) {
        out.add(CsvImportRow(rowNumber: rowNumber, error: 'Missing title'));
        continue;
      }

      final dateText = cell(dateIdx);
      final expiryDate = _parseDate(dateText);
      if (expiryDate == null) {
        final reason = dateText.isEmpty
            ? 'Missing date'
            : 'Could not read date "$dateText" — use YYYY-MM-DD if it '
                'looked ambiguous';
        out.add(CsvImportRow(rowNumber: rowNumber, error: reason));
        continue;
      }

      final counterparty = cell(counterpartyIdx);
      final currency = cell(currencyIdx);
      final amount = _parseAmount(cell(valueIdx));

      out.add(
        CsvImportRow(
          rowNumber: rowNumber,
          obligation: Obligation(
            id: nextId(),
            title: title,
            category: _parseCategory(cell(categoryIdx)),
            expiryDate: expiryDate,
            noticeDays: int.tryParse(cell(noticeDaysIdx)) ?? 0,
            counterparty: counterparty.isEmpty ? null : counterparty,
            value: amount != null && amount > 0
                ? Money(
                    (amount * 100).round(),
                    currency.isEmpty ? 'USD' : currency.toUpperCase(),
                  )
                : null,
            autoRenews: _parseBool(cell(autoRenewsIdx)),
            createdVia: CaptureSource.import,
          ),
        ),
      );
    }
    return out;
  }

  static int _indexOf(List<String> headers, String? header) =>
      header == null ? -1 : headers.indexOf(header);

  static DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;

    // ISO 8601 (2026-03-04) is unambiguous — trust it outright.
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    // Slash/dot-separated dates are ambiguous between D/M and M/D unless one
    // component is unambiguously > 12. Refuse to guess the rest.
    final parts = text.split(RegExp(r'[/.]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (a != null && b != null && y != null) {
        final year = y < 100 ? 2000 + y : y;
        if (a > 12 && b <= 12) return _dateOrNull(year, b, a); // D/M/Y
        if (b > 12 && a <= 12) return _dateOrNull(year, a, b); // M/D/Y
        return null; // both <= 12: genuinely ambiguous
      }
    }

    // Written months ("4 March 2026", "Mar 4, 2026") are unambiguous.
    for (final pattern in _writtenMonthPatterns) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } on FormatException {
        // try the next pattern
      }
    }
    return null;
  }

  static DateTime? _dateOrNull(int year, int month, int day) {
    final dt = DateTime(year, month, day);
    // DateTime rolls invalid dates forward (e.g. day 31 in a 30-day month)
    // rather than rejecting them — detect that and treat it as unparseable.
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  static const _writtenMonthPatterns = [
    'MMM d, yyyy',
    'MMMM d, yyyy',
    'd MMM yyyy',
    'd MMMM yyyy',
    'yyyy MMM d',
  ];

  static ObligationCategory _parseCategory(String text) {
    if (text.isEmpty) return ObligationCategory.other;
    final normalized = text.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    for (final c in ObligationCategory.values) {
      if (c.name.toLowerCase() == normalized) return c;
    }
    return ObligationCategory.other;
  }

  static bool _parseBool(String text) {
    final t = text.toLowerCase();
    return t == 'true' || t == 'yes' || t == 'y' || t == '1';
  }

  static double? _parseAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^\d.\-]'), '');
    return cleaned.isEmpty ? null : double.tryParse(cleaned);
  }
}
