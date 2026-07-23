import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../data/local/app_lock_preference.dart';

final appLockPreferenceProvider = Provider<AppLockPreference>((ref) {
  return AppLockPreference();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Reactive view of the lock preference. [AppLockGate] watches/reads this
/// instead of hitting [AppLockPreference] directly, so a toggle made in
/// Settings is visible immediately — including to the pause/resume check
/// that decides whether to re-lock — rather than only taking effect after
/// the app is restarted.
final appLockEnabledProvider =
    StateNotifierProvider<AppLockEnabledController, bool>((ref) {
  return AppLockEnabledController(ref.watch(appLockPreferenceProvider));
});

class AppLockEnabledController extends StateNotifier<bool> {
  AppLockEnabledController(this._preference) : super(true) {
    _ready = _load();
  }

  final AppLockPreference _preference;
  late final Future<void> _ready;

  Future<void> _load() async {
    state = await _preference.isEnabled();
  }

  /// Resolves once the persisted value has loaded, with [state] guaranteed
  /// to reflect it — lets a cold-start caller await the real value instead
  /// of racing the `true` default this controller seeds itself with.
  Future<bool> ensureLoaded() async {
    await _ready;
    return state;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await _preference.setEnabled(value);
  }
}
