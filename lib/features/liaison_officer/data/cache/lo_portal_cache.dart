import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

/// Light local cache for LO portal payloads (offline-friendly last snapshot).
class LoPortalCache {
  LoPortalCache._();

  static const _profileKey = 'cap_lo_profile';
  static const _delegatesKey = 'cap_lo_delegates';
  static const _tasksKey = 'cap_lo_tasks';
  static const _alertsKey = 'cap_lo_alerts';
  static const _helplinesKey = 'cap_lo_helplines';

  static Future<void> saveProfile(LiaisonOfficerDto? profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile == null) {
      await prefs.remove(_profileKey);
      return;
    }
    await prefs.setString(
      _profileKey,
      jsonEncode({
        'id': profile.id,
        'firstName': profile.firstName,
        'lastName': profile.lastName,
        'fullName': profile.fullName,
        'orgName': profile.orgName,
        'orgTypeName': profile.orgTypeName,
        'officialEmail': profile.officialEmail,
        'personalEmail': profile.personalEmail,
        'officialContact': profile.officialContact,
        'personalContact': profile.personalContact,
        'whatsappNumber': profile.whatsappNumber,
        'profileStatus': profile.profileStatus,
        'profileComplete': profile.profileComplete,
        'designation': profile.designation,
        'rank': profile.rank,
        'dateOfBirth': profile.dateOfBirth,
        'orgIdNumber': profile.orgIdNumber,
        'aadhaarNumber': profile.aadhaarNumber,
        'trouserWaist': profile.trouserWaist,
        'trouserLength': profile.trouserLength,
        'blazerChest': profile.blazerChest,
        'blazerSleeve': profile.blazerSleeve,
      }),
    );
  }

  static Future<LiaisonOfficerDto?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return LiaisonOfficerDto.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  static Future<void> saveDelegates(List<MyLoAssignmentDto> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _delegatesKey,
      jsonEncode(items.map(_delegateToMap).toList()),
    );
  }

  static Future<List<MyLoAssignmentDto>> loadDelegates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_delegatesKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => MyLoAssignmentDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveTasks(List<LoTaskDto> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(items.map(_taskToMap).toList()),
    );
  }

  static Future<List<LoTaskDto>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list
        .whereType<Map>()
        .map((e) => LoTaskDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Inserts an alert. When [dedupeKey] is set, an existing alert with the
  /// same key is left in place and no new row is written — this stops
  /// recurring background refreshes from stacking duplicates for the same
  /// underlying event (e.g. one upcoming-task reminder per task).
  /// [at] (ISO-8601) overrides the timestamp, e.g. a server send time.
  static Future<void> pushAlert({
    required String title,
    required String body,
    String? dedupeKey,
    String? at,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _decodeAlerts(prefs.getString(_alertsKey));
    if (dedupeKey != null) {
      for (final entry in list) {
        if (entry is Map && entry['key'] == dedupeKey) return;
      }
    }
    list.insert(0, {
      'key': ?dedupeKey,
      'title': title,
      'body': body,
      'at': at ?? DateTime.now().toIso8601String(),
      'read': false,
    });
    // Newest first by timestamp, so an older server message added late
    // does not jump above fresher local alerts.
    list.sort((a, b) => _alertTime(b).compareTo(_alertTime(a)));
    await prefs.setString(_alertsKey, jsonEncode(list.take(50).toList()));
  }

  /// Stored alerts, or an empty list when the value is missing or corrupt.
  static List<dynamic> _decodeAlerts(String? raw) {
    if (raw == null) return <dynamic>[];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? List<dynamic>.from(decoded) : <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  static DateTime _alertTime(dynamic entry) {
    final raw = entry is Map ? entry['at']?.toString() : null;
    return (raw == null ? null : DateTime.tryParse(raw))?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static Future<void> saveHelplines(List<LoHelplineDto> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _helplinesKey,
      jsonEncode(items.map((h) => h.toJson()).toList()),
    );
  }

  static Future<List<LoHelplineDto>> loadHelplines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_helplinesKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return LoHelplineDto.visible(
      list
          .whereType<Map>()
          .map((e) => LoHelplineDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Drops the signed-in officer's snapshot. Theme and alert lead time stay.
  static Future<void> clearOfficerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_delegatesKey);
    await prefs.remove(_tasksKey);
    await prefs.remove(_alertsKey);
    await prefs.remove(_helplinesKey);
  }

  static Future<List<Map<String, dynamic>>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    // Dedupe-by-key once at read time so pre-existing duplicates (written
    // before the pushAlert dedupeKey landed) collapse to the newest entry.
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final e in _decodeAlerts(prefs.getString(_alertsKey)).whereType<Map>()) {
      final m = Map<String, dynamic>.from(e);
      final k = m['key'];
      if (k is String && k.isNotEmpty) {
        if (seen.contains(k)) continue;
        seen.add(k);
      }
      out.add(m);
    }
    return out;
  }

  static Map<String, dynamic> _delegateToMap(MyLoAssignmentDto d) => {
    'assignmentId': d.assignmentId,
    'fullName': d.fullName,
    'salutation': d.salutation,
    'designation': d.designation,
    'organisation': d.organisation,
    'protocolEquiv': d.protocolEquiv,
    'email': d.email,
    'mobileNumber': d.mobileNumber,
    'arrivalFlight': d.arrivalFlight,
    'arrivalTerminal': d.arrivalTerminal,
    'arrivalDate': d.arrivalDate,
    'arrivalTime': d.arrivalTime,
    'departureFlight': d.departureFlight,
    'departureTerminal': d.departureTerminal,
    'departureDate': d.departureDate,
    'departureTime': d.departureTime,
    'family': d.family
        .map(
          (f) => {
            'id': f.id,
            'salutation': f.salutation,
            'fullName': f.fullName,
            'gender': f.gender,
            'relation': f.relation,
            'passportNumber': f.passportNumber,
            'passportValidity': f.passportValidity,
          },
        )
        .toList(),
  };

  static Map<String, dynamic> _taskToMap(LoTaskDto t) => {
    'id': t.id,
    'loId': t.loId,
    'loFullName': t.loFullName,
    'loAssignId': t.loAssignId,
    'delegateName': t.delegateName,
    'taskScope': t.taskScope,
    'taskSource': t.taskSource,
    'sortOrder': t.sortOrder,
    'taskTitle': t.taskTitle,
    'taskDescription': t.taskDescription,
    'scheduledDate': t.scheduledDate,
    'scheduledTime': t.scheduledTime,
    'locationVenue': t.locationVenue,
    'remarks': t.remarks,
    'statusCode': t.statusCode,
    'statusName': t.statusName,
  };
}
