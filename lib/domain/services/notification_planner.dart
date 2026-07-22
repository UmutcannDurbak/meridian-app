import 'package:meta/meta.dart';

import '../entities/obligation.dart';
import 'alert_scheduler.dart';

/// One concrete, platform-schedulable notification.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.obligationId,
    required this.at,
    required this.title,
    required this.body,
  });

  /// A stable id derived from (obligationId, at) — see [NotificationPlanner].
  final int id;
  final String obligationId;
  final DateTime at;
  final String title;
  final String body;
}

/// Turns the obligation list into the flat set of notifications the device
/// should have scheduled right now.
///
/// There is no server yet, so nothing diffs against what was scheduled
/// before — [NotificationChannel.reconcile] cancels everything and
/// re-schedules this plan from scratch on every obligation-list change and
/// on every app start. That only works if the same (obligation, instant)
/// pair always produces the same platform notification id; otherwise a
/// reschedule would leave orphaned notifications behind rather than
/// replacing them. Hence deriving [PlannedNotification.id] from the pair
/// itself instead of a counter.
abstract final class NotificationPlanner {
  static List<PlannedNotification> plan(
    List<Obligation> obligations,
    DateTime now,
  ) {
    final out = <PlannedNotification>[];
    for (final o in obligations) {
      for (final at in AlertScheduler.schedule(o, now)) {
        out.add(
          PlannedNotification(
            id: _stableId(o.id, at),
            obligationId: o.id,
            at: at,
            title: o.title,
            // Evaluated at the instant the alert actually fires, not now —
            // AlertScheduler.message phrases "due today" / "3 days" relative
            // to whatever DateTime it's given, and that should always be the
            // moment the notification appears on screen.
            body: AlertScheduler.message(o, at),
          ),
        );
      }
    }
    return out;
  }

  /// Platform notification ids are plain ints (a signed 32-bit value on
  /// Android under the hood), so this folds the hash into that range.
  static int _stableId(String obligationId, DateTime at) {
    final h = Object.hash(obligationId, at.millisecondsSinceEpoch);
    return h & 0x7FFFFFFF;
  }
}
