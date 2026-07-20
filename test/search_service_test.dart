import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/domain/services/search_service.dart';

void main() {
  Obligation build({
    required String id,
    required String title,
    String? counterparty,
    String? notes,
    ObligationCategory category = ObligationCategory.other,
    ObligationStatus status = ObligationStatus.dormant,
  }) {
    return Obligation(
      id: id,
      title: title,
      category: category,
      expiryDate: DateTime(2026, 1, 1),
      counterparty: counterparty,
      notes: notes,
      status: status,
    );
  }

  test('an empty query returns no results, not everything', () {
    final all = [build(id: '1', title: 'Office lease')];
    expect(SearchService.search(all, ''), isEmpty);
    expect(SearchService.search(all, '   '), isEmpty);
  });

  test('matches title case-insensitively', () {
    final all = [build(id: '1', title: 'Office Lease Renewal')];
    expect(SearchService.search(all, 'lease'), hasLength(1));
    expect(SearchService.search(all, 'LEASE'), hasLength(1));
  });

  test('matches counterparty', () {
    final all = [build(id: '1', title: 'X', counterparty: 'Acme Corp')];
    expect(SearchService.search(all, 'acme'), hasLength(1));
  });

  test('matches notes', () {
    final all = [
      build(id: '1', title: 'X', notes: 'renegotiate square footage'),
    ];
    expect(SearchService.search(all, 'footage'), hasLength(1));
  });

  test('matches category label', () {
    final all = [
      build(id: '1', title: 'X', category: ObligationCategory.insurance),
    ];
    expect(SearchService.search(all, 'insurance'), hasLength(1));
  });

  test('excludes drafts', () {
    final all = [
      build(id: '1', title: 'Draft obligation', status: ObligationStatus.draft),
    ];
    expect(SearchService.search(all, 'draft'), isEmpty);
  });

  test('includes resolved and dismissed obligations', () {
    final all = [
      build(
        id: '1',
        title: 'Resolved thing',
        status: ObligationStatus.resolved,
      ),
      build(
        id: '2',
        title: 'Dismissed thing',
        status: ObligationStatus.dismissed,
      ),
    ];
    expect(SearchService.search(all, 'thing'), hasLength(2));
  });

  test('results are sorted by title', () {
    final all = [
      build(id: '1', title: 'Zebra contract'),
      build(id: '2', title: 'Apple contract'),
    ];
    final results = SearchService.search(all, 'contract');
    expect(results.map((o) => o.id), ['2', '1']);
  });

  test('no match returns an empty list', () {
    final all = [build(id: '1', title: 'Office lease')];
    expect(SearchService.search(all, 'nonexistent'), isEmpty);
  });
}
