import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import 'obligation_repository.dart';
import 'obligation_repository_base.dart';

/// Real on-disk database by default. Tests override this with
/// [AppDatabase.forTesting] so they never touch a real file or leak state
/// between runs.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final obligationRepositoryProvider = Provider<ObligationRepositoryBase>((ref) {
  return ObligationRepository(ref.watch(databaseProvider));
});
