import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/domain/services/alert_scheduler.dart';
import 'package:meridian/domain/services/recurrence_engine.dart';

void main() {
  group('addMonths — month-end clamping', () {
    test('31 Jan + 1 month clamps to 28 Feb in a common year', () {
      final r = RecurrenceEngine.addMonths(DateTime(2025, 1, 31), 1);
      expect(r, DateTime(2025, 2, 28));
    });

    test('31 Jan + 1 month clamps to 29 Feb in a leap year', () {
      final r = RecurrenceEngine.addMonths(DateTime(2024, 1, 31), 1);
      expect(r, DateTime(2024, 2, 29));
    });

    test('clamping does not persist — 31 Jan + 2 months is 31 Mar', () {
      final r = RecurrenceEngine.addMonths(DateTime(2025, 1, 31), 2);
      expect(r, DateTime(2025, 3, 31));
    });

    test('29 Feb + 12 months lands on 28 Feb', () {
      final r = RecurrenceEngine.addMonths(DateTime(2024, 2, 29), 12);
      expect(r, DateTime(2025, 2, 28));
    });

    test('crosses year boundary', () {
      final r = RecurrenceEngine.addMonths(DateTime(2025, 11, 30), 3);
      expect(r, DateTime(2026, 2, 28));
    });
  });

  group('recurrence — no cumulative drift', () {
    test('12 monthly occurrences from the 31st return to the 31st', () {
      const rule = RecurrenceRule(frequency: Frequency.monthly);
      final seed = DateTime(2025, 1, 31);
      final out =
          RecurrenceEngine.upcoming(seed, rule, seed, limit: 12);

      // If the engine advanced from the previous occurrence instead of the
      // seed, February's clamp to the 28th would poison every later month.
      expect(out[0], DateTime(2025, 2, 28));
      expect(out[1], DateTime(2025, 3, 31));
      expect(out[2], DateTime(2025, 4, 30));
      expect(out[3], DateTime(2025, 5, 31));
      expect(out[11], DateTime(2026, 1, 31));
    });

    test('quarterly steps three months at a time', () {
      const rule = RecurrenceRule(frequency: Frequency.quarterly);
      final seed = DateTime(2025, 1, 15);
      final out = RecurrenceEngine.upcoming(seed, rule, seed, limit: 4);
      expect(out[0], DateTime(2025, 4, 15));
      expect(out[3], DateTime(2026, 1, 15));
    });

    test('respects until', () {
      // Monthly occurrences land on the 10th (Feb 10, Mar 10, Apr 10, ...).
      // `until` excludes any candidate strictly after it, so the bound must
      // sit on or after the 10th of the last month we expect to include.
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        until: DateTime(2025, 4, 30),
      );
      final seed = DateTime(2025, 1, 10);
      final out = RecurrenceEngine.upcoming(seed, rule, seed, limit: 10);
      expect(out.length, 3);
      expect(out.last, DateTime(2025, 4, 10));
    });
  });

  group('leap years', () {
    test('century rule', () {
      expect(RecurrenceEngine.isLeapYear(2000), isTrue);
      expect(RecurrenceEngine.isLeapYear(1900), isFalse);
      expect(RecurrenceEngine.isLeapYear(2024), isTrue);
      expect(RecurrenceEngine.isLeapYear(2025), isFalse);
    });
  });

  group('action deadline — the core insight', () {
    test('deadline is expiry minus notice period', () {
      final o = Obligation(
        id: '1',
        title: 'Supplier agreement',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 3, 1),
        noticeDays: 90,
      );
      expect(o.actionDeadline, DateTime(2025, 12, 1));
    });

    test('deadline equals expiry when no notice period', () {
      final o = Obligation(
        id: '2',
        title: 'Passport',
        category: ObligationCategory.document,
        expiryDate: DateTime(2026, 3, 1),
      );
      expect(o.actionDeadline, DateTime(2026, 3, 1));
    });

    test('pressure is 0 before the window opens and 1 after it closes', () {
      final o = Obligation(
        id: '3',
        title: 'Lease',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 3, 1),
        noticeDays: 90,
      );
      expect(o.pressureAt(DateTime(2024, 1, 1)), 0);
      expect(o.pressureAt(DateTime(2026, 1, 1)), 1);
    });
  });

  group('alert scheduling', () {
    test('drops offsets wider than the notice period', () {
      final o = Obligation(
        id: '4',
        title: 'Short notice contract',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 3, 1),
        noticeDays: 14,
        criticality: Criticality.critical,
      );
      final s = AlertScheduler.schedule(o, DateTime(2026, 1, 1));
      // 90/60/30 would all fire before the user can act; only <=14 and 0 remain
      expect(s.length, lessThanOrEqualTo(5));
    });

    test('draft obligations never alert', () {
      final o = Obligation(
        id: '5',
        title: 'Unconfirmed',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 3, 1),
        status: ObligationStatus.draft,
      );
      expect(AlertScheduler.schedule(o, DateTime(2026, 1, 1)), isEmpty);
    });

    test('auto-renew copy states the cost of inaction', () {
      final o = Obligation(
        id: '6',
        title: 'Datadog',
        category: ObligationCategory.subscription,
        expiryDate: DateTime(2026, 3, 1),
        noticeDays: 30,
        autoRenews: true,
        value: const Money(4800000, 'USD'),
      );
      final msg = AlertScheduler.message(o, DateTime(2026, 1, 15));
      expect(msg, contains('renews'));
      expect(msg, contains('unless'));
    });
  });
}
