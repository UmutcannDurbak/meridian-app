import '../entities/obligation.dart';

/// Builds the alert campaign for an obligation.
///
/// A single reminder is not a product. A 90-day notice period needs a warning
/// at 90 days, because at 30 days the decision is already constrained and at
/// 7 days it is gone. So alerting is a schedule that escalates, and it counts
/// down to the ACTION deadline, never to the expiry date.
///
/// These offsets are defaults. Users override per obligation and per category,
/// and their override always wins.
abstract final class AlertScheduler {
  static const _critical = [90, 60, 30, 14, 7, 3, 1, 0];
  static const _important = [30, 14, 7, 3, 1, 0];
  static const _routine = [7, 1, 0];

  static List<int> offsetsFor(Criticality c) => switch (c) {
        Criticality.critical => _critical,
        Criticality.important => _important,
        Criticality.routine => _routine,
      };

  /// Concrete alert instants for [o], skipping any already in the past.
  ///
  /// Offsets wider than the obligation's own notice period are dropped: a
  /// 90-day warning on a 14-day notice period would fire before the user can
  /// meaningfully act and trains them to ignore alerts.
  static List<DateTime> schedule(
    Obligation o,
    DateTime now, {
    int hour = 9,
    int minute = 0,
    List<int>? overrideOffsets,
  }) {
    if (o.status == ObligationStatus.draft ||
        o.status == ObligationStatus.resolved ||
        o.status == ObligationStatus.dismissed ||
        o.isSnoozed(now)) {
      return const [];
    }

    final deadline = o.actionDeadline;
    final offsets = overrideOffsets ?? offsetsFor(o.criticality);
    final horizon = o.noticeDays > 0 ? o.noticeDays : o.daysUntilAction(now);

    final out = <DateTime>[];
    for (final d in offsets) {
      if (o.noticeDays > 0 && d > horizon && d != 0) continue;
      final at = DateTime(
        deadline.year,
        deadline.month,
        deadline.day - d,
        hour,
        minute,
      );
      if (at.isAfter(now)) out.add(at);
    }

    // Past the deadline an auto-renewing obligation keeps nagging daily: the
    // cost of inaction is still accruing. Non-renewing ones stop.
    if (o.autoRenews && !now.isBefore(deadline)) {
      for (var i = 1; i <= 7; i++) {
        out.add(DateTime(now.year, now.month, now.day + i, hour, minute));
      }
    }

    out.sort();
    return out;
  }

  /// Copy shown in the notification.
  ///
  /// Auto-renewing obligations get different wording because the user needs to
  /// understand that doing nothing is itself a decision with a price.
  static String message(Obligation o, DateTime now) {
    final days = o.daysUntilAction(now);
    final amount = o.value == null
        ? ''
        : ' ${o.value!.currency} ${o.value!.major.toStringAsFixed(0)}';

    if (days < 0) {
      return o.autoRenews
          ? '${o.title} renewed$amount. The window closed ${-days} days ago.'
          : '${o.title} is ${-days} days overdue.';
    }
    if (days == 0) {
      return o.autoRenews
          ? 'Last day to stop ${o.title} renewing$amount.'
          : '${o.title} is due today.';
    }
    return o.autoRenews
        ? '${o.title} renews$amount unless you act within $days days.'
        : '${o.title} needs action within $days days.';
  }
}
