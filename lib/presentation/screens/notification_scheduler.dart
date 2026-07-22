import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/notification_providers.dart';
import '../../application/obligation_providers.dart';

/// Keeps the device's scheduled notifications in sync with the obligation
/// list. There is no server yet, so "wiring notifications" means: whenever
/// the obligations change, or the app starts, recompute the full
/// notification plan and hand it to the platform — see
/// NotificationChannel.reconcile and NotificationPlanner.
class NotificationScheduler extends ConsumerStatefulWidget {
  const NotificationScheduler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationScheduler> createState() =>
      _NotificationSchedulerState();
}

class _NotificationSchedulerState
    extends ConsumerState<NotificationScheduler> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: a denial just means reconcile() schedules alerts the
    // platform silently drops, same fail-open principle as AppLockGate.
    ref.read(notificationChannelProvider).requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(obligationListProvider, (previous, next) {
      next.whenData((obligations) {
        final now = ref.read(nowProvider);
        ref.read(notificationChannelProvider).reconcile(obligations, now);
      });
    });
    return widget.child;
  }
}
