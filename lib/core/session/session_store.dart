import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore._();

  static const _emailKey = 'auth_email';
  static const _roleKey = 'auth_role';
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_expires_at';

  /// In-memory mirror so Dio can read the token without async prefs.
  static AuthSession? current;

  static Future<AuthSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (email == null || email.trim().isEmpty) {
      current = null;
      return null;
    }

    final expiresRaw = prefs.getString(_expiresAtKey);
    final expiresAt =
        expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

    final session = AuthSession(
      email: email,
      role: prefs.getString(_roleKey) ?? 'Liaison Officer',
      accessToken: prefs.getString(_accessTokenKey),
      refreshToken: prefs.getString(_refreshTokenKey),
      expiresAt: expiresAt,
    );

    if (!session.isValid) {
      await clear();
      return null;
    }

    current = session;
    return session;
  }

  static Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, session.email);
    await prefs.setString(_roleKey, session.role);
    if (session.accessToken != null) {
      await prefs.setString(_accessTokenKey, session.accessToken!);
    } else {
      await prefs.remove(_accessTokenKey);
    }
    if (session.refreshToken != null) {
      await prefs.setString(_refreshTokenKey, session.refreshToken!);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
    if (session.expiresAt != null) {
      await prefs.setString(
        _expiresAtKey,
        session.expiresAt!.toIso8601String(),
      );
    } else {
      await prefs.remove(_expiresAtKey);
    }
    current = session;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
    current = null;
  }
}
