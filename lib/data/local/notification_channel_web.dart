import '../../domain/entities/obligation.dart';

/// No-op on web — this build is a quick preview with in-memory data (see
/// repository_provider_web.dart) and isn't a real target platform for the
/// product, so there's nothing to schedule against.
class NotificationChannel {
  Future<bool> requestPermissions() async => false;

  Future<void> reconcile(List<Obligation> obligations, DateTime now) async {}
}
