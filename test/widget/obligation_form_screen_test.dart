import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/application/obligation_providers.dart';
import 'package:meridian/core/theme/theme.dart';
import 'package:meridian/data/local/database.dart';
import 'package:meridian/data/repositories/obligation_repository.dart';
import 'package:meridian/domain/entities/obligation.dart';
import 'package:meridian/presentation/screens/capture/obligation_form_screen.dart';

import 'test_utils.dart';

void main() {
  testWidgets('review mode pre-fills fields and confirm activates the draft',
      (tester) async {
    // Review mode starts with "More details" expanded, which pushes the
    // Confirm button past the default 800x600 test surface — SliverList
    // only builds elements inside the viewport, so `find.text` would miss
    // it. Grow the surface instead of scrolling to keep the test simple.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    final repo = ObligationRepository(db);

    final draft = Obligation(
      id: 'draft-1',
      title: 'Datadog subscription',
      category: ObligationCategory.subscription,
      expiryDate: DateTime(2026, 5, 1),
      noticeDays: 30,
      counterparty: 'Datadog Inc.',
      value: const Money(480000, 'USD'),
      autoRenews: true,
      status: ObligationStatus.draft,
      createdVia: CaptureSource.scan,
    );
    await repo.upsert(draft);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ObligationFormScreen(
            draft: draft,
            extractionDisclosure: 'Read on this device. Not uploaded.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review draft'), findsOneWidget);
    expect(find.text('Read on this device. Not uploaded.'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Datadog subscription'),
      findsOneWidget,
    );
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    final saved = await repo.byId('draft-1');
    expect(saved, isNotNull);
    expect(saved!.status, ObligationStatus.dormant);
    expect(saved.title, 'Datadog subscription');
    expect(saved.value?.minorUnits, 480000);
    expect(saved.autoRenews, isTrue);
    await disposeAndFlushTimers(tester);
  });
}
