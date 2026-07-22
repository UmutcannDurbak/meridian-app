// Compile-time platform switch, same pattern as repository_provider.dart —
// dart.library.io exists everywhere except web.
export 'notification_channel_web.dart'
    if (dart.library.io) 'notification_channel_io.dart';
