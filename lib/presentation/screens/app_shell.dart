import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    HorizonScreen(),
    TimelineScreen(),
    ExposureScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _screens),
      ),
      floatingActionButton: _CaptureButton(
        key: const Key('captureButton'),
        onTap: () => showCaptureSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: Space.sm,
        color: tone.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavButton(
              icon: CupertinoIcons.list_bullet,
              label: 'Horizon',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavButton(
              icon: CupertinoIcons.calendar,
              label: 'Timeline',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            const SizedBox(width: Space.xxl),
            _NavButton(
              icon: CupertinoIcons.chart_bar_square,
              label: 'Exposure',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavButton(
              icon: CupertinoIcons.gear_alt,
              label: 'Settings',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
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
  const _CaptureButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Pressable(
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
    return Pressable(
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
    );
  }
}
