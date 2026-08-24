import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Key-value settings store.
/// Uses sqflite on mobile/desktop; SharedPreferences on web (sqflite is unsupported).
class AppSqliteDb {
  AppSqliteDb._();

  static Database? _db;
  static const _prefsPrefix = 'lo_kv_';
  static bool? _usePrefs;

  static Future<bool> _shouldUsePrefs() async {
    if (_usePrefs != null) return _usePrefs!;
    if (kIsWeb) {
      _usePrefs = true;
      return true;
    }
    try {
      await getDatabasesPath();
      _usePrefs = false;
    } catch (_) {
      _usePrefs = true;
    }
    return _usePrefs!;
  }

  static Future<Database> init() async {
    if (await _shouldUsePrefs()) {
      throw UnsupportedError('SQLite is not available on this platform');
    }
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'liaison_officer.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<Database> get db async => init();

  static Future<void> upsertSetting(String key, String value) async {
    if (await _shouldUsePrefs()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsPrefix$key', value);
      return;
    }
    final database = await db;
    await database.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSetting(String key) async {
    if (await _shouldUsePrefs()) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_prefsPrefix$key');
    }
    final database = await db;
    final rows = await database.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> cachePasses(List<dynamic> passes) async {
    await upsertSetting('passes_cache', jsonEncode(passes));
  }

  static Future<List<dynamic>?> getCachedPasses() async {
    final raw = await getSetting('passes_cache');
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  static Future<List<Map<String, Object?>>> getSettingsByPrefix(
    String prefix,
  ) async {
    if (await _shouldUsePrefs()) {
      final prefs = await SharedPreferences.getInstance();
      final fullPrefix = '$_prefsPrefix$prefix';
      final out = <Map<String, Object?>>[];
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(fullPrefix)) continue;
        final value = prefs.getString(key);
        if (value == null) continue;
        out.add({
          'key': key.substring(_prefsPrefix.length),
          'value': value,
        });
      }
      return out;
    }
    final database = await db;
    final rows = await database.query(
      'settings',
      where: 'key LIKE ?',
      whereArgs: ['$prefix%'],
    );
    return rows;
  }

  static Future<void> saveJsonList(String key, List<dynamic> value) async {
    await upsertSetting(key, jsonEncode(value));
  }

  static Future<List<dynamic>?> getJsonList(String key) async {
    final raw = await getSetting(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
