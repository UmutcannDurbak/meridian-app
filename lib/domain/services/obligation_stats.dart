import 'package:meta/meta.dart';

import '../entities/obligation.dart';

/// Counts and money behind the Timeline's stats header — how much is
/// actually coming up, broken out by how soon, how serious, and (for
/// obligations that carry a value) which direction the money moves.
/// Deliberately forward-only, same as Timeline itself: an obligation
/// already overdue has a negative [Obligation.daysUntilAction] and falls
/// into neither window, because that's Horizon's job to surface, not a
/// count on this screen.
@immutable
class ObligationStats {
  const ObligationStats({
    required this.thisWeekCount,
    required this.thisWeekCritical,
    required this.thisMonthCount,
    required this.thisMonthCritical,
    required this.netByCurrencyThisMonth,
  });

  /// Action deadline within the next 7 days.
  final int thisWeekCount;
  final int thisWeekCritical;

  /// Action deadline within the next 31 days — a superset of "this week".
  final int thisMonthCount;
  final int thisMonthCritical;

  /// Income minus expense for valued obligations within "this month" (the
  /// same next-31-days window as [thisMonthCount]), kept separate per
  /// currency rather than summed across them — see ExposureService for why
  /// that's non-negotiable. An obligation with no value contributes nothing;
  /// one currency code maps to zero only if income and expense in it
  /// happened to cancel out exactly, never because nothing was found — an
  /// empty map is the "nothing to show" case, not a zero entry.
  final Map<String, int> netByCurrencyThisMonth;
}

abstract final class ObligationStatsService {
  static ObligationStats compute(List<Obligation> obligations, DateTime now) {
    var weekCount = 0;
    var weekCritical = 0;
    var monthCount = 0;
    var monthCritical = 0;
    final net = <String, int>{};

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

        final v = o.value;
        if (v != null) {
          final signed = o.direction == MoneyDirection.income
              ? v.minorUnits
              : -v.minorUnits;
          net[v.currency] = (net[v.currency] ?? 0) + signed;
        }
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
      netByCurrencyThisMonth: net,
    );
  }
}
