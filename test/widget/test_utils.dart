import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Riverpod's [StreamProvider] disposal cancels the underlying drift query
/// stream, which schedules a zero-duration cleanup timer
/// (`StreamQueryStore.markAsClosed`). `testWidgets` disposes the widget tree
/// automatically after the test body returns with no further pump to let
/// that timer fire, so any drift-backed widget test trips the "Timer still
/// pending" invariant without this. Call as the last line of such a test.
Future<void> disposeAndFlushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}
