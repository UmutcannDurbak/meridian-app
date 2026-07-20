import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../widgets/obligation_row.dart';

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
                    onResolve: () => repo.resolve(o.id),
                    onSnooze: () =>
                        repo.snooze(o.id, const Duration(days: 7)),
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
