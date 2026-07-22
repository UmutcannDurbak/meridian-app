import 'dart:async';

import '../../domain/entities/obligation.dart';
import 'obligation_repository_base.dart';

/// Web preview only. There is no drift/sqlite3 backend for web in this
/// project yet — that needs drift's WASM executor plus a bundled
/// sqlite3.wasm asset, which is real work for another pass. This exists
/// purely so the web build compiles and is usable to look at: data lives
/// for the lifetime of the browser tab and resets on reload.
///
/// Every real platform (Android, iOS, desktop) uses [ObligationRepository]
/// instead — see repository_provider_io.dart / repository_provider_web.dart.
class InMemoryObligationRepository implements ObligationRepositoryBase {
  InMemoryObligationRepository({bool seedDemoData = true}) {
    if (seedDemoData) _seed();
  }

  final _items = <String, Obligation>{};
  final _controller = StreamController<List<Obligation>>.broadcast();

  void _emit() => _controller.add(_items.values.toList(growable: false));

  void _seed() {
    final now = DateTime.now();
    final demo = [
      Obligation(
        id: 'demo-1',
        title: 'Office lease renewal',
        category: ObligationCategory.contract,
        expiryDate: now.add(const Duration(days: 90)),
        noticeDays: 90,
        counterparty: 'Acme Property Group',
        value: const Money(1250000, 'EUR'),
        autoRenews: true,
        criticality: Criticality.critical,
      ),
      Obligation(
        id: 'demo-2',
        title: 'Datadog subscription',
        category: ObligationCategory.subscription,
        expiryDate: now.add(const Duration(days: 33)),
        noticeDays: 30,
        counterparty: 'Datadog Inc.',
        value: const Money(480000, 'USD'),
        autoRenews: true,
      ),
      Obligation(
        id: 'demo-3',
        title: 'Fire inspection certificate',
        category: ObligationCategory.certification,
        expiryDate: now.add(const Duration(days: 3)),
        criticality: Criticality.important,
      ),
      Obligation(
        id: 'demo-4',
        title: 'Passport renewal',
        category: ObligationCategory.document,
        expiryDate: now.subtract(const Duration(days: 2)),
        criticality: Criticality.routine,
      ),
      Obligation(
        id: 'demo-5',
        title: 'Client retainer — Bellwether Co.',
        category: ObligationCategory.payment,
        expiryDate: now.add(const Duration(days: 10)),
        counterparty: 'Bellwether Co.',
        value: const Money(600000, 'USD'),
        direction: MoneyDirection.income,
        criticality: Criticality.routine,
      ),
    ];
    for (final o in demo) {
      _items[o.id] = o;
    }
  }

  @override
  Stream<List<Obligation>> watchAll() {
    // New listeners see current state immediately, matching drift's
    // watch() semantics (which emits once on subscribe).
    return Stream.multi((controller) {
      controller.add(_items.values.toList(growable: false));
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<List<Obligation>> loadAll() async =>
      _items.values.toList(growable: false);

  @override
  Future<Obligation?> byId(String id) async => _items[id];

  @override
  Future<void> upsert(Obligation o) async {
    _items[o.id] = o;
    _emit();
  }

  @override
  Future<void> upsertAll(List<Obligation> items) async {
    for (final o in items) {
      _items[o.id] = o;
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _emit();
  }

  @override
  Future<void> resolve(String id) async {
    final o = _items[id];
    if (o == null) return;
    _items[id] = o.copyWith(status: ObligationStatus.resolved);
    _emit();
  }

  @override
  Future<void> snooze(String id, Duration by) async {
    final o = _items[id];
    if (o == null) return;
    _items[id] = o.copyWith(expiryDate: o.expiryDate.add(by));
    _emit();
  }
}
