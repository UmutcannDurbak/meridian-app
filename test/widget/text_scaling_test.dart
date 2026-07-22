import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/core/theme/theme.dart';
import 'package:meridian/data/local/database.dart';
import 'package:meridian/data/repositories/obligation_repository.dart';
import 'package:meridian/data/repositories/repository_provider_io.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/presentation/screens/app_shell.dart';

import 'test_utils.dart';

/// Accessibility check: does the layout survive a larger system text size
/// without silently clipping content? 1.5x is within Android's standard
/// accessibility font-scale range and a common iOS Dynamic Type size —
/// someone using either shouldn't see truncated deadlines or an overflow
/// error in place of a screen.
void main() {
  Widget wrap(AppDatabase db, {double textScale = 1.5}) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AppShell(),
          ),
        ),
      );

  testWidgets(
      'Horizon renders a seeded card at 1.5x text scale without overflow',
      (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final repo = ObligationRepository(db);
    await repo.upsert(
      Obligation(
        id: 'seed-1',
        title: 'Office lease renewal with a genuinely long title',
        category: ObligationCategory.contract,
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        counterparty: 'Acme Property Group International Holdings',
        value: const Money(1250000, 'EUR'),
        autoRenews: true,
        noticeDaysAssumed: true,
      ),
    );

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Office lease renewal with a genuinely long title'),
      findsOneWidget,
    );
    await disposeAndFlushTimers(tester);
  });

  testWidgets('Timeline (calendar + stats header) survives 1.5x text scale',
      (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final repo = ObligationRepository(db);
    await repo.upsert(
      Obligation(
        id: 'seed-2',
        title: 'Client retainer',
        category: ObligationCategory.payment,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
        value: const Money(600000, 'USD'),
        direction: MoneyDirection.income,
      ),
    );

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await disposeAndFlushTimers(tester);
  });

  testWidgets('Settings survives 1.5x text scale', (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await disposeAndFlushTimers(tester);
  });
}
