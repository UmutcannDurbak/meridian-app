import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/app_lock_providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../onboarding/onboarding_flow.dart';

/// Deliberately small. There's nowhere else in the app yet for account,
/// export, or delegation settings to belong to — those need auth first.
/// The one thing that genuinely lives here today is the app lock toggle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    final lockEnabled = ref.watch(appLockEnabledProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.lg,
        Space.md,
        Space.huge,
      ),
      children: [
        Text(s.settingsTitle, style: Type.display(tone.ink)),
        const SizedBox(height: Space.xl),
        Text(s.sectionSecurity, style: Type.eyebrow(tone.inkMuted)),
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
                    Text(s.lockTitle, style: Type.heading(tone.ink)),
                    const SizedBox(height: Space.xxs),
                    Text(s.lockSubtitle, style: Type.label(tone.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Switch.adaptive(
                value: lockEnabled,
                onChanged: ref.read(appLockEnabledProvider.notifier).setEnabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Text(s.sectionHelp, style: Type.eyebrow(tone.inkMuted)),
        const SizedBox(height: Space.sm),
        const OnboardingReplayTile(),
        const SizedBox(height: Space.xl),
        Text(s.sectionAbout, style: Type.eyebrow(tone.inkMuted)),
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
