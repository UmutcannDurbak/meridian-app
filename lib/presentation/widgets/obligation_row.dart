import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../../domain/entities/obligation.dart';
import 'action_window_bar.dart';
import 'obligation_action_sheet.dart';
import 'pressable.dart';

/// A single line in the Horizon.
///
/// The most frequent interaction in the product is resolving or deferring from
/// this row without opening anything, so swipe covers those two. Everything
/// else a row can do — edit, delete — lives one long-press away in
/// [showObligationActionSheet] rather than crowding the row itself.
class ObligationRow extends StatelessWidget {
  const ObligationRow({
    super.key,
    required this.obligation,
    required this.now,
    this.onTap,
    this.onResolve,
    this.onSnooze,
    this.onDelete,
  });

  final Obligation obligation;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;
  final VoidCallback? onSnooze;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    final o = obligation;
    final days = o.daysUntilAction(now);
    final pressure = o.pressureAt(now);

    return Dismissible(
      key: ValueKey(o.id),
      background: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: _swipeBg(
          context,
          Alignment.centerLeft,
          CupertinoIcons.checkmark_alt,
          s.actionResolve,
          filled: true,
        ),
      ),
      secondaryBackground: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: _swipeBg(
          context,
          Alignment.centerRight,
          CupertinoIcons.clock,
          s.actionSnooze,
          filled: false,
        ),
      ),
      confirmDismiss: (dir) async {
        HapticFeedback.mediumImpact();
        if (dir == DismissDirection.startToEnd) {
          onResolve?.call();
        } else {
          onSnooze?.call();
        }
        return false; // parent controls removal after state update
      },
      // Swipe-to-resolve/snooze doesn't reach a screen-reader user — that
      // gesture is claimed by VoiceOver/TalkBack for their own navigation.
      // Resolve and Snooze are exposed here as custom actions instead, so
      // they're reachable without the gesture at all. Delete stays behind
      // the long-press action sheet either way — it already asks for
      // confirmation there, and a raw custom action bypassing that would
      // make deleting less safe for a screen-reader user, not more
      // accessible.
      child: Semantics(
        label: _semanticLabel(s),
        button: true,
        onTap: onTap,
        onLongPress: _openActionSheet(context),
        customSemanticsActions: {
          if (onResolve case final resolve?)
            CustomSemanticsAction(label: s.actionResolve): resolve,
          if (onSnooze case final snooze?)
            CustomSemanticsAction(label: s.actionSnooze7): snooze,
        },
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          onLongPress: onTap == null ? null : _openActionSheet(context),
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: tone.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: tone.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tone.paper,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Icon(
                        _categoryIcon(o.category),
                        size: 17,
                        color: tone.inkMuted,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.title,
                            style: Type.heading(tone.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (o.counterparty != null) ...[
                            const SizedBox(height: Space.xxs),
                            Text(
                              o.counterparty!,
                              style: Type.label(tone.inkMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(s.dayLabel(days), style: Type.numeric(tone.ink)),
                        const SizedBox(height: Space.xxs),
                        Text(
                          DateFormat.MMMd().format(o.actionDeadline),
                          style: Type.label(tone.inkMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                ActionWindowBar(
                  pressure: pressure,
                  windowStartFraction: o.noticeDays > 0 ? 0.35 : 0.0,
                ),
                if (o.autoRenews || o.noticeDaysAssumed || o.isSnoozed(now)) ...[
                  const SizedBox(height: Space.sm),
                  // Wrap, not Row — two tags fit on one line at normal text
                  // size but not at a larger accessibility size, and this
                  // should reflow rather than overflow when that happens.
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.xs,
                    children: [
                      if (o.autoRenews) _tag(context, _renewalTag(o, s)),
                      if (o.noticeDaysAssumed)
                        // Surfaced deliberately: an assumed notice period
                        // that is wrong is the one way this product can
                        // actively mislead.
                        _tag(context, s.tagNoticeAssumed),
                      if (o.isSnoozed(now))
                        _tag(
                          context,
                          s.snoozedUntil(
                            DateFormat.MMMd().format(o.snoozedUntil!),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(ObligationCategory c) => switch (c) {
        ObligationCategory.contract => CupertinoIcons.doc_text,
        ObligationCategory.subscription => CupertinoIcons.arrow_2_circlepath,
        ObligationCategory.payment => CupertinoIcons.money_dollar,
        ObligationCategory.insurance => CupertinoIcons.shield,
        ObligationCategory.licence => CupertinoIcons.rosette,
        ObligationCategory.certification => CupertinoIcons.checkmark_seal,
        ObligationCategory.maintenance => CupertinoIcons.wrench,
        ObligationCategory.tax => CupertinoIcons.percent,
        ObligationCategory.warranty => CupertinoIcons.shield_lefthalf_fill,
        ObligationCategory.document => CupertinoIcons.doc,
        ObligationCategory.commitment => CupertinoIcons.person_2,
        ObligationCategory.other => CupertinoIcons.ellipsis_circle,
      };

  /// "Renews unless cancelled" on its own doesn't answer the question users
  /// actually have — renews *when*? If a period was picked, say it.
  ///
  /// The generic fallback is localized via [AppStrings.tagAutoRenews]; the
  /// specific period phrasing ("monthly", "every 2 weeks") is not yet — see
  /// AppStrings' doc comment for the screens this pass covers.
  static String _renewalTag(Obligation o, AppStrings s) {
    final rule = o.recurrence;
    if (rule == null) return s.tagAutoRenews;
    final period = switch (rule.frequency) {
      Frequency.weekly =>
        rule.interval == 1 ? 'weekly' : 'every ${rule.interval} weeks',
      Frequency.monthly =>
        rule.interval == 1 ? 'monthly' : 'every ${rule.interval} months',
      Frequency.quarterly =>
        rule.interval == 1 ? 'quarterly' : 'every ${rule.interval} quarters',
      Frequency.annual =>
        rule.interval == 1 ? 'annually' : 'every ${rule.interval} years',
      Frequency.custom => 'every ${rule.interval} days',
      Frequency.daily => 'daily',
      Frequency.none => null,
    };
    return period == null ? s.tagAutoRenews : 'Renews $period unless cancelled';
  }

  /// One coherent sentence a screen reader announces for the whole row,
  /// standing in for the several separate Text widgets excludeSemantics
  /// hides — otherwise a screen reader would read the title, counterparty,
  /// day label, and exact date as four disconnected fragments.
  String _semanticLabel(AppStrings s) {
    final o = obligation;
    final days = o.daysUntilAction(now);
    final urgency = days < 0
        ? '${-days} days overdue'
        : days == 0
            ? 'due today'
            : 'due in $days days';
    final parts = <String>[
      o.title,
      if (o.counterparty != null) o.counterparty!,
      urgency,
      o.category.label,
      if (o.autoRenews) _renewalTag(o, s),
      if (o.noticeDaysAssumed) s.tagNoticeAssumed,
    ];
    return parts.join('. ');
  }

  VoidCallback? _openActionSheet(BuildContext context) {
    if (onTap == null) return null;
    return () {
      HapticFeedback.mediumImpact();
      showObligationActionSheet(
        context,
        onEdit: () => onTap?.call(),
        onSnooze: () => onSnooze?.call(),
        onResolve: () => onResolve?.call(),
        onDelete: () => onDelete?.call(),
      );
    };
  }

  Widget _tag(BuildContext context, String text) {
    final tone = context.tone;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xxs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: tone.hairline),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(text, style: Type.eyebrow(tone.inkMuted)),
    );
  }

  Widget _swipeBg(
    BuildContext context,
    Alignment a,
    IconData icon,
    String label, {
    required bool filled,
  }) {
    final tone = context.tone;
    final fg = filled ? tone.paper : tone.ink;
    final iconAndLabel = [
      Icon(icon, size: 16, color: fg),
      const SizedBox(width: Space.xs),
      Text(label, style: Type.eyebrow(fg)),
    ];
    return Container(
      alignment: a,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      color: filled ? tone.ink : tone.surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: a == Alignment.centerRight
            ? iconAndLabel.reversed.toList()
            : iconAndLabel,
      ),
    );
  }
}
