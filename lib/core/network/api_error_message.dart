import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/network/api_exception.dart';

/// User-facing message from CAP / Dio failures (no DioException class dump).
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  String? raw;
  if (error is DioException &&
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.unknown)) {
    // No HTTP response: offline, timeout, or (on web) the browser hid the
    // response because it had no CORS headers. Dio's text for these is a
    // paragraph about XMLHttpRequest, so replace it. Debug builds name the
    // call so the failing endpoint is easy to find.
    final where = kDebugMode
        ? ' (${error.requestOptions.method} ${error.requestOptions.path})'
        : '';
    final timedOut =
        error.type != DioExceptionType.connectionError &&
        error.type != DioExceptionType.unknown;
    return timedOut
        ? 'The server took too long to respond. Please try again.$where'
        : 'Could not reach the server. Check your connection and try again.$where';
  }
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException && inner.message.trim().isNotEmpty) {
      raw = inner.message;
    } else if ((error.message ?? '').trim().isNotEmpty) {
      raw = error.message;
    }
  } else if (error is ApiException) {
    raw = error.message;
  } else {
    final s = error.toString().trim();
    if (s.isNotEmpty) raw = s;
  }

  if (raw == null || raw.isEmpty) return fallback;
  return _humanize(raw);
}

String _humanize(String message) {
  var m = message.trim();
  // Strip common wrapper prefixes.
  m = m.replaceFirst(
    RegExp(r'^DioException\s*\[[^\]]*\]:\s*', caseSensitive: false),
    '',
  );
  m = m.replaceFirst(RegExp(r'^ApiException:\s*', caseSensitive: false), '');
  m = m.replaceFirst(RegExp(r'\s*\(\d{3}\)\s*$'), '');
  // "genderId: Gender is required" → "Gender is required"
  final fieldPrefixed = RegExp(r'^[A-Za-z0-9_]+\s*:\s*(.+)$').firstMatch(m);
  if (fieldPrefixed != null) {
    final rest = fieldPrefixed.group(1)!.trim();
    if (rest.isNotEmpty) m = rest;
  }
  m = m.trim();
  return m.isEmpty ? 'Something went wrong. Please try again.' : m;
}
