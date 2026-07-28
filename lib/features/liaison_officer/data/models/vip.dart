import 'package:liaison_officer/features/liaison_officer/data/models/transport.dart';

import 'engagement.dart';
import 'hotel.dart';

class VIP {
  final String name;
  final String designation;
  final String contact;
  final String? imagePath;

  final Hotel hotel;
  final Transport transport;
  final List<Engagement> engagements;

  final List<String> remarks;
  final List<String> specialRequests;

  final String? foodPreferences;

  // 🔥 Foreign VIP Fields
  final bool isForeign;
  final String? nationality;
  final String? passportNumber;
  final String? language;
  final String? timeZone;
  final String? visaStatus;
  final String? securityClearanceStatus;

  VIP({
    required this.name,
    required this.designation,
    required this.contact,
    required this.hotel,
    required this.transport,
    required List<Engagement> engagements,
    this.imagePath,
    List<String>? remarks,
    List<String>? specialRequests,
    this.foodPreferences,
    this.isForeign = false,
    this.nationality,
    this.passportNumber,
    this.language,
    this.timeZone,
    this.visaStatus,
    this.securityClearanceStatus,
  })  : engagements = List<Engagement>.from(engagements),
        remarks = List<String>.from(remarks ?? const []),
        specialRequests = List<String>.from(specialRequests ?? const []);

  // -------------------------------
  // 📊 Dashboard Business Logic
  // -------------------------------

  int get totalTasks => engagements.length + 2;

  int get completedTasks {
    int count = 0;

    // Hotel task is complete only when a room is assigned.
    if (hotel.roomNumber.trim().isNotEmpty) count++;

    if (transport.status.toLowerCase() == 'completed') {
      count++;
    }

    count += engagements
        .where((e) => e.rsvpStatus.toLowerCase() == 'confirmed')
        .length;

    return count;
  }

  double get progressPercent =>
      totalTasks > 0 ? completedTasks / totalTasks : 0;

  // -------------------------------
  // 🔁 CopyWith (important for Riverpod)
  // -------------------------------

  VIP copyWith({
    String? name,
    String? designation,
    String? contact,
    String? imagePath,
    Hotel? hotel,
    Transport? transport,
    List<Engagement>? engagements,
    List<String>? remarks,
    List<String>? specialRequests,
    String? foodPreferences,
    bool? isForeign,
    String? nationality,
    String? passportNumber,
    String? language,
    String? timeZone,
    String? visaStatus,
    String? securityClearanceStatus,
  }) {
    return VIP(
      name: name ?? this.name,
      designation: designation ?? this.designation,
      contact: contact ?? this.contact,
      imagePath: imagePath ?? this.imagePath,
      hotel: hotel ?? this.hotel,
      transport: transport ?? this.transport,
      engagements: engagements ?? this.engagements,
      remarks: remarks ?? this.remarks,
      specialRequests: specialRequests ?? this.specialRequests,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      isForeign: isForeign ?? this.isForeign,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      language: language ?? this.language,
      timeZone: timeZone ?? this.timeZone,
      visaStatus: visaStatus ?? this.visaStatus,
      securityClearanceStatus:
          securityClearanceStatus ?? this.securityClearanceStatus,
    );
  }

  // -------------------------------
  // 🗂️ To Map (Hive / API)
  // -------------------------------

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'contact': contact,
      'imagePath': imagePath,
      'hotel': hotel.toMap(),
      'transport': transport.toMap(),
      'engagements': engagements.map((e) => e.toMap()).toList(),
      'remarks': remarks,
      'specialRequests': specialRequests,
      'foodPreferences': foodPreferences,
      'isForeign': isForeign,
      'nationality': nationality,
      'passportNumber': passportNumber,
      'language': language,
      'timeZone': timeZone,
      'visaStatus': visaStatus,
      'securityClearanceStatus': securityClearanceStatus,
    };
  }

  // -------------------------------
  // 🛡️ Safe Bool Parser
  // -------------------------------

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  // -------------------------------
  // 📦 From Map (Safe)
  // -------------------------------

  factory VIP.fromMap(Map<String, dynamic> map) {
    return VIP(
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      contact: map['contact'] ?? '',
      imagePath: map['imagePath'],

      hotel: map['hotel'] != null
          ? Hotel.fromMap(Map<String, dynamic>.from(map['hotel']))
          : Hotel.empty(),

      transport: map['transport'] != null
          ? Transport.fromMap(Map<String, dynamic>.from(map['transport']))
          : Transport.empty(),

      engagements: (map['engagements'] as List? ?? [])
          .map((e) => Engagement.fromMap(Map<String, dynamic>.from(e)))
          .toList(),

      remarks: List<String>.from(map['remarks'] ?? []),
      specialRequests: List<String>.from(map['specialRequests'] ?? []),
      foodPreferences: map['foodPreferences'],

      // 🔥 SAFELY PARSED
      isForeign: _parseBool(map['isForeign']),

      nationality: map['nationality'],
      passportNumber: map['passportNumber'],
      language: map['language'],
      timeZone: map['timeZone'],
      visaStatus: map['visaStatus'],
      securityClearanceStatus: map['securityClearanceStatus'],
    );
  }
}
