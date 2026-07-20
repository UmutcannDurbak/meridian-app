import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/obligation_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';

/// FR-403 — the forecast that turns the register from a list of reminders
/// into a financial instrument: how much committed spend is entering its
/// action window, and when.
///
/// Colour stays out of this screen entirely. The pressure ramp means one
/// thing — proximity to a deadline — and money is not that. Bars here are
/// tone-only, same rule as everywhere else in the app.
class ExposureScreen extends ConsumerWidget {
  const ExposureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final months = ref.watch(exposureMonthsProvider);

    final currencies = <String>{};
    for (final m in months) {
      currencies.addAll(m.totalsByCurrency.keys);
    }

    if (currencies.isEmpty) {
      return _Empty();
    }

    final sortedCurrencies = currencies.toList()..sort();
    final thisMonth = months.first;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.lg,
        Space.md,
        Space.huge,
      ),
      children: [
        Text('Exposure', style: Type.display(tone.ink)),
        const SizedBox(height: Space.lg),
        for (final currency in sortedCurrencies) ...[
          _TotalFigure(
            currency: currency,
            totalMinorUnits: months.fold(
              0,
              (sum, m) => sum + (m.totalsByCurrency[currency] ?? 0),
            ),
            thisMonthMinorUnits: thisMonth.totalsByCurrency[currency],
          ),
          const SizedBox(height: Space.lg),
          _MonthlyChart(months: months, currency: currency),
          const SizedBox(height: Space.xl),
        ],
      ],
    );
  }
}

class _TotalFigure extends StatelessWidget {
  const _TotalFigure({
    required this.currency,
    required this.totalMinorUnits,
    required this.thisMonthMinorUnits,
  });

  final String currency;
  final int totalMinorUnits;
  final int? thisMonthMinorUnits;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatMoney(totalMinorUnits, currency),
          style: Type.amount(tone.ink).copyWith(fontSize: 28),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          'committed over the next 12 months',
          style: Type.label(tone.inkMuted),
        ),
        if (thisMonthMinorUnits != null && thisMonthMinorUnits! > 0) ...[
          const SizedBox(height: Space.sm),
          Text(
            '${_formatMoney(thisMonthMinorUnits!, currency)} enters its '
            'action window this month',
            style: Type.label(tone.ink),
          ),
        ],
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months, required this.currency});

  final List<MonthExposure> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final values = [
      for (final m in months) m.totalsByCurrency[currency] ?? 0,
    ];
    final max = values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(currency, style: Type.eyebrow(tone.inkMuted)),
        const SizedBox(height: Space.sm),
        for (var i = 0; i < months.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _MonthBar(
              label: DateFormat.MMM().format(months[i].month),
              minorUnits: values[i],
              fraction: max == 0 ? 0 : values[i] / max,
              currency: currency,
            ),
          ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.minorUnits,
    required this.fraction,
    required this.currency,
  });

  final String label;
  final int minorUnits;
  final double fraction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: Type.label(tone.inkMuted)),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: tone.surface,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                  if (fraction > 0)
                    Container(
                      width: (constraints.maxWidth * fraction).clamp(
                        4.0,
                        constraints.maxWidth,
                      ),
                      height: 20,
                      decoration: BoxDecoration(
                        color: tone.ink,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: Space.sm),
        SizedBox(
          width: 92,
          child: Text(
            minorUnits == 0 ? '—' : _formatMoney(minorUnits, currency),
            style: Type.numeric(tone.ink),
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
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
                CupertinoIcons.chart_bar_square,
                size: 28,
                color: tone.inkFaint,
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(
              'Nothing with a value on the horizon.',
              style: Type.title(tone.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Add a value to an obligation and it will show up here as '
              'committed spend, forecast by month.',
              style: Type.body(tone.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(int minorUnits, String currency) {
  return NumberFormat.simpleCurrency(name: currency).format(minorUnits / 100);
}
