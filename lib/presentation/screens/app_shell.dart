import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/navigation_providers.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../widgets/pressable.dart';
import 'capture/capture_sheet.dart';
import 'exposure/exposure_screen.dart';
import 'horizon/horizon_screen.dart';
import 'settings/settings_screen.dart';
import 'timeline/timeline_screen.dart';

/// Hosts the four destinations from the screen inventory — Horizon,
/// Timeline, Exposure, Settings — plus capture as a centred, prominent
/// action rather than a fifth tab, per the SRS: "Capture is centered and
/// prominent; it is the highest-value action."
///
/// The selected tab lives in [selectedTabProvider], not local state — other
/// screens (Horizon's "view Timeline" link) need to switch tabs too.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    HorizonScreen(),
    TimelineScreen(),
    ExposureScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    final index = ref.watch(selectedTabProvider);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: _screens),
      ),
      floatingActionButton: _CaptureButton(
        key: const Key('captureButton'),
        semanticLabel: s.captureSemanticLabel,
        onTap: () => showCaptureSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: Space.sm,
        color: tone.surface,
        // Clamped, not left to scale freely like everything else in the
        // app: this bar has a fixed height, and at a large accessibility
        // text size the label under each icon overflowed it (found via
        // test/widget/text_scaling_test.dart). iOS and Android's own tab
        // bars make the same tradeoff for the same reason — fixed chrome,
        // not scrolling content.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavButton(
                icon: CupertinoIcons.list_bullet,
                label: s.navHorizon,
                selected: index == 0,
                onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
              ),
              _NavButton(
                icon: CupertinoIcons.calendar,
                label: s.navTimeline,
                selected: index == 1,
                onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
              ),
              const SizedBox(width: Space.xxl),
              _NavButton(
                icon: CupertinoIcons.chart_bar_square,
                label: s.navExposure,
                selected: index == 2,
                onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
              ),
              _NavButton(
                icon: CupertinoIcons.gear_alt,
                label: s.navSettings,
                selected: index == 3,
                onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Not a stock FloatingActionButton — that widget's press feedback is an
/// InkWell splash, which this theme disables app-wide and never replaces.
/// Rebuilding it on Pressable gives capture, the app's single most important
/// tap target, the same real press feedback as everything else.
class _CaptureButton extends StatelessWidget {
  const _CaptureButton({super.key, required this.onTap, required this.semanticLabel});
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.ink,
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: Icon(CupertinoIcons.add, color: tone.paper, size: 26),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final color = selected ? tone.ink : tone.inkFaint;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: Space.xxs),
              Text(label, style: Type.eyebrow(color)),
            ],
          ),
        ),
      ),
    );
  }
}
