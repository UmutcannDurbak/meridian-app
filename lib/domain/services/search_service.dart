import '../entities/obligation.dart';

/// FR-404 — search across every text field an obligation has: title,
/// counterparty, notes, and category. Case-insensitive substring match,
/// ORed across fields.
///
/// Drafts are excluded — an unconfirmed draft isn't a real record yet (see
/// ObligationStatus.draft), so it stays out of search the same way it stays
/// out of Horizon. Everything else is searchable regardless of status,
/// including resolved obligations — finding "what did we do about the
/// Acme lease last year" is a reasonable thing to want.
abstract final class SearchService {
  static List<Obligation> search(List<Obligation> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    return all
        .where((o) => o.status != ObligationStatus.draft && _matches(o, q))
        .toList()
      ..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
  }

  static bool _matches(Obligation o, String q) {
    if (o.title.toLowerCase().contains(q)) return true;
    if ((o.counterparty ?? '').toLowerCase().contains(q)) return true;
    if ((o.notes ?? '').toLowerCase().contains(q)) return true;
    if (o.category.label.toLowerCase().contains(q)) return true;
    return false;
  }
}
