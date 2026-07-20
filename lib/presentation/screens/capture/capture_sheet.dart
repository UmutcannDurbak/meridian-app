import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../widgets/pressable.dart';
import 'csv_import_screen.dart';
import 'obligation_form_screen.dart';
import 'scan_capture_screen.dart';

/// Entry point for FR-101/102/103/105. Email forwarding needs backend
/// infrastructure this pass doesn't build — see docs/ROADMAP.md.
Future<void> showCaptureSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _CaptureSheet(),
  );
}

class _CaptureSheet extends StatelessWidget {
  const _CaptureSheet();

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    // isScrollControlled lets the sheet size to its content up to full
    // screen height; wrapping in a scroll view is the fallback for the rest
    // — a small device or a landscape keyboard should scroll, never overflow.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add an obligation', style: Type.title(tone.ink)),
            const SizedBox(height: Space.md),
            _Option(
              icon: CupertinoIcons.pencil,
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
            Divider(color: tone.hairline, height: Space.lg),
            _Option(
              icon: CupertinoIcons.doc_text_viewfinder,
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
            Divider(color: tone.hairline, height: Space.lg),
            _Option(
              icon: CupertinoIcons.table,
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
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.surface,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(icon, color: tone.ink, size: 20),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Type.heading(tone.ink)),
                  const SizedBox(height: Space.xxs),
                  Text(subtitle, style: Type.label(tone.inkMuted)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16, color: tone.inkFaint),
          ],
        ),
      ),
    );
  }
}
