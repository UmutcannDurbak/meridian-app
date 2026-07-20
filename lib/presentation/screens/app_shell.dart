import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import 'capture/capture_sheet.dart';
import 'exposure/exposure_screen.dart';
import 'horizon/horizon_screen.dart';
import 'timeline/timeline_screen.dart';

/// Hosts the three peer destinations from the screen inventory — Horizon,
/// Timeline, Exposure — plus capture as a centred, prominent action rather
/// than a fourth tab, per the SRS: "Capture is centered and prominent; it
/// is the highest-value action."
///
/// Settings isn't here yet. There's nothing to put in it until auth and
/// account deletion exist — an empty Settings tab would be worse than none.
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
  ];

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _screens),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCaptureSheet(context),
        backgroundColor: tone.ink,
        foregroundColor: tone.paper,
        child: const Icon(Icons.add),
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
              icon: Icons.view_agenda_outlined,
              label: 'Horizon',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavButton(
              icon: Icons.timeline_outlined,
              label: 'Timeline',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            const SizedBox(width: Space.xxl),
            _NavButton(
              icon: Icons.insights_outlined,
              label: 'Exposure',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
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
