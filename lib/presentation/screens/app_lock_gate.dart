import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../application/app_lock_providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';

enum _LockState { checking, locked, unlocked, unavailable }

/// Wraps the whole app. FR-603: biometric lock, on by default, given the
/// sensitivity of what this app holds.
///
/// Fails open, deliberately, in two cases: the platform has no local_auth
/// implementation at all (web — this app's preview build, not a real
/// security boundary anyway), or the device has no biometric/passcode
/// capability to check against. Locking someone out with no possible way
/// back in is worse than the app being unprotected on a device that was
/// never going to protect it either way.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  _LockState _state = _LockState.checking;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Read fresh rather than trusting whatever was true at initState — the
    // whole point is that a toggle made in Settings since then must be
    // honoured on this very pause/resume, not just after a restart.
    final lockEnabled = ref.read(appLockEnabledProvider);
    if (state == AppLifecycleState.paused && _state == _LockState.unlocked) {
      if (lockEnabled) setState(() => _state = _LockState.locked);
    } else if (state == AppLifecycleState.resumed &&
        _state == _LockState.locked) {
      if (lockEnabled) {
        _unlock();
      } else {
        setState(() => _state = _LockState.unlocked);
      }
    }
  }

  Future<void> _evaluate() async {
    try {
      final enabled =
          await ref.read(appLockEnabledProvider.notifier).ensureLoaded();
      if (!enabled) {
        if (mounted) setState(() => _state = _LockState.unlocked);
        return;
      }

      final canCheck = await _canCheckDevice();
      if (!mounted) return;
      setState(
        () => _state = canCheck ? _LockState.locked : _LockState.unavailable,
      );
      if (canCheck) _unlock();
    } catch (_) {
      // Whatever went wrong, don't strand the user on the checking splash
      // forever — fail open, same principle as everywhere else in this file.
      if (mounted) setState(() => _state = _LockState.unavailable);
    }
  }

  Future<bool> _canCheckDevice() async {
    final auth = ref.read(localAuthProvider);
    try {
      return await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (_) {
      // No platform implementation for local_auth on this target.
      return false;
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    final auth = ref.read(localAuthProvider);
    try {
      final ok = await auth.authenticate(
        localizedReason: 'Unlock Meridian',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok && mounted) setState(() => _state = _LockState.unlocked);
    } on Exception {
      // Leave locked — the lock screen's button lets them try again.
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _LockState.checking => const _CheckingSplash(),
      _LockState.unlocked || _LockState.unavailable => widget.child,
      _LockState.locked => _LockScreen(
          authenticating: _authenticating,
          onUnlock: _unlock,
        ),
    };
  }
}

class _CheckingSplash extends StatelessWidget {
  const _CheckingSplash();

  @override
  Widget build(BuildContext context) {
    return Container(color: Tone.paper);
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.authenticating, required this.onUnlock});

  final bool authenticating;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: tone.paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: tone.hairline),
                  ),
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    size: 30,
                    color: tone.ink,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Text(s.lockScreenTitle, style: Type.title(tone.ink)),
                const SizedBox(height: Space.sm),
                Text(
                  s.lockScreenBody,
                  style: Type.body(tone.inkMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: authenticating ? null : onUnlock,
                  child: Text(authenticating ? s.lockScreenChecking : s.lockScreenUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
