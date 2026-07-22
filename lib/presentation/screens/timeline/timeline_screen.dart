import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../widgets/obligation_row.dart';
import '../capture/obligation_form_screen.dart';

/// FR-402 — a 12-month forward scroll, so something easy to miss in a
/// day-by-day view (a licence expiring in September) is visible today.
///
/// Deliberately excludes anything already overdue — that's Horizon's job.
/// This screen only looks forward, one month at a time, all twelve of them
/// shown even when empty: knowing a month is clear is itself useful here.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final months = ref.watch(timelineMonthsProvider);
    final stats = ref.watch(obligationStatsProvider);
    final now = ref.watch(nowProvider);
    final repo = ref.watch(obligationRepositoryProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.lg,
            Space.md,
            Space.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Text('Timeline', style: Type.display(tone.ink)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          sliver: SliverToBoxAdapter(child: _StatsHeader(stats: stats)),
        ),
        for (final bucket in months) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.lg,
                Space.md,
                Space.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMMMM().format(bucket.month).toUpperCase(),
                    style: Type.eyebrow(tone.inkMuted),
                  ),
                  if (bucket.items.isNotEmpty)
                    Text(
                      '${bucket.items.length}',
                      style: Type.eyebrow(tone.inkFaint),
                    ),
                ],
              ),
            ),
          ),
          if (bucket.items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  0,
                  Space.md,
                  Space.sm,
                ),
                child: Text('Nothing due', style: Type.label(tone.inkFaint)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              sliver: SliverList.separated(
                itemCount: bucket.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                itemBuilder: (context, i) {
                  final o = bucket.items[i];
                  return ObligationRow(
                    obligation: o,
                    now: now,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ObligationFormScreen(existing: o),
                      ),
                    ),
                    onResolve: () => repo.resolve(o.id),
                    onSnooze: () =>
                        repo.snooze(o.id, const Duration(days: 7)),
                    onDelete: () => repo.delete(o.id),
                  );
                },
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: Space.huge)),
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
    return Row(
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
            critical == 0
                ? 'nothing critical'
                : '$critical critical',
            style: Type.label(
              critical == 0 ? tone.inkFaint : Pressure.closing,
            ),
          ),
        ],
      ),
    );
  }
}
