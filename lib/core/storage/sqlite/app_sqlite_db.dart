import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppSqliteDb {
  AppSqliteDb._();

  static Database? _db;

  static Future<Database> init() async {
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
    final database = await db;
    await database.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSetting(String key) async {
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
}
