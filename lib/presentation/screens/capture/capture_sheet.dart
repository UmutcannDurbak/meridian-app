import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import 'csv_import_screen.dart';
import 'obligation_form_screen.dart';
import 'scan_capture_screen.dart';

/// Entry point for FR-101/102/103/105. Email forwarding needs backend
/// infrastructure this pass doesn't build — see docs/ROADMAP.md.
Future<void> showCaptureSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _CaptureSheet(),
  );
}

class _CaptureSheet extends StatelessWidget {
  const _CaptureSheet();

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add an obligation', style: Type.title(tone.ink)),
            const SizedBox(height: Space.md),
            _Option(
              icon: Icons.edit_outlined,
              title: 'Enter manually',
              subtitle: 'Title and date — everything else is optional',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ObligationFormScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: Space.sm),
            _Option(
              icon: Icons.document_scanner_outlined,
              title: 'Scan a document',
              subtitle: 'Read on this device. Nothing is uploaded.',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ScanCaptureScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: Space.sm),
            _Option(
              icon: Icons.table_chart_outlined,
              title: 'Import spreadsheet',
              subtitle: 'Bring in a CSV of contracts or renewals at once',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CsvImportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            Icon(icon, color: tone.ink),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Type.heading(tone.ink)),
                  Text(subtitle, style: Type.label(tone.inkMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
