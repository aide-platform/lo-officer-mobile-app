import 'dart:convert';

import '../../../../core/storage/sqlite/app_sqlite_db.dart';

class LoPreviousExperience {
  final String eventName;
  final String year;
  final String role;
  final String delegateDetails;

  const LoPreviousExperience({
    this.eventName = '',
    this.year = '',
    this.role = '',
    this.delegateDetails = '',
  });

  LoPreviousExperience copyWith({
    String? eventName,
    String? year,
    String? role,
    String? delegateDetails,
  }) {
    return LoPreviousExperience(
      eventName: eventName ?? this.eventName,
      year: year ?? this.year,
      role: role ?? this.role,
      delegateDetails: delegateDetails ?? this.delegateDetails,
    );
  }

  Map<String, dynamic> toMap() => {
        'eventName': eventName,
        'year': year,
        'role': role,
        'delegateDetails': delegateDetails,
      };

  factory LoPreviousExperience.fromMap(Map<String, dynamic> map) {
    return LoPreviousExperience(
      eventName: map['eventName']?.toString() ?? '',
      year: map['year']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      delegateDetails: map['delegateDetails']?.toString() ?? '',
    );
  }
}

class LoProfile {
  final String email;
  final String status;
  final String salutation;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String rank;
  final String designation;
  final String passportPhoto;
  final String organisationName;
  final String organisationType;
  final String organisationIdNumber;
  final String organisationIdBadgeFront;
  final String organisationIdBadgeBack;
  final String aadhaarNumber;
  final String aadhaarFront;
  final String aadhaarBack;
  final String officialEmail;
  final String personalEmail;
  final String officialContactNumber;
  final String personalContactNumber;
  final String whatsappNumber;
  final String signature;
  final bool hasPreviousExperience;
  final List<LoPreviousExperience> previousExperiences;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final List<String> languagesKnown;

  const LoProfile({
    required this.email,
    this.status = 'Draft',
    this.salutation = '',
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.dateOfBirth,
    this.rank = '',
    this.designation = '',
    this.passportPhoto = '',
    this.organisationName = 'Parent Organisation',
    this.organisationType = 'Government',
    this.organisationIdNumber = '',
    this.organisationIdBadgeFront = '',
    this.organisationIdBadgeBack = '',
    this.aadhaarNumber = '',
    this.aadhaarFront = '',
    this.aadhaarBack = '',
    this.officialEmail = '',
    this.personalEmail = '',
    this.officialContactNumber = '',
    this.personalContactNumber = '',
    this.whatsappNumber = '',
    this.signature = '',
    this.hasPreviousExperience = false,
    this.previousExperiences = const [],
    this.availableFrom,
    this.availableTo,
    this.languagesKnown = const [],
  });

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    var age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isSubmitted => status.toLowerCase() == 'submitted';

  bool get isComplete {
    final required = [
      salutation,
      firstName,
      lastName,
      gender,
      rank,
      designation,
      organisationName,
      organisationType,
      organisationIdNumber,
      aadhaarNumber,
      officialEmail,
      personalEmail,
      officialContactNumber,
      personalContactNumber,
      whatsappNumber,
      signature,
    ];
    return required.every((element) => element.trim().isNotEmpty) &&
        dateOfBirth != null &&
        availableFrom != null &&
        availableTo != null &&
        languagesKnown.isNotEmpty;
  }

  LoProfile copyWith({
    String? email,
    String? status,
    String? salutation,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? rank,
    String? designation,
    String? passportPhoto,
    String? organisationName,
    String? organisationType,
    String? organisationIdNumber,
    String? organisationIdBadgeFront,
    String? organisationIdBadgeBack,
    String? aadhaarNumber,
    String? aadhaarFront,
    String? aadhaarBack,
    String? officialEmail,
    String? personalEmail,
    String? officialContactNumber,
    String? personalContactNumber,
    String? whatsappNumber,
    String? signature,
    bool? hasPreviousExperience,
    List<LoPreviousExperience>? previousExperiences,
    DateTime? availableFrom,
    DateTime? availableTo,
    List<String>? languagesKnown,
  }) {
    return LoProfile(
      email: email ?? this.email,
      status: status ?? this.status,
      salutation: salutation ?? this.salutation,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      rank: rank ?? this.rank,
      designation: designation ?? this.designation,
      passportPhoto: passportPhoto ?? this.passportPhoto,
      organisationName: organisationName ?? this.organisationName,
      organisationType: organisationType ?? this.organisationType,
      organisationIdNumber: organisationIdNumber ?? this.organisationIdNumber,
      organisationIdBadgeFront:
          organisationIdBadgeFront ?? this.organisationIdBadgeFront,
      organisationIdBadgeBack: organisationIdBadgeBack ?? this.organisationIdBadgeBack,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarFront: aadhaarFront ?? this.aadhaarFront,
      aadhaarBack: aadhaarBack ?? this.aadhaarBack,
      officialEmail: officialEmail ?? this.officialEmail,
      personalEmail: personalEmail ?? this.personalEmail,
      officialContactNumber: officialContactNumber ?? this.officialContactNumber,
      personalContactNumber: personalContactNumber ?? this.personalContactNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      signature: signature ?? this.signature,
      hasPreviousExperience: hasPreviousExperience ?? this.hasPreviousExperience,
      previousExperiences: previousExperiences ?? this.previousExperiences,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      languagesKnown: languagesKnown ?? this.languagesKnown,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'status': status,
        'salutation': salutation,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'rank': rank,
        'designation': designation,
        'passportPhoto': passportPhoto,
        'organisationName': organisationName,
        'organisationType': organisationType,
        'organisationIdNumber': organisationIdNumber,
        'organisationIdBadgeFront': organisationIdBadgeFront,
        'organisationIdBadgeBack': organisationIdBadgeBack,
        'aadhaarNumber': aadhaarNumber,
        'aadhaarFront': aadhaarFront,
        'aadhaarBack': aadhaarBack,
        'officialEmail': officialEmail,
        'personalEmail': personalEmail,
        'officialContactNumber': officialContactNumber,
        'personalContactNumber': personalContactNumber,
        'whatsappNumber': whatsappNumber,
        'signature': signature,
        'hasPreviousExperience': hasPreviousExperience,
        'previousExperiences': previousExperiences
            .map((experience) => experience.toMap())
            .toList(),
        'availableFrom': availableFrom?.toIso8601String(),
        'availableTo': availableTo?.toIso8601String(),
        'languagesKnown': languagesKnown,
      };

  factory LoProfile.fromMap(Map<String, dynamic> map) {
    final dateOfBirthString = map['dateOfBirth']?.toString();
    final availableFromString = map['availableFrom']?.toString();
    final availableToString = map['availableTo']?.toString();
    final previousExperiences = (map['previousExperiences'] as List? ?? const [])
        .map((e) => LoPreviousExperience.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return LoProfile(
      email: map['email']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Draft',
      salutation: map['salutation']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      dateOfBirth: dateOfBirthString == null || dateOfBirthString.isEmpty
          ? null
          : DateTime.tryParse(dateOfBirthString),
      rank: map['rank']?.toString() ?? '',
      designation: map['designation']?.toString() ?? '',
      passportPhoto: map['passportPhoto']?.toString() ?? '',
      organisationName: map['organisationName']?.toString() ?? 'Parent Organisation',
      organisationType: map['organisationType']?.toString() ?? 'Government',
      organisationIdNumber: map['organisationIdNumber']?.toString() ?? '',
      organisationIdBadgeFront: map['organisationIdBadgeFront']?.toString() ?? '',
      organisationIdBadgeBack: map['organisationIdBadgeBack']?.toString() ?? '',
      aadhaarNumber: map['aadhaarNumber']?.toString() ?? '',
      aadhaarFront: map['aadhaarFront']?.toString() ?? '',
      aadhaarBack: map['aadhaarBack']?.toString() ?? '',
      officialEmail: map['officialEmail']?.toString() ?? '',
      personalEmail: map['personalEmail']?.toString() ?? '',
      officialContactNumber: map['officialContactNumber']?.toString() ?? '',
      personalContactNumber: map['personalContactNumber']?.toString() ?? '',
      whatsappNumber: map['whatsappNumber']?.toString() ?? '',
      signature: map['signature']?.toString() ?? '',
      hasPreviousExperience: map['hasPreviousExperience'] == true,
      previousExperiences: previousExperiences,
      availableFrom: availableFromString == null || availableFromString.isEmpty
          ? null
          : DateTime.tryParse(availableFromString),
      availableTo: availableToString == null || availableToString.isEmpty
          ? null
          : DateTime.tryParse(availableToString),
      languagesKnown: (map['languagesKnown'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static String _keyForEmail(String email) =>
      'lo_profile_${email.trim().toLowerCase()}';

  static Future<LoProfile?> load({required String email}) async {
    final raw = await AppSqliteDb.getSetting(_keyForEmail(email));
    if (raw == null || raw.isEmpty) return null;
    try {
      return LoProfile.fromMap(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    await AppSqliteDb.upsertSetting(
      _keyForEmail(email),
      jsonEncode(toMap()),
    );
  }

  factory LoProfile.empty({required String email}) => LoProfile(
        email: email,
        organisationName: 'Parent Organisation',
        organisationType: 'Government',
      );

  static Future<List<LoProfile>> listSubmittedProfiles() async {
    final rows = await AppSqliteDb.getSettingsByPrefix('lo_profile_');
    final profiles = <LoProfile>[];
    for (final row in rows) {
      final raw = row['value']?.toString();
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final profile = LoProfile.fromMap(Map<String, dynamic>.from(decoded));
        if (profile.isSubmitted) {
          profiles.add(profile);
        }
      } catch (_) {
        // ignore malformed records
      }
    }
    return profiles;
  }

  static Future<List<String>> listAssignedBadges() async {
    final rows = await AppSqliteDb.getJsonList('lo_badge_assignments');
    if (rows == null) return const <String>[];
    return rows.map((value) => value.toString()).toList();
  }

  static Future<void> saveAssignedBadges(List<String> emails) async {
    await AppSqliteDb.saveJsonList('lo_badge_assignments', emails);
  }
}
