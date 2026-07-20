import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Widget tests otherwise try to fetch Inter/Newsreader over the network on
/// first use, which is slow and flaky in CI. Force the bundled fallback.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
