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

class HorizonGroup {
  const HorizonGroup(this.label, this.items);
  final String label;
  final List<Obligation> items;
}

/// Groups by urgency, not by date. Empty groups are dropped entirely — a
/// section header with nothing under it is noise on a screen whose whole
/// purpose is reducing noise.
final horizonGroupsProvider = Provider<List<HorizonGroup>>((ref) {
  final now = ref.watch(nowProvider);
  final all = ref.watch(obligationListProvider).valueOrNull ?? const [];

  final live = all
      .where(
        (o) =>
            o.status != ObligationStatus.resolved &&
            o.status != ObligationStatus.dismissed &&
            o.status != ObligationStatus.draft,
      )
      .toList()
    ..sort((a, b) => a.actionDeadline.compareTo(b.actionDeadline));

  final overdue = <Obligation>[];
  final week = <Obligation>[];
  final month = <Obligation>[];
  final later = <Obligation>[];

  for (final o in live) {
    final d = o.daysUntilAction(now);
    if (d < 0) {
      overdue.add(o);
    } else if (d <= 7) {
      week.add(o);
    } else if (d <= 31) {
      month.add(o);
    } else {
      later.add(o);
    }
  }

  return [
    if (overdue.isNotEmpty) HorizonGroup('Overdue', overdue),
    if (week.isNotEmpty) HorizonGroup('This week', week),
    if (month.isNotEmpty) HorizonGroup('This month', month),
    if (later.isNotEmpty) HorizonGroup('Later', later),
  ];
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
