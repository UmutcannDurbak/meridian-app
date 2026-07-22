import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/obligation.dart';
import '../../widgets/month_calendar.dart';
import '../../widgets/obligation_row.dart';
import '../capture/obligation_form_screen.dart';

/// FR-402 — a 12-month forward calendar, so something easy to miss in a
/// flat list (a licence expiring in September) is visible as a specific
/// square on a specific month, and tapping that square is how you get to
/// it. Deliberately excludes anything already overdue — that's Horizon's
/// job. Forward-only, one month at a time, all twelve navigable even when
/// a given month is empty.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  int _monthIndex = 0;
  int? _selectedDay;

  void _goToMonth(int index) {
    setState(() {
      _monthIndex = index;
      _selectedDay = null;
    });
  }

  void _toggleDay(int day) {
    setState(() => _selectedDay = _selectedDay == day ? null : day);
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final months = ref.watch(timelineMonthsProvider);
    final stats = ref.watch(obligationStatsProvider);
    final now = ref.watch(nowProvider);
    final repo = ref.watch(obligationRepositoryProvider);

    final bucket = months[_monthIndex];
    final itemsByDay = <int, List<Obligation>>{};
    for (final o in bucket.items) {
      itemsByDay.putIfAbsent(o.actionDeadline.day, () => []).add(o);
    }
    final selectedDay = _selectedDay;
    final displayedItems =
        selectedDay != null ? (itemsByDay[selectedDay] ?? const []) : bucket.items;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.lg,
        Space.md,
        Space.huge,
      ),
      children: [
        Text('Timeline', style: Type.display(tone.ink)),
        const SizedBox(height: Space.md),
        _StatsHeader(stats: stats),
        const SizedBox(height: Space.lg),
        MonthNav(
          label: DateFormat.yMMMM().format(bucket.month),
          canGoBack: _monthIndex > 0,
          canGoForward: _monthIndex < months.length - 1,
          onBack: () => _goToMonth(_monthIndex - 1),
          onForward: () => _goToMonth(_monthIndex + 1),
        ),
        const SizedBox(height: Space.md),
        MonthCalendar(
          month: bucket.month,
          itemsByDay: itemsByDay,
          now: now,
          selectedDay: _selectedDay,
          onSelectDay: _toggleDay,
        ),
        const SizedBox(height: Space.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDay != null
                  ? DateFormat.MMMd().format(
                      DateTime(bucket.month.year, bucket.month.month, selectedDay),
                    )
                  : DateFormat.yMMMM().format(bucket.month).toUpperCase(),
              style: Type.eyebrow(tone.inkMuted),
            ),
            if (displayedItems.isNotEmpty)
              Text(
                '${displayedItems.length}',
                style: Type.eyebrow(tone.inkFaint),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        if (displayedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text('Nothing due', style: Type.label(tone.inkFaint)),
          )
        else
          for (final o in displayedItems)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: ObligationRow(
                obligation: o,
                now: now,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ObligationFormScreen(existing: o),
                  ),
                ),
                onResolve: () => repo.resolve(o.id),
                onSnooze: () => repo.snooze(o.id, const Duration(days: 7)),
                onDelete: () => repo.delete(o.id),
              ),
            ),
      ],
    );
  }
}

/// How much is actually coming up, at a glance, before scrolling a single
/// month. "This month" is a superset of "this week", not a separate bucket
/// — see ObligationStatsService.
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});
  final ObligationStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'THIS WEEK',
                count: stats.thisWeekCount,
                critical: stats.thisWeekCritical,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: _StatCard(
                label: 'THIS MONTH',
                count: stats.thisMonthCount,
                critical: stats.thisMonthCritical,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        _NetCard(netByCurrency: stats.netByCurrencyThisMonth),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.critical,
  });

  final String label;
  final int count;
  final int critical;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tone.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Type.eyebrow(tone.inkMuted)),
          const SizedBox(height: Space.xs),
          Text('$count', style: Type.display(tone.ink).copyWith(fontSize: 26)),
          const SizedBox(height: Space.xxs),
          Text(
            critical == 0 ? 'nothing critical' : '$critical critical',
            style: Type.label(critical == 0 ? tone.inkFaint : Pressure.closing),
          ),
        ],
      ),
    );
  }
}

/// Income minus what you owe, for valued obligations due this month.
/// Currencies never get summed together — see ObligationStats.
class _NetCard extends StatelessWidget {
  const _NetCard({required this.netByCurrency});
  final Map<String, int> netByCurrency;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final entries = netByCurrency.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: tone.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NET THIS MONTH', style: Type.eyebrow(tone.inkMuted)),
          const SizedBox(height: Space.xs),
          if (entries.isEmpty)
            Text(
              'Nothing valued this month',
              style: Type.label(tone.inkFaint),
            )
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xxs),
                child: Text(
                  _formatNet(e.value, e.key),
                  style: Type.display(e.value < 0 ? Pressure.closing : tone.ink)
                      .copyWith(fontSize: entries.length > 1 ? 22 : 26),
                ),
              ),
          const SizedBox(height: Space.xxs),
          Text(
            'income minus what you owe, valued obligations only',
            style: Type.label(tone.inkFaint),
          ),
        ],
      ),
    );
  }

  static String _formatNet(int minorUnits, String currency) {
    final formatted = NumberFormat.simpleCurrency(name: currency)
        .format(minorUnits.abs() / 100);
    return minorUnits >= 0 ? '+$formatted' : '-$formatted';
  }
}
