import '../../domain/entities/obligation.dart';

/// The persistence seam the rest of the app depends on. Pure Dart, no
/// platform imports — this is what lets [obligationRepositoryProvider]
/// resolve to a different concrete implementation per platform (drift on
/// io platforms, in-memory on web) without any other file caring which one
/// it got. See repository_provider.dart.
abstract class ObligationRepositoryBase {
  Stream<List<Obligation>> watchAll();
  Future<List<Obligation>> loadAll();
  Future<Obligation?> byId(String id);
  Future<void> upsert(Obligation o);

  /// Bulk insert/update, e.g. for CSV import. Implementations should batch
  /// this rather than looping [upsert] — a spreadsheet import can be
  /// hundreds of rows.
  Future<void> upsertAll(List<Obligation> items);

  Future<void> delete(String id);
  Future<void> resolve(String id);
  Future<void> snooze(String id, Duration by);
}
