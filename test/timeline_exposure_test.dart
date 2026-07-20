import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/domain/services/exposure_service.dart';
import 'package:meridian/domain/services/timeline_service.dart';

void main() {
  group('TimelineService.monthBuckets', () {
    test('returns 12 months starting at the current month by default', () {
      final now = DateTime(2026, 3, 15);
      final buckets = TimelineService.monthBuckets(const [], now);
      expect(buckets, hasLength(12));
      expect(buckets.first.month, DateTime(2026, 3));
      expect(buckets.last.month, DateTime(2027, 2));
    });

    test('places an obligation in the bucket matching its action deadline', () {
      final now = DateTime(2026, 3, 15);
      final o = Obligation(
        id: '1',
        title: 'Lease',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 6, 1),
        noticeDays: 30,
      ); // actionDeadline = 2 May 2026
      final buckets = TimelineService.monthBuckets([o], now);
      final mayBucket = buckets.firstWhere((b) => b.month.month == 5);
      expect(mayBucket.items, [o]);
    });

    test('excludes obligations already overdue relative to now', () {
      final now = DateTime(2026, 3, 15);
      final overdue = Obligation(
        id: '1',
        title: 'Past due',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 1, 1),
      );
      final buckets = TimelineService.monthBuckets([overdue], now);
      expect(buckets.every((b) => b.items.isEmpty), isTrue);
    });

    test('excludes resolved, dismissed, and draft obligations', () {
      final now = DateTime(2026, 3, 1);
      final base = Obligation(
        id: '1',
        title: 'X',
        category: ObligationCategory.other,
        expiryDate: DateTime(2026, 4, 1),
      );
      final buckets = TimelineService.monthBuckets(
        [
          base.copyWith(status: ObligationStatus.resolved),
          base.copyWith(status: ObligationStatus.dismissed),
          base.copyWith(status: ObligationStatus.draft),
        ],
        now,
      );
      expect(buckets.every((b) => b.items.isEmpty), isTrue);
    });

    test('includes a dormant/actionable obligation in its month', () {
      final now = DateTime(2026, 3, 1);
      final o = Obligation(
        id: '1',
        title: 'Live',
        category: ObligationCategory.other,
        expiryDate: DateTime(2026, 4, 15),
      );
      final buckets = TimelineService.monthBuckets([o], now);
      final aprilBucket = buckets.firstWhere((b) => b.month.month == 4);
      expect(aprilBucket.items, [o]);
    });

    test('items within a bucket are sorted by action deadline', () {
      final now = DateTime(2026, 3, 1);
      final later = Obligation(
        id: 'later',
        title: 'Later',
        category: ObligationCategory.other,
        expiryDate: DateTime(2026, 4, 20),
      );
      final earlier = Obligation(
        id: 'earlier',
        title: 'Earlier',
        category: ObligationCategory.other,
        expiryDate: DateTime(2026, 4, 5),
      );
      final buckets = TimelineService.monthBuckets([later, earlier], now);
      final aprilBucket = buckets.firstWhere((b) => b.month.month == 4);
      expect(aprilBucket.items.map((o) => o.id), ['earlier', 'later']);
    });
  });

  group('ExposureService.fromBuckets', () {
    test('sums obligation values by currency within a month', () {
      final now = DateTime(2026, 3, 1);
      final buckets = TimelineService.monthBuckets(
        [
          Obligation(
            id: '1',
            title: 'A',
            category: ObligationCategory.other,
            expiryDate: DateTime(2026, 4, 1),
            value: const Money(10000, 'USD'),
          ),
          Obligation(
            id: '2',
            title: 'B',
            category: ObligationCategory.other,
            expiryDate: DateTime(2026, 4, 15),
            value: const Money(25000, 'USD'),
          ),
          Obligation(
            id: '3',
            title: 'C',
            category: ObligationCategory.other,
            expiryDate: DateTime(2026, 4, 20),
            value: const Money(5000, 'EUR'),
          ),
        ],
        now,
      );

      final exposure = ExposureService.fromBuckets(buckets);
      final april = exposure.firstWhere((m) => m.month.month == 4);
      expect(april.totalsByCurrency['USD'], 35000);
      expect(april.totalsByCurrency['EUR'], 5000);
      expect(april.itemCount, 3);
    });

    test('obligations without a value contribute nothing', () {
      final now = DateTime(2026, 3, 1);
      final buckets = TimelineService.monthBuckets(
        [
          Obligation(
            id: '1',
            title: 'No value',
            category: ObligationCategory.other,
            expiryDate: DateTime(2026, 4, 1),
          ),
        ],
        now,
      );
      final exposure = ExposureService.fromBuckets(buckets);
      final april = exposure.firstWhere((m) => m.month.month == 4);
      expect(april.totalsByCurrency, isEmpty);
      expect(april.itemCount, 0);
    });

    test('a month with nothing produces an empty totals map, not an error', () {
      final exposure = ExposureService.fromBuckets(
        TimelineService.monthBuckets(
          const [],
          DateTime(2026, 3, 1),
        ),
      );
      expect(exposure, hasLength(12));
      expect(exposure.every((m) => m.totalsByCurrency.isEmpty), isTrue);
    });
  });
}
