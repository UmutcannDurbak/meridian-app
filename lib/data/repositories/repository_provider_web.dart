import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'in_memory_obligation_repository.dart';
import 'obligation_repository_base.dart';

/// Web has no persistence backend yet — see
/// in_memory_obligation_repository.dart for why. No databaseProvider here;
/// there's nothing to inject, and tests never target web.
final obligationRepositoryProvider = Provider<ObligationRepositoryBase>((ref) {
  return InMemoryObligationRepository();
});
