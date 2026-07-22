import 'package:meta/meta.dart';

import '../entities/obligation.dart';

/// Counts behind the Timeline's stats header — how much is actually coming
/// up, broken out by how soon and how serious. Deliberately forward-only,
/// same as Timeline itself: an obligation already overdue has a negative
/// [Obligation.daysUntilAction] and falls into neither window, because
/// that's Horizon's job to surface, not a count on this screen.
@immutable
class ObligationStats {
  const ObligationStats({
    required this.thisWeekCount,
    required this.thisWeekCritical,
    required this.thisMonthCount,
    required this.thisMonthCritical,
  });

  /// Action deadline within the next 7 days.
  final int thisWeekCount;
  final int thisWeekCritical;

  /// Action deadline within the next 31 days — a superset of "this week".
  final int thisMonthCount;
  final int thisMonthCritical;
}

abstract final class ObligationStatsService {
  static ObligationStats compute(List<Obligation> obligations, DateTime now) {
    var weekCount = 0;
    var weekCritical = 0;
    var monthCount = 0;
    var monthCritical = 0;

    for (final o in obligations) {
      if (o.status == ObligationStatus.resolved ||
          o.status == ObligationStatus.dismissed ||
          o.status == ObligationStatus.draft) {
        continue;
      }
      final d = o.daysUntilAction(now);
      if (d < 0) continue;

      final critical = o.criticality == Criticality.critical;
      if (d <= 31) {
        monthCount++;
        if (critical) monthCritical++;
      }
      if (d <= 7) {
        weekCount++;
        if (critical) weekCritical++;
      }
    }

    return ObligationStats(
      thisWeekCount: weekCount,
      thisWeekCritical: weekCritical,
      thisMonthCount: monthCount,
      thisMonthCritical: monthCritical,
    );
  }
}
