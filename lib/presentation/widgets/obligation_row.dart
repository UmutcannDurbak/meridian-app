import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../../domain/entities/obligation.dart';
import 'action_window_bar.dart';

/// A single line in the Horizon.
///
/// The most frequent interaction in the product is resolving or deferring from
/// this row without opening anything. If a user has to navigate to a detail
/// screen to clear an item, the product feels like work — which for this
/// audience is fatal. Hence swipe actions on every row.
class ObligationRow extends StatelessWidget {
  const ObligationRow({
    super.key,
    required this.obligation,
    required this.now,
    this.onTap,
    this.onResolve,
    this.onSnooze,
  });

  final Obligation obligation;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;
  final VoidCallback? onSnooze;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final o = obligation;
    final days = o.daysUntilAction(now);
    final pressure = o.pressureAt(now);

    return Dismissible(
      key: ValueKey(o.id),
      background: _swipeBg(context, Alignment.centerLeft, 'Resolve'),
      secondaryBackground: _swipeBg(context, Alignment.centerRight, 'Snooze'),
      confirmDismiss: (dir) async {
        HapticFeedback.mediumImpact();
        if (dir == DismissDirection.startToEnd) {
          onResolve?.call();
        } else {
          onSnooze?.call();
        }
        return false; // parent controls removal after state update
      },
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      Text(_dayLabel(days), style: Type.numeric(tone.ink)),
                      const SizedBox(height: Space.xxs),
                      Text(
                        DateFormat.MMMd().format(o.actionDeadline),
                        style: Type.label(tone.inkFaint),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              ActionWindowBar(
                pressure: pressure,
                windowStartFraction: o.noticeDays > 0 ? 0.35 : 0.0,
              ),
              if (o.autoRenews || o.noticeDaysAssumed) ...[
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    if (o.autoRenews)
                      _tag(context, 'Renews unless cancelled'),
                    if (o.noticeDaysAssumed) ...[
                      if (o.autoRenews) const SizedBox(width: Space.sm),
                      // Surfaced deliberately: an assumed notice period that is
                      // wrong is the one way this product can actively mislead.
                      _tag(context, 'Notice period assumed'),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _dayLabel(int days) {
    if (days < 0) return '${-days}d over';
    if (days == 0) return 'Today';
    return '${days}d';
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

  Widget _swipeBg(BuildContext context, Alignment a, String label) {
    final tone = context.tone;
    return Container(
      alignment: a,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      color: tone.surface,
      child: Text(label, style: Type.eyebrow(tone.inkMuted)),
    );
  }
}
