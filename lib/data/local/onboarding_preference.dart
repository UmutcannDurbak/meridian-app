import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether the first-run walkthrough has been shown. Same storage choice as
/// [AppLockPreference] — not because this value is sensitive, but for the
/// same reason: one place credential-adjacent state lives in this app.
class OnboardingPreference {
  OnboardingPreference([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'onboarding_seen';
  final FlutterSecureStorage _storage;

  Future<bool> hasSeenOnboarding() async {
    final v = await _storage.read(key: _key);
    return v == 'true';
  }

  Future<void> setSeen(bool seen) async {
    await _storage.write(key: _key, value: seen.toString());
  }
}
