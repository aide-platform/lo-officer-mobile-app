import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted key/value store for cached personal data (profile with
/// Aadhaar, delegate contacts and passports, tasks). Android keeps it in
/// EncryptedSharedPreferences, iOS in the Keychain (VAPT: plain
/// SharedPreferences was readable from backups and rooted phones).
///
/// Values written by older app versions in SharedPreferences are moved here
/// on first read, so an update keeps the offline snapshot.
class SecureCache {
  SecureCache._();

  static const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _prefix = 'cache.';

  /// Set in SharedPreferences whenever this cache holds data. iOS keeps
  /// Keychain items after the app is deleted, but SharedPreferences goes, so
  /// a missing marker means a fresh install: stale values from an earlier
  /// install (maybe another officer) are dropped instead of shown.
  static const _markerKey = 'secure_cache_present';

  static Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy != null) {
      await storage.write(key: '$_prefix$key', value: legacy);
      await prefs.setBool(_markerKey, true);
      await prefs.remove(key);
      return legacy;
    }
    if (prefs.getBool(_markerKey) != true) {
      await storage.delete(key: '$_prefix$key');
      return null;
    }
    return storage.read(key: '$_prefix$key');
  }

  static Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await storage.write(key: '$_prefix$key', value: value);
    await prefs.setBool(_markerKey, true);
    await prefs.remove(key);
  }

  static Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await storage.delete(key: '$_prefix$key');
    await prefs.remove(key);
  }
}
