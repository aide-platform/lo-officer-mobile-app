import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/network/pinned_roots.dart';

/// Debug-only escape hatch for traffic inspection on a dev machine
/// (`--dart-define=DISABLE_PINNING=true`). Ignored in release builds.
const bool _disablePinning = bool.fromEnvironment('DISABLE_PINNING');

SecurityContext? _context;

/// TLS context that trusts only [pinnedRootCertificates], not the phone's
/// certificate store.
SecurityContext pinnedSecurityContext() {
  final cached = _context;
  if (cached != null) return cached;
  final context = SecurityContext(withTrustedRoots: false);
  for (final pem in pinnedRootCertificates) {
    context.setTrustedCertificatesBytes(utf8.encode(pem));
  }
  return _context = context;
}

/// Makes [dio] accept only server chains that end in a pinned root CA.
/// Plain `http://` (local Spring Boot during development) is unaffected.
void applyCertificatePinning(Dio dio) {
  if (kDebugMode && _disablePinning) return;
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient(context: pinnedSecurityContext());
      // Never let an untrusted chain through.
      client.badCertificateCallback = (cert, host, port) => false;
      return client;
    },
  );
}
