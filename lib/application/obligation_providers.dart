import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/obligation.dart';

/// Injected clock. Never call DateTime.now() inside widgets or domain code —
/// it makes every time-dependent behaviour in this app untestable, and this
/// app is almost entirely time-dependent behaviour.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

final obligationListProvider =
    NotifierProvider<ObligationList, List<Obligation>>(ObligationList.new);

class ObligationList extends Notifier<List<Obligation>> {
  @override
  List<Obligation> build() => const [];

  void addAll(List<Obligation> items) => state = [...state, ...items];

  void resolve(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: ObligationStatus.resolved) else o,
    ];
    // TODO: enqueue sync + regenerate next occurrence if recurring
  }

  void snooze(String id, Duration by) {
    state = [
      for (final o in state)
        if (o.id == id)
          o.copyWith(expiryDate: o.expiryDate.add(by))
        else
          o,
    ];
  }
}

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
  final all = ref.watch(obligationListProvider);

  final live = all
      .where((o) =>
          o.status != ObligationStatus.resolved &&
          o.status != ObligationStatus.dismissed &&
          o.status != ObligationStatus.draft,)
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
