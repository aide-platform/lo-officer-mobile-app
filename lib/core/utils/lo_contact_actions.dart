import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared tel / sms / WhatsApp / Maps launch helpers for LO field screens.
///
/// Every helper reports a failure itself through [messengerKey], so a
/// button never silently does nothing.
class LoContactActions {
  LoContactActions._();

  /// Set as `MaterialApp.scaffoldMessengerKey`.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Dialable number: digits with an optional leading `+`. Short service
  /// numbers (100, 112, 1077) are allowed. Null when nothing to dial.
  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) return null;
    return trimmed.startsWith('+') ? '+$digits' : digits;
  }

  /// WhatsApp needs the country code: a 10-digit Indian mobile gets 91.
  static String? _whatsAppNumber(String? raw) {
    final n = normalizePhone(raw);
    if (n == null) return null;
    var digits = n.replaceAll('+', '');
    if (!n.startsWith('+') && digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!n.startsWith('+') && digits.length == 10) digits = '91$digits';
    return digits.length < 10 ? null : digits;
  }

  static Future<bool> call(String? phone) async {
    final number = normalizePhone(phone);
    if (number == null) return _fail('No valid phone number to call.');
    return _launch(
      Uri(scheme: 'tel', path: number),
      failure: 'Unable to start the call.',
    );
  }

  static Future<bool> sms(String? phone, {String? body}) async {
    final number = normalizePhone(phone);
    if (number == null) return _fail('No valid phone number for SMS.');
    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: body == null || body.isEmpty ? null : {'body': body},
    );
    return _launch(uri, failure: 'Unable to open messages.');
  }

  static Future<bool> whatsApp(String? phone, {String? text}) async {
    final digits = _whatsAppNumber(phone);
    if (digits == null) return _fail('No valid WhatsApp number.');
    final uri = Uri.parse(
      'https://wa.me/$digits${text != null && text.isNotEmpty ? '?text=${Uri.encodeComponent(text)}' : ''}',
    );
    return _launch(
      uri,
      mode: LaunchMode.externalApplication,
      failure: 'Unable to open WhatsApp.',
    );
  }

  /// Opens Google Maps search for [query] (venue, pickup, terminal, etc.).
  static Future<bool> openMaps(String? query) async {
    final q = (query ?? '').trim();
    if (q.isEmpty) return _fail('No location to show on the map.');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
    return _launch(
      uri,
      mode: LaunchMode.externalApplication,
      failure: 'Unable to open maps.',
    );
  }

  static Future<bool> email(String? address) async {
    final a = (address ?? '').trim();
    if (a.isEmpty || !a.contains('@')) {
      return _fail('No valid email address.');
    }
    return _launch(
      Uri(scheme: 'mailto', path: a),
      failure: 'No email app found.',
    );
  }

  /// Launches directly: `canLaunchUrl` returns false on Android 11+ / iOS
  /// when the scheme is not declared, even though the launch would work.
  static Future<bool> _launch(
    Uri uri, {
    required String failure,
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      if (await launchUrl(uri, mode: mode)) return true;
    } catch (_) {}
    return _fail(failure);
  }

  static bool _fail(String message) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
    return false;
  }
}
