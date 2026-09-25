import 'package:url_launcher/url_launcher.dart';

/// Shared tel / sms / WhatsApp / Maps launch helpers for LO field screens.
class LoContactActions {
  LoContactActions._();

  /// Digits-only phone; returns null if too short to dial.
  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    return digits;
  }

  static Future<bool> call(String? phone) async {
    final digits = normalizePhone(phone);
    if (digits == null) return false;
    return _launch(Uri(scheme: 'tel', path: digits));
  }

  static Future<bool> sms(String? phone, {String? body}) async {
    final digits = normalizePhone(phone);
    if (digits == null) return false;
    final uri = Uri(
      scheme: 'sms',
      path: digits,
      queryParameters: body == null || body.isEmpty ? null : {'body': body},
    );
    return _launch(uri);
  }

  static Future<bool> whatsApp(String? phone, {String? text}) async {
    final digits = normalizePhone(phone);
    if (digits == null) return false;
    final uri = Uri.parse(
      'https://wa.me/$digits${text != null && text.isNotEmpty ? '?text=${Uri.encodeComponent(text)}' : ''}',
    );
    return _launch(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens Google Maps search for [query] (venue, pickup, terminal, etc.).
  static Future<bool> openMaps(String? query) async {
    final q = (query ?? '').trim();
    if (q.isEmpty) return false;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
    return _launch(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> email(String? address) async {
    final a = (address ?? '').trim();
    if (a.isEmpty || !a.contains('@')) return false;
    return _launch(Uri(scheme: 'mailto', path: a));
  }

  static Future<bool> _launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: mode);
  }
}
