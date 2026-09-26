import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth session with JWT tokens in encrypted storage.
/// Email / role stay in SharedPreferences for lightweight display.
class SessionStore {
  SessionStore._();

  static const _emailKey = 'auth_email';
  static const _roleKey = 'auth_role';
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_expires_at';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// In-memory mirror so Dio can read the token without async prefs.
  static AuthSession? current;

  static Future<AuthSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (email == null || email.trim().isEmpty) {
      current = null;
      return null;
    }

    final expiresRaw = await _secure.read(key: _expiresAtKey) ??
        prefs.getString(_expiresAtKey);
    final expiresAt =
        expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

    // Prefer secure storage; migrate any legacy prefs tokens once.
    var accessToken = await _secure.read(key: _accessTokenKey);
    var refreshToken = await _secure.read(key: _refreshTokenKey);
    final legacyAccess = prefs.getString(_accessTokenKey);
    final legacyRefresh = prefs.getString(_refreshTokenKey);
    if ((accessToken == null || accessToken.isEmpty) &&
        legacyAccess != null &&
        legacyAccess.isNotEmpty) {
      accessToken = legacyAccess;
      await _secure.write(key: _accessTokenKey, value: legacyAccess);
      await prefs.remove(_accessTokenKey);
    }
    if ((refreshToken == null || refreshToken.isEmpty) &&
        legacyRefresh != null &&
        legacyRefresh.isNotEmpty) {
      refreshToken = legacyRefresh;
      await _secure.write(key: _refreshTokenKey, value: legacyRefresh);
      await prefs.remove(_refreshTokenKey);
    }
    if (expiresRaw != null && prefs.containsKey(_expiresAtKey)) {
      await _secure.write(key: _expiresAtKey, value: expiresRaw);
      await prefs.remove(_expiresAtKey);
    }

    final session = AuthSession(
      email: email,
      role: prefs.getString(_roleKey) ?? 'Liaison Officer',
      accessToken: accessToken,
      refreshToken: refreshToken,
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
      await _secure.write(key: _accessTokenKey, value: session.accessToken!);
    } else {
      await _secure.delete(key: _accessTokenKey);
    }
    if (session.refreshToken != null) {
      await _secure.write(key: _refreshTokenKey, value: session.refreshToken!);
    } else {
      await _secure.delete(key: _refreshTokenKey);
    }
    if (session.expiresAt != null) {
      await _secure.write(
        key: _expiresAtKey,
        value: session.expiresAt!.toIso8601String(),
      );
    } else {
      await _secure.delete(key: _expiresAtKey);
    }

    // Clear any leftover plaintext tokens from older builds.
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);

    current = session;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
    await _secure.delete(key: _accessTokenKey);
    await _secure.delete(key: _refreshTokenKey);
    await _secure.delete(key: _expiresAtKey);
    current = null;
  }
}
