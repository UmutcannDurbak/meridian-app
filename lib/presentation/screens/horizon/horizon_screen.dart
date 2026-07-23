import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/navigation_providers.dart';
import '../../../application/obligation_providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/obligation.dart';
import '../../screens/capture/obligation_form_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../widgets/obligation_row.dart';
import '../../widgets/pressable.dart';

/// The home screen, and the answer to one question: what needs me now?
///
/// Deliberately not a calendar grid. A calendar shows every day equally,
/// including the empty ones, which is exactly backwards for someone with 200
/// obligations. This is a prioritised list with the dead space removed.
///
/// No Scaffold of its own — [AppShell] owns the single Scaffold, bottom
/// nav, and capture FAB shared across Horizon/Timeline/Exposure.
class HorizonScreen extends ConsumerWidget {
  const HorizonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAll = ref.watch(obligationListProvider);

    return asyncAll.when(
      loading: () => const _HorizonSkeleton(),
      error: (error, stack) => _ErrorState(
        message: AppStrings.of(context).errorLoad,
      ),
      data: (_) => const _HorizonList(),
    );
  }
}

class _HorizonList extends ConsumerWidget {
  const _HorizonList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    final grouped = ref.watch(horizonGroupsProvider);
    final overflowCount = ref.watch(horizonOverflowCountProvider);
    final drafts = ref.watch(draftListProvider);
    final now = ref.watch(nowProvider);
    final repo = ref.watch(obligationRepositoryProvider);

    if (grouped.isEmpty && drafts.isEmpty && overflowCount == 0) {
      return const _Empty();
    }

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.horizonTitle, style: Type.display(tone.ink)),
                IconButton(
                  icon: Icon(CupertinoIcons.search, color: tone.inkMuted),
                  tooltip: s.searchTooltip,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SearchScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (drafts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                0,
                Space.md,
                Space.md,
              ),
              child: _DraftBanner(
                text: s.draftBanner(drafts.length, drafts.first.title),
                first: drafts.first,
              ),
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
                    _groupLabel(s, group.kind).toUpperCase(),
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            sliver: SliverList.separated(
              itemCount: group.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) {
                final o = group.items[i];
                return ObligationRow(
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
                );
              },
            ),
          ),
        ],
        if (overflowCount > 0)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.lg,
              Space.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _OverflowLink(count: overflowCount),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.huge)),
      ],
    );
  }
}

String _groupLabel(AppStrings s, HorizonGroupKind kind) => switch (kind) {
      HorizonGroupKind.overdue => s.groupOverdue,
      HorizonGroupKind.thisWeek => s.groupThisWeek,
      HorizonGroupKind.thisMonth => s.groupThisMonth,
    };

/// Points at what Horizon deliberately leaves off — obligations due beyond
/// [horizonWindowDays] are real, just not imminent. See
/// horizonOverflowCountProvider for why they're not just piled up here
/// under a "Later" heading instead.
class _OverflowLink extends ConsumerWidget {
  const _OverflowLink({required this.count});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    return Pressable(
      onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: tone.hairline),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, size: 16, color: tone.inkMuted),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                s.overflowLink(count),
                style: Type.label(tone.inkMuted),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16, color: tone.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Unconfirmed captures are never alerted, never auto-deleted, and never
/// treated as live obligations — but they also must not be forgotten. This
/// is how a user finds their way back to one. See ObligationStatus.draft.
class _DraftBanner extends StatelessWidget {
  const _DraftBanner({required this.text, required this.first});
  final String text;
  final Obligation first;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Pressable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ObligationFormScreen(draft: first),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: tone.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.paper,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(
                CupertinoIcons.doc_text,
                size: 16,
                color: tone.inkMuted,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(text, style: Type.label(tone.ink)),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16, color: tone.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Loading state. A skeleton, never a spinner — see NFR on required states.
class _HorizonSkeleton extends StatelessWidget {
  const _HorizonSkeleton();

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(tone.surface, 120, 28),
          const SizedBox(height: Space.xl),
          _bar(tone.surface, 80, 12),
          const SizedBox(height: Space.md),
          for (var i = 0; i < 4; i++) ...[
            _bar(tone.surface, double.infinity, 56),
            const SizedBox(height: Space.sm),
          ],
        ],
      ),
    );
  }

  Widget _bar(Color color, double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(
          message,
          style: Type.body(tone.inkMuted),
          textAlign: TextAlign.center,
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
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.surface,
                shape: BoxShape.circle,
                border: Border.all(color: tone.hairline),
              ),
              child: Icon(
                CupertinoIcons.checkmark_seal,
                size: 28,
                color: tone.inkFaint,
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(
              s.emptyTitle,
              style: Type.title(tone.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              s.emptyBody,
              style: Type.body(tone.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
