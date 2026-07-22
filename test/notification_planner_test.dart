import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/domain/services/alert_scheduler.dart';
import 'package:meridian/domain/services/notification_planner.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Obligation obligation({
    String id = 'o-1',
    Criticality criticality = Criticality.important,
    ObligationStatus status = ObligationStatus.dormant,
  }) =>
      Obligation(
        id: id,
        title: 'Server lease',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 3, 1),
        noticeDays: 30,
        criticality: criticality,
        status: status,
      );

  group('NotificationPlanner.plan', () {
    test('produces one planned notification per alert instant', () {
      final o = obligation();
      final expectedInstants = AlertScheduler.schedule(o, now);

      final plan = NotificationPlanner.plan([o], now);

      expect(plan.length, expectedInstants.length);
      expect(plan.map((p) => p.at), expectedInstants);
    });

    test('drops obligations with no schedule (drafts) entirely', () {
      final draft = obligation(status: ObligationStatus.draft);
      expect(NotificationPlanner.plan([draft], now), isEmpty);
    });

    test('ids are stable across repeated calls for the same input', () {
      final o = obligation();
      final first = NotificationPlanner.plan([o], now);
      final second = NotificationPlanner.plan([o], now);

      expect(first.map((p) => p.id), second.map((p) => p.id));
    });

    test('ids differ between two different obligations', () {
      final a = obligation(id: 'a');
      final b = obligation(id: 'b');

      final plan = NotificationPlanner.plan([a, b], now);
      final ids = plan.map((p) => p.id).toSet();

      expect(ids.length, plan.length); // no collisions
    });

    test('ids differ between two instants of the same obligation', () {
      final o = obligation(criticality: Criticality.critical);
      final plan = NotificationPlanner.plan([o], now);

      expect(plan.length, greaterThan(1));
      expect(plan.map((p) => p.id).toSet().length, plan.length);
    });

    test('every planned id is a non-negative 32-bit int', () {
      final o = obligation(criticality: Criticality.critical);
      final plan = NotificationPlanner.plan([o], now);

      for (final p in plan) {
        expect(p.id, greaterThanOrEqualTo(0));
        expect(p.id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('carries the obligation title and a non-empty message body', () {
      final o = obligation();
      final plan = NotificationPlanner.plan([o], now);

      expect(plan, isNotEmpty);
      for (final p in plan) {
        expect(p.title, 'Server lease');
        expect(p.obligationId, 'o-1');
        expect(p.body, isNotEmpty);
      }
    });

    test('empty obligation list plans nothing', () {
      expect(NotificationPlanner.plan(const [], now), isEmpty);
    });
  });
}
