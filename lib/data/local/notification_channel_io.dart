import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/obligation.dart';
import '../../domain/services/notification_planner.dart';

/// Local, on-device notification scheduling. There is no backend yet — see
/// docs/ROADMAP.md's "server-side scheduling" line — so this is the entire
/// implementation: [reconcile] is called on every obligation-list change and
/// on app start, and is idempotent by construction (see NotificationPlanner)
/// rather than diffing against what was scheduled before.
///
/// Known limitation: on Android, alarms scheduled through this plugin do not
/// automatically survive a device reboot in this version — the app has to be
/// opened again to re-arm them. Acceptable for a first pass; a proper fix
/// needs a boot-completed receiver, which is native platform work.
class NotificationChannel {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fails open to UTC — notifications still fire, just not necessarily
      // at the intended local wall-clock time. Better than not scheduling.
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  /// Fails open like [AppLockGate] — a denied permission means alerts are
  /// silently dropped by the platform, not a crash or a blocked app.
  Future<bool> requestPermissions() async {
    await _ensureInitialized();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final androidGranted = await android?.requestNotificationsPermission();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return (androidGranted ?? true) && (iosGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  Future<void> reconcile(List<Obligation> obligations, DateTime now) async {
    await _ensureInitialized();
    try {
      await _plugin.cancelAll();
      for (final n in NotificationPlanner.plan(obligations, now)) {
        await _plugin.zonedSchedule(
          n.id,
          n.title,
          n.body,
          tz.TZDateTime.from(n.at, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'obligation_alerts',
              'Obligation alerts',
              channelDescription: 'Deadline and action-window reminders.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          // Inexact rather than exact: these are reminders, not alarms, and
          // exact scheduling on Android 12+ requires the user to separately
          // grant a sensitive "Alarms & reminders" permission — too much
          // friction for a notice that fires within the target hour either
          // way.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {
      // No platform implementation, or the plugin isn't available (e.g. a
      // test host) — fail open rather than crash the reconcile loop.
    }
  }
}
