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

/// End-to-end coverage of the capture loop the way a device would exercise
/// it, minus the platform channel (no simulator/device is available in this
/// environment — see docs/ROADMAP.md on the Windows/cloud-Mac split).
void main() {
  Widget wrap(AppDatabase db) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppShell(),
        ),
      );

  testWidgets('shows the empty state with nothing persisted', (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Nothing is waiting on you.'), findsOneWidget);
    await disposeAndFlushTimers(tester);
  });

  testWidgets('renders a persisted obligation grouped by urgency',
      (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final repo = ObligationRepository(db);
    await repo.upsert(
      Obligation(
        id: 'seed-1',
        title: 'Server lease',
        category: ObligationCategory.contract,
        expiryDate: DateTime.now().add(const Duration(days: 3)),
      ),
    );

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Server lease'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    await disposeAndFlushTimers(tester);
  });

  testWidgets(
      'FAB opens the capture sheet, and manual entry enforces the '
      'required date', (tester) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Enter manually'), findsOneWidget);

    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();
    expect(find.text('New obligation'), findsOneWidget);

    // Title only, no date — FR-103 requires both before it can save.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Fire inspection',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(find.text('New obligation'), findsOneWidget); // still on the form
    await disposeAndFlushTimers(tester);
  });
}
