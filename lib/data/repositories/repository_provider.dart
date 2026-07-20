// Compile-time platform switch. dart.library.io exists on every platform
// except web, so this resolves to the drift-backed provider everywhere
// except web, and to the in-memory one there. Nothing outside this file
// needs to know which — see obligation_repository_base.dart.
export 'repository_provider_web.dart'
    if (dart.library.io) 'repository_provider_io.dart';
