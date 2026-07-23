import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/repository_provider.dart';
import '../domain/entities/obligation.dart';
import '../domain/services/exposure_service.dart';
import '../domain/services/obligation_stats.dart';
import '../domain/services/timeline_service.dart';

export '../data/repositories/repository_provider.dart'
    show obligationRepositoryProvider;
export '../domain/services/exposure_service.dart' show MonthExposure;
export '../domain/services/obligation_stats.dart' show ObligationStats;
export '../domain/services/timeline_service.dart' show MonthBucket;

/// Injected clock. Never call DateTime.now() outside this provider — it
/// makes every time-dependent behaviour in this app untestable, and this app
/// is almost entirely time-dependent behaviour.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// The database is the single source of truth. This stream is how the rest
/// of the app observes it — no separate in-memory copy to keep in sync.
final obligationListProvider = StreamProvider<List<Obligation>>((ref) {
  return ref.watch(obligationRepositoryProvider).watchAll();
});

enum HorizonGroupKind { overdue, thisWeek, thisMonth }

class HorizonGroup {
  const HorizonGroup(this.kind, this.items);
  final HorizonGroupKind kind;
  final List<Obligation> items;
}

/// The window Horizon (the home screen) actually surfaces. Beyond this,
/// an obligation is real but not imminent — Timeline's job, not Horizon's.
/// See [horizonGroupsProvider] for why the cutoff exists at all.
const horizonWindowDays = 31;

/// Groups by urgency, not by date. Empty groups are dropped entirely — a
/// section header with nothing under it is noise on a screen whose whole
/// purpose is reducing noise.
///
/// Deliberately capped at [horizonWindowDays]: this is "what needs me now",
/// not a second copy of every obligation on file. Dumping something due in
/// 11 months under a catch-all "Later" heading buries the handful of things
/// that are actually close, which defeats the point of a prioritised list.
/// Anything past the cutoff still exists — it's one tap away via Timeline,
/// surfaced through [horizonOverflowCountProvider] — it just doesn't
/// compete for space with what's actually due soon.
final horizonGroupsProvider = Provider<List<HorizonGroup>>((ref) {
  final now = ref.watch(nowProvider);
  final all = ref.watch(obligationListProvider).valueOrNull ?? const [];

  final live = all
      .where(
        (o) =>
            o.status != ObligationStatus.resolved &&
            o.status != ObligationStatus.dismissed &&
            o.status != ObligationStatus.draft &&
            !o.isSnoozed(now),
      )
      .toList()
    ..sort((a, b) => a.actionDeadline.compareTo(b.actionDeadline));

  final overdue = <Obligation>[];
  final week = <Obligation>[];
  final month = <Obligation>[];

  for (final o in live) {
    final d = o.daysUntilAction(now);
    if (d < 0) {
      overdue.add(o);
    } else if (d <= 7) {
      week.add(o);
    } else if (d <= horizonWindowDays) {
      month.add(o);
    }
  }

  return [
    if (overdue.isNotEmpty) HorizonGroup(HorizonGroupKind.overdue, overdue),
    if (week.isNotEmpty) HorizonGroup(HorizonGroupKind.thisWeek, week),
    if (month.isNotEmpty) HorizonGroup(HorizonGroupKind.thisMonth, month),
  ];
});

/// Count of live, non-snoozed obligations due beyond [horizonWindowDays] —
/// real, but intentionally left off Horizon. Drives the "N more upcoming"
/// link to Timeline so they're not simply lost.
final horizonOverflowCountProvider = Provider<int>((ref) {
  final now = ref.watch(nowProvider);
  final all = ref.watch(obligationListProvider).valueOrNull ?? const [];
  return all.where((o) {
    return o.status != ObligationStatus.resolved &&
        o.status != ObligationStatus.dismissed &&
        o.status != ObligationStatus.draft &&
        !o.isSnoozed(now) &&
        o.daysUntilAction(now) > horizonWindowDays;
  }).length;
});

/// Unconfirmed drafts awaiting review. Never alerted, never auto-deleted,
/// never counted as a real obligation — see ObligationStatus.draft.
final draftListProvider = Provider<List<Obligation>>((ref) {
  final all = ref.watch(obligationListProvider).valueOrNull ?? const [];
  return all.where((o) => o.status == ObligationStatus.draft).toList()
    ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
});

/// 12-month forward view for the Timeline screen.
final timelineMonthsProvider = Provider<List<MonthBucket>>((ref) {
  final now = ref.watch(nowProvider);
  final all = ref.watch(obligationListProvider).valueOrNull ?? const [];
  return TimelineService.monthBuckets(all, now);
});

/// Same window as [timelineMonthsProvider], summed by currency for the
/// Exposure screen.
final exposureMonthsProvider = Provider<List<MonthExposure>>((ref) {
  return ExposureService.fromBuckets(ref.watch(timelineMonthsProvider));
});

/// Counts behind the Timeline screen's stats header.
final obligationStatsProvider = Provider<ObligationStats>((ref) {
  final now = ref.watch(nowProvider);
  final all = ref.watch(obligationListProvider).valueOrNull ?? const [];
  return ObligationStatsService.compute(all, now);
});
