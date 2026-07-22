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
  }) =>
      Obligation(
        id: id,
        title: 'Item $id',
        category: ObligationCategory.contract,
        expiryDate: now.add(Duration(days: daysUntil)),
        criticality: criticality,
        status: status,
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
    });
  });
}
