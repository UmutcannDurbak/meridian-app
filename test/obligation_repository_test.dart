import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/data/local/database.dart';
import 'package:meridian/data/repositories/obligation_repository.dart';
import 'package:meridian/domain/entities/obligation.dart';

void main() {
  late AppDatabase db;
  late ObligationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = ObligationRepository(db);
  });

  tearDown(() => db.close());

  test('round-trips every field through the database', () async {
    final o = Obligation(
      id: 'a1',
      title: 'Office lease',
      category: ObligationCategory.contract,
      expiryDate: DateTime(2026, 3, 1),
      noticeDays: 90,
      noticeDaysAssumed: true,
      counterparty: 'Acme Property Group',
      value: const Money(1250000, 'EUR'),
      direction: MoneyDirection.income,
      autoRenews: true,
      criticality: Criticality.critical,
      status: ObligationStatus.dormant,
      recurrence: const RecurrenceRule(
        frequency: Frequency.annual,
        interval: 1,
      ),
      assigneeId: 'user-2',
      notes: 'Renegotiate square footage',
      attachmentIds: const ['att-1', 'att-2'],
      createdVia: CaptureSource.scan,
    );

    await repo.upsert(o);
    final loaded = await repo.byId('a1');

    expect(loaded, isNotNull);
    expect(loaded!.title, 'Office lease');
    expect(loaded.category, ObligationCategory.contract);
    expect(loaded.expiryDate, DateTime(2026, 3, 1));
    expect(loaded.noticeDays, 90);
    expect(loaded.noticeDaysAssumed, isTrue);
    expect(loaded.counterparty, 'Acme Property Group');
    expect(loaded.value?.minorUnits, 1250000);
    expect(loaded.value?.currency, 'EUR');
    expect(loaded.direction, MoneyDirection.income);
    expect(loaded.autoRenews, isTrue);
    expect(loaded.criticality, Criticality.critical);
    expect(loaded.recurrence?.frequency, Frequency.annual);
    expect(loaded.assigneeId, 'user-2');
    expect(loaded.notes, 'Renegotiate square footage');
    expect(loaded.attachmentIds, ['att-1', 'att-2']);
    expect(loaded.createdVia, CaptureSource.scan);
  });

  test('watchAll emits on every write', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().map((l) => l.length).listen(emissions.add);

    await repo.upsert(
      Obligation(
        id: 'b1',
        title: 'Insurance',
        category: ObligationCategory.insurance,
        expiryDate: DateTime(2026, 6, 1),
      ),
    );
    await pumpEventQueue();

    await repo.resolve('b1');
    await pumpEventQueue();

    await sub.cancel();

    // Initial empty emission, then one after insert. drift re-emits on any
    // write to a watched table, so resolve() adds a third emission even
    // though it doesn't change the row count — only the status.
    expect(emissions, [0, 1, 1]);
    final resolved = await repo.byId('b1');
    expect(resolved?.status, ObligationStatus.resolved);
  });

  test('upsert preserves createdAt across updates', () async {
    final o = Obligation(
      id: 'c1',
      title: 'Domain renewal',
      category: ObligationCategory.subscription,
      expiryDate: DateTime(2026, 1, 1),
    );
    await repo.upsert(o);
    final row = await (db.select(db.obligationRows)
          ..where((t) => t.id.equals('c1')))
        .getSingle();
    final firstCreatedAt = row.createdAt;

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.upsert(o.copyWith(title: 'Domain renewal (renamed)'));

    final rowAfter = await (db.select(db.obligationRows)
          ..where((t) => t.id.equals('c1')))
        .getSingle();
    expect(rowAfter.createdAt, firstCreatedAt);
    expect(rowAfter.title, 'Domain renewal (renamed)');
  });

  test('snooze mutes the obligation without touching its real expiry date',
      () async {
    await repo.upsert(
      Obligation(
        id: 'd1',
        title: 'Certification',
        category: ObligationCategory.certification,
        expiryDate: DateTime(2026, 1, 10),
      ),
    );

    final before = DateTime.now();
    await repo.snooze('d1', const Duration(days: 7));
    final loaded = await repo.byId('d1');

    // The real deadline is untouched — snoozing must never silently rewrite
    // when the thing itself is actually due.
    expect(loaded?.expiryDate, DateTime(2026, 1, 10));
    expect(loaded?.snoozedUntil, isNotNull);
    expect(loaded!.isSnoozed(before.add(const Duration(days: 1))), isTrue);
    expect(loaded.isSnoozed(before.add(const Duration(days: 8))), isFalse);
  });

  test('delete removes the row', () async {
    await repo.upsert(
      Obligation(
        id: 'e1',
        title: 'Temp',
        category: ObligationCategory.other,
        expiryDate: DateTime(2026, 1, 1),
      ),
    );
    await repo.delete('e1');
    expect(await repo.byId('e1'), isNull);
  });

  test('upsertAll inserts a batch in one call', () async {
    await repo.upsertAll([
      Obligation(
        id: 'f1',
        title: 'Row one',
        category: ObligationCategory.contract,
        expiryDate: DateTime(2026, 1, 1),
      ),
      Obligation(
        id: 'f2',
        title: 'Row two',
        category: ObligationCategory.subscription,
        expiryDate: DateTime(2026, 2, 1),
      ),
    ]);

    final all = await repo.loadAll();
    expect(all.map((o) => o.id), containsAll(['f1', 'f2']));
    expect(all.firstWhere((o) => o.id == 'f2').title, 'Row two');
  });
}
