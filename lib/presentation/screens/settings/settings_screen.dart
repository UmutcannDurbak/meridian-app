import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/app_lock_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';

/// Deliberately small. There's nowhere else in the app yet for account,
/// export, or delegation settings to belong to — those need auth first.
/// The one thing that genuinely lives here today is the app lock toggle.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _lockEnabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await ref.read(appLockPreferenceProvider).isEnabled();
    if (mounted) setState(() => _lockEnabled = enabled);
  }

  Future<void> _setLockEnabled(bool value) async {
    setState(() => _lockEnabled = value);
    await ref.read(appLockPreferenceProvider).setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.lg,
        Space.md,
        Space.huge,
      ),
      children: [
        Text('Settings', style: Type.display(tone.ink)),
        const SizedBox(height: Space.xl),
        Text('SECURITY', style: Type.eyebrow(tone.inkMuted)),
        const SizedBox(height: Space.sm),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: tone.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: tone.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.paper,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(
                  CupertinoIcons.lock_shield,
                  size: 18,
                  color: tone.inkMuted,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Require Face ID / biometric unlock',
                      style: Type.heading(tone.ink),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      'Recommended — this app holds contracts and financial '
                      'details.',
                      style: Type.label(tone.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Switch.adaptive(
                value: _lockEnabled ?? true,
                onChanged: _lockEnabled == null ? null : _setLockEnabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Text('ABOUT', style: Type.eyebrow(tone.inkMuted)),
        const SizedBox(height: Space.sm),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: tone.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: tone.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.paper,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text('M', style: Type.title(tone.ink)),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meridian', style: Type.heading(tone.ink)),
                    const SizedBox(height: Space.xxs),
                    Text(
                      // Keep in sync with pubspec.yaml's version field by
                      // hand — not worth a package_info_plus dependency for
                      // one line of text.
                      'Version 0.1.0 — early scaffold, not yet released.',
                      style: Type.label(tone.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
