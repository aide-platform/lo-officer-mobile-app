import 'package:liaison_officer/features/liaison_officer/data/models/transport.dart';

import 'engagement.dart';
import 'event_nomination.dart';
import 'family_member.dart';
import 'hotel.dart';

class VIP {
  final String name;
  final String salutation;
  final String designation;
  final String gender;
  final String protocolEquivalence;
  final String organisation;
  final String ministry;
  final String contact;
  final String email;
  final String? imagePath;

  final Hotel hotel;
  final Transport transport;
  final List<Engagement> engagements;
  final List<FamilyMember> familyMembers;
  final List<EventNomination> eventNominations;

  final List<String> remarks;
  final List<String> specialRequests;

  final String? foodPreferences;

  final bool isForeign;
  final String? nationality;
  final String? passportNumber;
  final DateTime? passportValidity;
  final String? language;
  final String? timeZone;
  final String? visaStatus;
  final String? securityClearanceStatus;

  VIP({
    required this.name,
    this.salutation = '',
    required this.designation,
    this.gender = '',
    this.protocolEquivalence = '',
    this.organisation = '',
    this.ministry = '',
    required this.contact,
    this.email = '',
    required this.hotel,
    required this.transport,
    required List<Engagement> engagements,
    List<FamilyMember>? familyMembers,
    List<EventNomination>? eventNominations,
    this.imagePath,
    List<String>? remarks,
    List<String>? specialRequests,
    this.foodPreferences,
    this.isForeign = false,
    this.nationality,
    this.passportNumber,
    this.passportValidity,
    this.language,
    this.timeZone,
    this.visaStatus,
    this.securityClearanceStatus,
  })  : engagements = List<Engagement>.from(engagements),
        familyMembers = List<FamilyMember>.from(familyMembers ?? const []),
        eventNominations =
            List<EventNomination>.from(eventNominations ?? const []),
        remarks = List<String>.from(remarks ?? const []),
        specialRequests = List<String>.from(specialRequests ?? const []);

  String get displayName =>
      salutation.trim().isEmpty ? name : '${salutation.trim()} $name';

  int get totalTasks => engagements.length + 2;

  int get completedTasks {
    int count = 0;
    if (hotel.roomNumber.trim().isNotEmpty) count++;
    if (transport.status.toLowerCase() == 'completed') count++;
    count += engagements
        .where((e) => e.rsvpStatus.toLowerCase() == 'confirmed')
        .length;
    return count;
  }

  double get progressPercent =>
      totalTasks > 0 ? completedTasks / totalTasks : 0;

  VIP copyWith({
    String? name,
    String? salutation,
    String? designation,
    String? gender,
    String? protocolEquivalence,
    String? organisation,
    String? ministry,
    String? contact,
    String? email,
    String? imagePath,
    Hotel? hotel,
    Transport? transport,
    List<Engagement>? engagements,
    List<FamilyMember>? familyMembers,
    List<EventNomination>? eventNominations,
    List<String>? remarks,
    List<String>? specialRequests,
    String? foodPreferences,
    bool? isForeign,
    String? nationality,
    String? passportNumber,
    DateTime? passportValidity,
    String? language,
    String? timeZone,
    String? visaStatus,
    String? securityClearanceStatus,
  }) {
    return VIP(
      name: name ?? this.name,
      salutation: salutation ?? this.salutation,
      designation: designation ?? this.designation,
      gender: gender ?? this.gender,
      protocolEquivalence: protocolEquivalence ?? this.protocolEquivalence,
      organisation: organisation ?? this.organisation,
      ministry: ministry ?? this.ministry,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
      hotel: hotel ?? this.hotel,
      transport: transport ?? this.transport,
      engagements: engagements ?? this.engagements,
      familyMembers: familyMembers ?? this.familyMembers,
      eventNominations: eventNominations ?? this.eventNominations,
      remarks: remarks ?? this.remarks,
      specialRequests: specialRequests ?? this.specialRequests,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      isForeign: isForeign ?? this.isForeign,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      passportValidity: passportValidity ?? this.passportValidity,
      language: language ?? this.language,
      timeZone: timeZone ?? this.timeZone,
      visaStatus: visaStatus ?? this.visaStatus,
      securityClearanceStatus:
          securityClearanceStatus ?? this.securityClearanceStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'salutation': salutation,
      'designation': designation,
      'gender': gender,
      'protocolEquivalence': protocolEquivalence,
      'organisation': organisation,
      'ministry': ministry,
      'contact': contact,
      'email': email,
      'imagePath': imagePath,
      'hotel': hotel.toMap(),
      'transport': transport.toMap(),
      'engagements': engagements.map((e) => e.toMap()).toList(),
      'familyMembers': familyMembers.map((e) => e.toMap()).toList(),
      'eventNominations': eventNominations.map((e) => e.toMap()).toList(),
      'remarks': remarks,
      'specialRequests': specialRequests,
      'foodPreferences': foodPreferences,
      'isForeign': isForeign,
      'nationality': nationality,
      'passportNumber': passportNumber,
      'passportValidity': passportValidity?.toIso8601String(),
      'language': language,
      'timeZone': timeZone,
      'visaStatus': visaStatus,
      'securityClearanceStatus': securityClearanceStatus,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  factory VIP.fromMap(Map<String, dynamic> map) {
    return VIP(
      name: map['name']?.toString() ?? '',
      salutation: map['salutation']?.toString() ?? '',
      designation: map['designation']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      protocolEquivalence: map['protocolEquivalence']?.toString() ?? '',
      organisation: map['organisation']?.toString() ?? '',
      ministry: map['ministry']?.toString() ?? '',
      contact: map['contact']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      imagePath: map['imagePath']?.toString(),
      hotel: map['hotel'] != null
          ? Hotel.fromMap(Map<String, dynamic>.from(map['hotel']))
          : Hotel.empty(),
      transport: map['transport'] != null
          ? Transport.fromMap(Map<String, dynamic>.from(map['transport']))
          : Transport.empty(),
      engagements: (map['engagements'] as List? ?? [])
          .map((e) => Engagement.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      familyMembers: (map['familyMembers'] as List? ?? [])
          .map((e) => FamilyMember.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      eventNominations: (map['eventNominations'] as List? ?? [])
          .map((e) => EventNomination.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      remarks: List<String>.from(map['remarks'] ?? []),
      specialRequests: List<String>.from(map['specialRequests'] ?? []),
      foodPreferences: map['foodPreferences']?.toString(),
      isForeign: _parseBool(map['isForeign']),
      nationality: map['nationality']?.toString(),
      passportNumber: map['passportNumber']?.toString(),
      passportValidity: map['passportValidity'] != null
          ? DateTime.tryParse(map['passportValidity'].toString())
          : null,
      language: map['language']?.toString(),
      timeZone: map['timeZone']?.toString(),
      visaStatus: map['visaStatus']?.toString(),
      securityClearanceStatus: map['securityClearanceStatus']?.toString(),
    );
  }
}
