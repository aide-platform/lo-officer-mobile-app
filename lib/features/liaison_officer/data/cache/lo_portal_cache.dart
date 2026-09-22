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

  static Future<void> pushAlert({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_alertsKey);
    final list = existing == null
        ? <dynamic>[]
        : List<dynamic>.from(jsonDecode(existing) as List);
    list.insert(0, {
      'title': title,
      'body': body,
      'at': DateTime.now().toIso8601String(),
      'read': false,
    });
    await prefs.setString(_alertsKey, jsonEncode(list.take(50).toList()));
  }

  static Future<List<Map<String, dynamic>>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertsKey);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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
            .map((f) => {
                  'id': f.id,
                  'salutation': f.salutation,
                  'fullName': f.fullName,
                  'gender': f.gender,
                  'relation': f.relation,
                  'passportNumber': f.passportNumber,
                  'passportValidity': f.passportValidity,
                })
            .toList(),
      };

  static Map<String, dynamic> _taskToMap(LoTaskDto t) => {
        'id': t.id,
        'loId': t.loId,
        'loFullName': t.loFullName,
        'loAssignId': t.loAssignId,
        'delegateName': t.delegateName,
        'taskSource': t.taskSource,
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
