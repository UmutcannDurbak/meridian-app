import 'package:drift/drift.dart';

import '../../domain/entities/obligation.dart';
import '../local/database.dart';
import 'obligation_repository_base.dart';

/// The only place `Obligation` ever gets serialised. Domain code stays free
/// of persistence concerns; this class is the seam between the two, and the
/// database it wraps is the single source of truth — there is no separate
/// in-memory copy to fall out of sync with it.
///
/// io platforms only — see repository_provider_io.dart. Web uses
/// InMemoryObligationRepository instead, since drift's native executor
/// needs dart:ffi, which doesn't exist in a browser.
class ObligationRepository implements ObligationRepositoryBase {
  ObligationRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Obligation>> watchAll() =>
      _db.select(_db.obligationRows).watch().map(
            (rows) => rows.map(_toDomain).toList(),
          );

  @override
  Future<List<Obligation>> loadAll() async =>
      (await _db.select(_db.obligationRows).get()).map(_toDomain).toList();

  @override
  Future<Obligation?> byId(String id) async {
    final row = await (_db.select(_db.obligationRows)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Insert or update. `createdAt` is preserved across updates — only a true
  /// first write sets it.
  @override
  Future<void> upsert(Obligation o) async {
    final now = DateTime.now();
    final existing = await (_db.select(_db.obligationRows)
          ..where((t) => t.id.equals(o.id)))
        .getSingleOrNull();
    await _db.into(_db.obligationRows).insertOnConflictUpdate(
          _toCompanion(o, createdAt: existing?.createdAt ?? now, updatedAt: now),
        );
  }

  /// Every item is a fresh insert (CSV import always mints new ids), so
  /// unlike [upsert] there's no existing row to preserve createdAt from.
  @override
  Future<void> upsertAll(List<Obligation> items) async {
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.obligationRows,
        items.map((o) => _toCompanion(o, createdAt: now, updatedAt: now)),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.obligationRows)..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> resolve(String id) async {
    await (_db.update(_db.obligationRows)..where((t) => t.id.equals(id)))
        .write(
      ObligationRowsCompanion(
        status: Value(ObligationStatus.resolved.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> snooze(String id, Duration by) async {
    final row = await (_db.select(_db.obligationRows)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.obligationRows)..where((t) => t.id.equals(id)))
        .write(
      ObligationRowsCompanion(
        expiryDate: Value(row.expiryDate.add(by)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  ObligationRowsCompanion _toCompanion(
    Obligation o, {
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return ObligationRowsCompanion(
      id: Value(o.id),
      title: Value(o.title),
      category: Value(o.category.name),
      expiryDate: Value(o.expiryDate),
      noticeDays: Value(o.noticeDays),
      noticeDaysAssumed: Value(o.noticeDaysAssumed),
      counterparty: Value(o.counterparty),
      valueMinorUnits: Value(o.value?.minorUnits),
      valueCurrency: Value(o.value?.currency),
      direction: Value(o.direction.name),
      autoRenews: Value(o.autoRenews),
      criticality: Value(o.criticality.name),
      status: Value(o.status.name),
      recurrenceFrequency: Value(o.recurrence?.frequency.name),
      recurrenceInterval: Value(o.recurrence?.interval),
      recurrenceUntil: Value(o.recurrence?.until),
      recurrenceCount: Value(o.recurrence?.count),
      assigneeId: Value(o.assigneeId),
      notes: Value(o.notes),
      attachmentIds: Value(o.attachmentIds.join(',')),
      createdVia: Value(o.createdVia.name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  Obligation _toDomain(ObligationRow r) {
    final frequencyName = r.recurrenceFrequency;
    return Obligation(
      id: r.id,
      title: r.title,
      category: _enumByName(
        ObligationCategory.values,
        r.category,
        ObligationCategory.other,
      ),
      expiryDate: r.expiryDate,
      noticeDays: r.noticeDays,
      noticeDaysAssumed: r.noticeDaysAssumed,
      counterparty: r.counterparty,
      value: r.valueMinorUnits != null && r.valueCurrency != null
          ? Money(r.valueMinorUnits!, r.valueCurrency!)
          : null,
      direction: _enumByName(
        MoneyDirection.values,
        r.direction,
        MoneyDirection.expense,
      ),
      autoRenews: r.autoRenews,
      criticality: _enumByName(
        Criticality.values,
        r.criticality,
        Criticality.important,
      ),
      status: _enumByName(
        ObligationStatus.values,
        r.status,
        ObligationStatus.dormant,
      ),
      recurrence: frequencyName == null
          ? null
          : RecurrenceRule(
              frequency:
                  _enumByName(Frequency.values, frequencyName, Frequency.none),
              interval: r.recurrenceInterval ?? 1,
              until: r.recurrenceUntil,
              count: r.recurrenceCount,
            ),
      assigneeId: r.assigneeId,
      notes: r.notes,
      attachmentIds:
          r.attachmentIds.isEmpty ? const [] : r.attachmentIds.split(','),
      createdVia: _enumByName(
        CaptureSource.values,
        r.createdVia,
        CaptureSource.manual,
      ),
    );
  }

  T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
