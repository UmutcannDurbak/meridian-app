import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../widgets/obligation_row.dart';

/// The home screen, and the answer to one question: what needs me now?
///
/// Deliberately not a calendar grid. A calendar shows every day equally,
/// including the empty ones, which is exactly backwards for someone with 200
/// obligations. This is a prioritised list with the dead space removed.
class HorizonScreen extends ConsumerWidget {
  const HorizonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final grouped = ref.watch(horizonGroupsProvider);
    final now = ref.watch(nowProvider);

    return Scaffold(
      body: SafeArea(
        child: grouped.isEmpty
            ? const _Empty()
            : CustomScrollView(
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
                      child: Text('Horizon', style: Type.display(tone.ink)),
                    ),
                  ),
                  for (final group in grouped) ...[
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
                              group.label.toUpperCase(),
                              style: Type.eyebrow(tone.inkMuted),
                            ),
                            Text(
                              '${group.items.length}',
                              style: Type.eyebrow(tone.inkFaint),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList.separated(
                      itemCount: group.items.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: tone.hairline, height: 1),
                      itemBuilder: (context, i) {
                        final o = group.items[i];
                        return ObligationRow(
                          obligation: o,
                          now: now,
                          onResolve: () => ref
                              .read(obligationListProvider.notifier)
                              .resolve(o.id),
                          onSnooze: () => ref
                              .read(obligationListProvider.notifier)
                              .snooze(o.id, const Duration(days: 7)),
                        );
                      },
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Space.huge),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The first screen a new user sees. An invitation, not a failure.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nothing is waiting on you.',
              style: Type.title(tone.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Add your first contract or renewal and Meridian will tell you '
              'when you need to act — not when it is already too late.',
              style: Type.body(tone.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
