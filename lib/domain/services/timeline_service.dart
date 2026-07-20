import '../entities/obligation.dart';

/// One calendar month and the live obligations whose action deadline falls
/// in it.
class MonthBucket {
  const MonthBucket(this.month, this.items);

  /// The first day of the month, at midnight.
  final DateTime month;
  final List<Obligation> items;
}

/// Buckets obligations by month for [TimelineScreen] and, via
/// [ExposureService], the Exposure forecast.
///
/// Deliberately forward-only: bucketing starts at the current month and
/// never looks backward. Already-overdue items are Horizon's job — Timeline
/// exists to show the shape of what's coming, not to duplicate the "act
/// now" list.
abstract final class TimelineService {
  static List<MonthBucket> monthBuckets(
    List<Obligation> obligations,
    DateTime now, {
    int months = 12,
  }) {
    final live = obligations.where(_isLive).toList()
      ..sort((a, b) => a.actionDeadline.compareTo(b.actionDeadline));

    final start = DateTime(now.year, now.month);
    return [
      for (var i = 0; i < months; i++) _bucketFor(start, i, live),
    ];
  }

  static MonthBucket _bucketFor(
    DateTime start,
    int offset,
    List<Obligation> live,
  ) {
    final month = DateTime(start.year, start.month + offset);
    final items = live.where((o) {
      final d = o.actionDeadline;
      return d.year == month.year && d.month == month.month;
    }).toList();
    return MonthBucket(month, items);
  }

  static bool _isLive(Obligation o) =>
      o.status != ObligationStatus.resolved &&
      o.status != ObligationStatus.dismissed &&
      o.status != ObligationStatus.draft;
}
