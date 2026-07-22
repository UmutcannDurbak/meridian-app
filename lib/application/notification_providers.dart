import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/notification_channel.dart';

/// One channel instance for the app's lifetime — re-creating it per rebuild
/// would mean re-initializing the platform plugin repeatedly.
final notificationChannelProvider = Provider<NotificationChannel>((ref) {
  return NotificationChannel();
});
