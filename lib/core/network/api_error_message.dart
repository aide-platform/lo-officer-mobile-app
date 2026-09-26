import 'package:dio/dio.dart';
import 'package:liaison_officer/core/network/api_exception.dart';

/// User-facing message from CAP / Dio failures (no DioException class dump).
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  String? raw;
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
  m = m.replaceFirst(RegExp(r'^DioException\s*\[[^\]]*\]:\s*', caseSensitive: false), '');
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
