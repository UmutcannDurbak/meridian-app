import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether the biometric app lock is on. Defaults to enabled — FR-603:
/// "required by default given the sensitivity of contract data." A user can
/// turn it off in Settings, but they have to do that deliberately.
///
/// Stored in the Keychain/Keystore via flutter_secure_storage rather than
/// SharedPreferences — same rule as everywhere else credential-adjacent
/// state lives in this app, even though this particular value (a boolean
/// on/off flag) isn't itself sensitive.
class AppLockPreference {
  AppLockPreference([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'app_lock_enabled';
  final FlutterSecureStorage _storage;

  Future<bool> isEnabled() async {
    final v = await _storage.read(key: _key);
    return v == null ? true : v == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _key, value: enabled.toString());
  }
}
