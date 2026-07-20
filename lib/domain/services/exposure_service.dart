import '../entities/obligation.dart';
import 'timeline_service.dart';

/// One month's committed value, grouped by currency rather than summed
/// across them — a $40,000 obligation and a €40,000 one are not the same
/// $80,000, and this product doesn't get to pretend otherwise until it
/// actually does currency conversion.
class MonthExposure {
  const MonthExposure(this.month, this.totalsByCurrency, this.itemCount);

  final DateTime month;

  /// Currency code -> total minor units for obligations with a value.
  final Map<String, int> totalsByCurrency;

  /// Obligations in this month that carry a monetary value at all.
  final int itemCount;
}

/// FR-403 — the forecast that turns the register from a reminder list into
/// a financial instrument: how much committed spend is entering its action
/// window, and when.
abstract final class ExposureService {
  static List<MonthExposure> fromBuckets(List<MonthBucket> buckets) {
    return [
      for (final b in buckets)
        MonthExposure(
          b.month,
          _sumByCurrency(b.items),
          b.items.where((o) => o.value != null).length,
        ),
    ];
  }

  static Map<String, int> _sumByCurrency(List<Obligation> items) {
    final totals = <String, int>{};
    for (final o in items) {
      final v = o.value;
      if (v == null) continue;
      totals[v.currency] = (totals[v.currency] ?? 0) + v.minorUnits;
    }
    return totals;
  }
}
