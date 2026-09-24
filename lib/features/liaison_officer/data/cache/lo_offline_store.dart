import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_portal_cache.dart';

/// Hive-backed offline snapshot + queued task status updates for LO field use.
class LoOfflineStore {
  LoOfflineStore._();

  static const _boxName = 'lo_offline';
  static const _queueKey = 'task_status_queue';
  static const _delegatesKey = 'delegates_json';
  static const _tasksKey = 'tasks_json';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Box<dynamic> get box {
    final b = _box;
    if (b == null) {
      throw StateError('LoOfflineStore.init() was not called');
    }
    return b;
  }

  static Future<void> cacheDelegates(List<MyLoAssignmentDto> items) async {
    await LoPortalCache.saveDelegates(items);
    try {
      await box.put(
        _delegatesKey,
        jsonEncode(items.map((d) => {
              'assignmentId': d.assignmentId,
              'fullName': d.fullName,
              'designation': d.designation,
              'delegateType': d.delegateType,
              'countryName': d.countryName,
              'arrivalDate': d.arrivalDate,
              'departureDate': d.departureDate,
            }).toList()),
      );
    } catch (_) {}
  }

  static Future<void> cacheTasks(List<LoTaskDto> items) async {
    await LoPortalCache.saveTasks(items);
    try {
      await box.put(
        _tasksKey,
        jsonEncode(items
            .map((t) => {
                  'id': t.id,
                  'taskTitle': t.taskTitle,
                  'delegateName': t.delegateName,
                  'statusCode': t.statusCode,
                  'statusName': t.statusName,
                })
            .toList()),
      );
    } catch (_) {}
  }

  static Future<void> enqueueTaskStatus({
    required String taskId,
    required String statusCode,
    String? remarks,
  }) async {
    try {
      final raw = box.get(_queueKey);
      final list = raw is String
          ? List<dynamic>.from(jsonDecode(raw) as List)
          : <dynamic>[];
      list.add({
        'taskId': taskId,
        'statusCode': statusCode,
        'remarks': remarks,
        'queuedAt': DateTime.now().toIso8601String(),
      });
      await box.put(_queueKey, jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> peekQueue() async {
    try {
      final raw = box.get(_queueKey);
      if (raw is! String) return const [];
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clearQueue() async {
    try {
      await box.delete(_queueKey);
    } catch (_) {}
  }

  static Future<void> replaceQueue(List<Map<String, dynamic>> items) async {
    try {
      if (items.isEmpty) {
        await clearQueue();
        return;
      }
      await box.put(_queueKey, jsonEncode(items));
    } catch (_) {}
  }
}
