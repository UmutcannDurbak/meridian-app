import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/domain/services/obligation_stats.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Obligation obligation({
    required String id,
    required int daysUntil,
    Criticality criticality = Criticality.important,
    ObligationStatus status = ObligationStatus.dormant,
    Money? value,
    MoneyDirection direction = MoneyDirection.expense,
  }) =>
      Obligation(
        id: id,
        title: 'Item $id',
        category: ObligationCategory.contract,
        expiryDate: now.add(Duration(days: daysUntil)),
        criticality: criticality,
        status: status,
        value: value,
        direction: direction,
      );

  group('ObligationStatsService.compute', () {
    test('counts items within 7 days as this week', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: 0),
          obligation(id: 'b', daysUntil: 7),
          obligation(id: 'c', daysUntil: 8),
        ],
        now,
      );

      expect(stats.thisWeekCount, 2);
      expect(stats.thisMonthCount, 3);
    });

    test('excludes overdue items from both windows', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: -1),
        ],
        now,
      );

      expect(stats.thisWeekCount, 0);
      expect(stats.thisMonthCount, 0);
    });

    test('excludes resolved, dismissed, and draft obligations', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: 1, status: ObligationStatus.resolved),
          obligation(id: 'b', daysUntil: 1, status: ObligationStatus.dismissed),
          obligation(id: 'c', daysUntil: 1, status: ObligationStatus.draft),
        ],
        now,
      );

      expect(stats.thisWeekCount, 0);
      expect(stats.thisMonthCount, 0);
    });

    test('this month is a superset of this week, not exclusive of it', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: 2),
        ],
        now,
      );

      expect(stats.thisWeekCount, 1);
      expect(stats.thisMonthCount, 1);
    });

    test('breaks out critical counts separately within each window', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: 2, criticality: Criticality.critical),
          obligation(id: 'b', daysUntil: 2, criticality: Criticality.routine),
          obligation(id: 'c', daysUntil: 20, criticality: Criticality.critical),
        ],
        now,
      );

      expect(stats.thisWeekCount, 2);
      expect(stats.thisWeekCritical, 1);
      expect(stats.thisMonthCount, 3);
      expect(stats.thisMonthCritical, 2);
    });

    test('an item beyond 31 days counts in neither window', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: 32),
        ],
        now,
      );

      expect(stats.thisWeekCount, 0);
      expect(stats.thisMonthCount, 0);
    });

    test('empty list produces all-zero stats', () {
      final stats = ObligationStatsService.compute(
        const [],
        now,
      );

      expect(stats.thisWeekCount, 0);
      expect(stats.thisWeekCritical, 0);
      expect(stats.thisMonthCount, 0);
      expect(stats.thisMonthCritical, 0);
      expect(stats.netByCurrencyThisMonth, isEmpty);
    });

    test('income adds and expense subtracts, within this month', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(
            id: 'a',
            daysUntil: 2,
            value: const Money(100000, 'USD'),
          ),
          obligation(
            id: 'b',
            daysUntil: 2,
            value: const Money(30000, 'USD'),
            direction: MoneyDirection.income,
          ),
        ],
        now,
      );

      expect(stats.netByCurrencyThisMonth, {'USD': -70000});
    });

    test('keeps currencies separate rather than summing them', () {
      final stats = ObligationStatsService.compute(
        [
          obligation(id: 'a', daysUntil: 2, value: const Money(5000, 'USD')),
          obligation(
            id: 'b',
            daysUntil: 2,
            value: const Money(3000, 'EUR'),
            direction: MoneyDirection.income,
          ),
        ],
        now,
      );

      expect(stats.netByCurrencyThisMonth, {'USD': -5000, 'EUR': 3000});
    });

    test('obligations without a value contribute nothing to net', () {
      final stats = ObligationStatsService.compute(
        [obligation(id: 'a', daysUntil: 2)],
        now,
      );

      expect(stats.netByCurrencyThisMonth, isEmpty);
    });

    test('a valued obligation beyond this month is excluded from net', () {
      final stats = ObligationStatsService.compute(
        [obligation(id: 'a', daysUntil: 45, value: const Money(1000, 'USD'))],
        now,
      );

      expect(stats.netByCurrencyThisMonth, isEmpty);
    });
  });
}
