import '../entities/obligation.dart';

/// Generates future occurrences of a recurring obligation.
///
/// The hard part here is not the loop, it is calendar arithmetic. Dart's
/// `DateTime(2025, 2, 31)` silently rolls forward to 3 March rather than
/// throwing, which quietly corrupts every month-end obligation in the system.
/// A lease renewing on the 31st must land on the 28th/29th/30th of short
/// months and then return to the 31st — not drift permanently to the 3rd.
///
/// The rule below is therefore: always compute from the ORIGINAL anchor day,
/// never from the previously generated occurrence. Drift is cumulative and
/// invisible until a user misses a deadline a year later.
abstract final class RecurrenceEngine {
  /// Next occurrence strictly after [from], anchored on [seed].
  static DateTime? next(DateTime seed, RecurrenceRule rule, DateTime from) {
    if (rule.frequency == Frequency.none) return null;
    var n = 1;
    while (n < 600) {
      final candidate = _advance(seed, rule, n);
      if (candidate.isAfter(from)) {
        if (rule.until != null && candidate.isAfter(rule.until!)) return null;
        if (rule.count != null && n > rule.count!) return null;
        return candidate;
      }
      n++;
    }
    return null;
  }

  /// The next [limit] occurrences after [from].
  static List<DateTime> upcoming(
    DateTime seed,
    RecurrenceRule rule,
    DateTime from, {
    int limit = 12,
  }) {
    final out = <DateTime>[];
    var cursor = from;
    for (var i = 0; i < limit; i++) {
      final n = next(seed, rule, cursor);
      if (n == null) break;
      out.add(n);
      cursor = n;
    }
    return out;
  }

  /// [step]th occurrence after the seed. Always derived from the seed.
  static DateTime _advance(DateTime seed, RecurrenceRule rule, int step) {
    final k = step * rule.interval;
    return switch (rule.frequency) {
      Frequency.none => seed,
      Frequency.daily => seed.add(Duration(days: k)),
      Frequency.weekly => seed.add(Duration(days: k * 7)),
      Frequency.monthly => addMonths(seed, k),
      Frequency.quarterly => addMonths(seed, k * 3),
      Frequency.annual => addMonths(seed, k * 12),
      Frequency.custom => seed.add(Duration(days: k)),
    };
  }

  /// Adds [months] to [d], clamping the day to the target month's length.
  ///
  /// 31 Jan + 1 month  -> 28 Feb (29 Feb in a leap year)
  /// 31 Jan + 2 months -> 31 Mar   (clamping does not persist)
  /// 29 Feb 2024 + 12 months -> 28 Feb 2025
  static DateTime addMonths(DateTime d, int months) {
    final totalMonth = d.month - 1 + months;
    final year = d.year + (totalMonth ~/ 12);
    final month = (totalMonth % 12) + 1;
    // Handle negative months correctly (Dart's % is already non-negative for
    // positive divisors, but the year division needs care for negatives).
    final adjYear = totalMonth < 0 && totalMonth % 12 != 0 ? year - 1 : year;
    final adjMonth = totalMonth < 0 ? ((totalMonth % 12) + 12) % 12 + 1 : month;
    final day = d.day.clamp(1, daysInMonth(adjYear, adjMonth));
    return DateTime(adjYear, adjMonth, day, d.hour, d.minute);
  }

  static int daysInMonth(int year, int month) {
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) return 29;
    return lengths[month - 1];
  }

  static bool isLeapYear(int y) =>
      (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
}
