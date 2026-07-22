import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../../domain/entities/obligation.dart';
import 'pressable.dart';

/// A month grid — the day-level view Timeline's flat monthly list didn't
/// have. Monday-start, same ISO convention this app's forward-only month
/// buckets already imply. Deliberately dumb: it only knows how to lay out
/// and highlight days, all state (which month, which day is selected)
/// lives in the caller.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.itemsByDay,
    required this.now,
    required this.selectedDay,
    required this.onSelectDay,
  });

  /// First-of-month is enough — only year/month are read.
  final DateTime month;
  final Map<int, List<Obligation>> itemsByDay;
  final DateTime now;
  final int? selectedDay;
  final ValueChanged<int> onSelectDay;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday=1 -> 0 blanks
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    return Column(
      children: [
        Row(
          children: [
            for (final l in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(l, style: Type.eyebrow(tone.inkFaint)),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: Space.xxs,
            crossAxisSpacing: Space.xxs,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, i) {
            if (i < leadingBlanks) return const SizedBox.shrink();
            final day = i - leadingBlanks + 1;
            final items = itemsByDay[day] ?? const [];
            return _DayCell(
              day: day,
              items: items,
              isToday: isCurrentMonth && now.day == day,
              isSelected: selectedDay == day,
              now: now,
              onTap: () => onSelectDay(day),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.items,
    required this.isToday,
    required this.isSelected,
    required this.now,
    required this.onTap,
  });

  final int day;
  final List<Obligation> items;
  final bool isToday;
  final bool isSelected;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final numberColor = isSelected ? tone.paper : tone.ink;

    Color? dotColor;
    if (items.isNotEmpty) {
      final maxPressure = items
          .map((o) => o.pressureAt(now))
          .reduce((a, b) => a > b ? a : b);
      dotColor = Pressure.at(maxPressure);
    }

    return Pressable(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? tone.ink : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: tone.ink, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$day', style: Type.numeric(numberColor)),
              const SizedBox(height: 2),
              SizedBox(
                width: 5,
                height: 5,
                child: dotColor == null
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Month navigation row — "‹  July 2026  ›" — bounded by the caller to
/// whatever forward window it has data for.
class MonthNav extends StatelessWidget {
  const MonthNav({
    super.key,
    required this.label,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final String label;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavArrow(
          icon: CupertinoIcons.chevron_left,
          enabled: canGoBack,
          onTap: onBack,
        ),
        Text(label, style: Type.heading(tone.ink)),
        _NavArrow(
          icon: CupertinoIcons.chevron_right,
          enabled: canGoForward,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Pressable(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? tone.ink : tone.inkFaint,
        ),
      ),
    );
  }
}
