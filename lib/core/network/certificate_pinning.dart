/// CA pinning for the API client (VAPT MED-05). Mobile/desktop builds use
/// [pinned_roots.dart]; web builds keep the browser's own TLS checks.
library;

export 'certificate_pinning_stub.dart'
    if (dart.library.io) 'certificate_pinning_io.dart';
