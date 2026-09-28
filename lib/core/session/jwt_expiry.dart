import 'dart:convert';

/// Reads the `exp` claim (seconds since epoch) from a JWT access token.
///
/// Returns null when [token] is not a JWT or has no numeric `exp`.
DateTime? jwtExpiresAt(String token) {
  final parts = token.split('.');
  if (parts.length < 2 || parts[1].isEmpty) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final json = jsonDecode(payload);
    if (json is! Map) return null;
    final exp = json['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}
