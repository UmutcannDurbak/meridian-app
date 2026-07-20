import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../data/local/app_lock_preference.dart';

final appLockPreferenceProvider = Provider<AppLockPreference>((ref) {
  return AppLockPreference();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});
