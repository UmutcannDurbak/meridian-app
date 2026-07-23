import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';

/// Long-press on an [ObligationRow] to reach this — the full action set
/// (edit, snooze, resolve, delete) that the row's two swipe directions
/// don't have room for. Tap alone opens the row for editing; this is for
/// everything else.
Future<void> showObligationActionSheet(
  BuildContext context, {
  required VoidCallback onEdit,
  required VoidCallback onSnooze,
  required VoidCallback onResolve,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ActionSheet(
      onEdit: onEdit,
      onSnooze: onSnooze,
      onResolve: onResolve,
      onDelete: onDelete,
    ),
  );
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.onEdit,
    required this.onSnooze,
    required this.onResolve,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onSnooze;
  final VoidCallback onResolve;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final s = AppStrings.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Action(
              icon: CupertinoIcons.pencil,
              title: s.actionEdit,
              onTap: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),
            Divider(color: tone.hairline, height: Space.lg),
            _Action(
              icon: CupertinoIcons.clock,
              title: s.actionSnooze7,
              onTap: () {
                Navigator.of(context).pop();
                onSnooze();
              },
            ),
            Divider(color: tone.hairline, height: Space.lg),
            _Action(
              icon: CupertinoIcons.checkmark_alt,
              title: s.actionResolve,
              onTap: () {
                Navigator.of(context).pop();
                onResolve();
              },
            ),
            Divider(color: tone.hairline, height: Space.lg),
            _Action(
              icon: CupertinoIcons.trash,
              title: s.actionDelete,
              destructive: true,
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await _confirmDelete(context);
                if (confirmed) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final tone = context.tone;
    final s = AppStrings.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteConfirmTitle),
        content: Text(
          s.deleteConfirmBody,
          style: Type.body(tone.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.actionDelete, style: Type.heading(Pressure.closing)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tone = context.tone;
    final color = destructive ? Pressure.closing : tone.ink;
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: Space.md),
            Text(title, style: Type.heading(color)),
          ],
        ),
      ),
    );
  }
}
