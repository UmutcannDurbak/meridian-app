import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of AppShell's four tabs is showing. A provider rather than
/// AppShell-local state so other screens — e.g. Horizon's "view Timeline"
/// link for obligations outside its near-term window — can switch tabs
/// without reaching into AppShell's widget tree.
final selectedTabProvider = StateProvider<int>((ref) => 0);
