// CAP DTO models for Liaison Officer app.

class LiaisonOfficerDto {
  final String? id;
  final String? personId;
  final String? orgId;
  final String? orgName;
  final String? orgTypeName;
  final String? salutationName;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? rank;
  final String? designation;
  final String? officialEmail;
  final String? personalEmail;
  final String? officialContact;
  final String? personalContact;
  final String? whatsappNumber;
  final String? profileStatus;
  final bool? profileComplete;
  final bool? isActive;
  final String? genderName;
  final String? genderId;
  final String? dateOfBirth;
  final String? orgIdNumber;
  final String? aadhaarNumber;
  final bool? hasPrevLoExp;
  final int? yearsOfExperience;
  final String? currentPassId;
  final String? currentPassNumber;
  final String? currentBadgeCatName;
  final String? currentBadgeCatId;
  final List<String> languages;
  final String? availabilityStatus;
  final String? photoFileId;
  final String? photoFileName;
  final String? signatureFileId;
  final String? signatureFileName;
  final String? aadhaarFrontId;
  final String? aadhaarFrontFileName;
  final String? aadhaarBackId;
  final String? aadhaarBackFileName;
  final String? orgBadgeFrontId;
  final String? orgBadgeFrontFileName;
  final String? orgBadgeBackId;
  final String? orgBadgeBackFileName;

  const LiaisonOfficerDto({
    this.id,
    this.personId,
    this.orgId,
    this.orgName,
    this.orgTypeName,
    this.salutationName,
    this.firstName,
    this.lastName,
    this.fullName,
    this.rank,
    this.designation,
    this.officialEmail,
    this.personalEmail,
    this.officialContact,
    this.personalContact,
    this.whatsappNumber,
    this.profileStatus,
    this.profileComplete,
    this.isActive,
    this.genderName,
    this.genderId,
    this.dateOfBirth,
    this.orgIdNumber,
    this.aadhaarNumber,
    this.hasPrevLoExp,
    this.yearsOfExperience,
    this.currentPassId,
    this.currentPassNumber,
    this.currentBadgeCatName,
    this.currentBadgeCatId,
    this.languages = const [],
    this.availabilityStatus,
    this.photoFileId,
    this.photoFileName,
    this.signatureFileId,
    this.signatureFileName,
    this.aadhaarFrontId,
    this.aadhaarFrontFileName,
    this.aadhaarBackId,
    this.aadhaarBackFileName,
    this.orgBadgeFrontId,
    this.orgBadgeFrontFileName,
    this.orgBadgeBackId,
    this.orgBadgeBackFileName,
  });

  factory LiaisonOfficerDto.fromJson(Map<String, dynamic> json) {
    final langs = json['languages'] ??
        json['languagesKnown'] ??
        json['languageNames'];
    return LiaisonOfficerDto(
      id: json['id']?.toString(),
      personId: json['personId']?.toString(),
      orgId: json['orgId']?.toString(),
      orgName: json['orgName']?.toString(),
      orgTypeName: json['orgTypeName']?.toString(),
      salutationName: json['salutationName']?.toString() ??
          json['salutation']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      fullName: json['fullName']?.toString(),
      rank: json['rank']?.toString(),
      designation: json['designation']?.toString(),
      officialEmail: json['officialEmail']?.toString() ??
          json['primaryEmail']?.toString(),
      personalEmail: json['personalEmail']?.toString(),
      officialContact: json['officialContact']?.toString() ??
          json['primaryMobile']?.toString(),
      personalContact: json['personalContact']?.toString(),
      whatsappNumber: json['whatsappNumber']?.toString(),
      profileStatus: json['profileStatus']?.toString(),
      profileComplete: json['profileComplete'] as bool?,
      isActive: json['isActive'] as bool?,
      genderName: json['genderName']?.toString(),
      genderId: json['genderId']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      orgIdNumber: json['orgIdNumber']?.toString(),
      aadhaarNumber: json['aadhaarNumber']?.toString(),
      hasPrevLoExp: json['hasPrevLoExp'] as bool?,
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      currentPassId: json['currentPassId']?.toString(),
      currentPassNumber: json['currentPassNumber']?.toString(),
      currentBadgeCatName: json['currentBadgeCatName']?.toString(),
      currentBadgeCatId: json['currentBadgeCatId']?.toString(),
      languages: langs is List
          ? langs.map((e) => e.toString()).toList()
          : const [],
      availabilityStatus: json['availabilityStatus']?.toString() ??
          json['availability']?.toString(),
      photoFileId: json['photoFileId']?.toString(),
      photoFileName: json['photoFileName']?.toString(),
      signatureFileId: json['signatureFileId']?.toString(),
      signatureFileName: json['signatureFileName']?.toString(),
      aadhaarFrontId: json['aadhaarFrontId']?.toString(),
      aadhaarFrontFileName: json['aadhaarFrontFileName']?.toString(),
      aadhaarBackId: json['aadhaarBackId']?.toString(),
      aadhaarBackFileName: json['aadhaarBackFileName']?.toString(),
      orgBadgeFrontId: json['orgBadgeFrontId']?.toString(),
      orgBadgeFrontFileName: json['orgBadgeFrontFileName']?.toString(),
      orgBadgeBackId: json['orgBadgeBackId']?.toString(),
      orgBadgeBackFileName: json['orgBadgeBackFileName']?.toString(),
    );
  }

  /// Document slots present for preview (label â†’ fileId).
  Map<String, String> get documentFileIds {
    final map = <String, String>{};
    void put(String label, String? id) {
      if (id != null && id.isNotEmpty) map[label] = id;
    }

    put('Photo', photoFileId);
    put('Signature', signatureFileId);
    put('Aadhaar front', aadhaarFrontId);
    put('Aadhaar back', aadhaarBackId);
    put('Org badge front', orgBadgeFrontId);
    put('Org badge back', orgBadgeBackId);
    return map;
  }

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    return [salutationName, firstName, lastName]
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .join(' ');
  }
}

class MyLoFamilyDto {
  final String? id;
  final String? salutation;
  final String? fullName;
  final String? gender;
  final String? relation;
  final String? passportNumber;
  final String? passportValidity;

  const MyLoFamilyDto({
    this.id,
    this.salutation,
    this.fullName,
    this.gender,
    this.relation,
    this.passportNumber,
    this.passportValidity,
  });

  factory MyLoFamilyDto.fromJson(Map<String, dynamic> json) => MyLoFamilyDto(
        id: json['id']?.toString(),
        salutation: json['salutation']?.toString(),
        fullName: json['fullName']?.toString(),
        gender: json['gender']?.toString(),
        relation: json['relation']?.toString(),
        passportNumber: json['passportNumber']?.toString(),
        passportValidity: json['passportValidity']?.toString(),
      );
}

class MyLoAssignmentDto {
  final String? assignmentId;
  final String? delegateType;
  final String? personId;
  final String? attendeeId;
  final String? salutation;
  final String? fullName;
  final String? designation;
  final String? organisation;
  final String? ministry;
  final String? countryName;
  final String? protocolEquiv;
  final String? vipCategory;
  final String? gender;
  final String? email;
  final String? mobileNumber;
  final String? arrivalFlight;
  final String? arrivalTerminal;
  final String? arrivalDate;
  final String? arrivalTime;
  final String? departureFlight;
  final String? departureTerminal;
  final String? departureDate;
  final String? departureTime;
  final String? passportNumber;
  final String? passportExpiry;
  final String? passportNationality;
  final List<String> decorations;
  final List<MyLoFamilyDto> family;

  const MyLoAssignmentDto({
    this.assignmentId,
    this.delegateType,
    this.personId,
    this.attendeeId,
    this.salutation,
    this.fullName,
    this.designation,
    this.organisation,
    this.ministry,
    this.countryName,
    this.protocolEquiv,
    this.vipCategory,
    this.gender,
    this.email,
    this.mobileNumber,
    this.arrivalFlight,
    this.arrivalTerminal,
    this.arrivalDate,
    this.arrivalTime,
    this.departureFlight,
    this.departureTerminal,
    this.departureDate,
    this.departureTime,
    this.passportNumber,
    this.passportExpiry,
    this.passportNationality,
    this.decorations = const [],
    this.family = const [],
  });

  factory MyLoAssignmentDto.fromJson(Map<String, dynamic> json) {
    final familyRaw = json['family'];
    final decorationsRaw = json['decorations'] ?? json['awards'];
    final profile = json['profile'];
    final profileMap =
        profile is Map ? Map<String, dynamic>.from(profile) : null;
    return MyLoAssignmentDto(
      assignmentId: json['assignmentId']?.toString(),
      delegateType: json['delegateType']?.toString(),
      personId: json['personId']?.toString(),
      attendeeId: json['attendeeId']?.toString(),
      salutation: json['salutation']?.toString(),
      fullName: json['fullName']?.toString(),
      designation: json['designation']?.toString(),
      organisation: json['organisation']?.toString(),
      ministry: json['ministry']?.toString() ??
          profileMap?['ministry']?.toString(),
      countryName: json['countryName']?.toString(),
      protocolEquiv: json['protocolEquiv']?.toString(),
      vipCategory: json['vipCategory']?.toString(),
      gender: json['gender']?.toString() ??
          json['genderName']?.toString() ??
          profileMap?['gender']?.toString(),
      email: json['email']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      arrivalFlight: json['arrivalFlight']?.toString(),
      arrivalTerminal: json['arrivalTerminal']?.toString(),
      arrivalDate: json['arrivalDate']?.toString(),
      arrivalTime: json['arrivalTime']?.toString(),
      departureFlight: json['departureFlight']?.toString(),
      departureTerminal: json['departureTerminal']?.toString(),
      departureDate: json['departureDate']?.toString(),
      departureTime: json['departureTime']?.toString(),
      passportNumber: json['passportNumber']?.toString() ??
          profileMap?['passportNumber']?.toString(),
      passportExpiry: json['passportExpiry']?.toString() ??
          profileMap?['passportExpiry']?.toString(),
      passportNationality: json['passportNationality']?.toString() ??
          profileMap?['nationality']?.toString(),
      decorations: decorationsRaw is List
          ? decorationsRaw.map((e) => e.toString()).toList()
          : const [],
      family: familyRaw is List
          ? familyRaw
              .whereType<Map>()
              .map((e) => MyLoFamilyDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class LoTaskDto {
  final String? id;
  final String? loId;
  final String? loFullName;
  final String? loAssignId;
  final String? delegatePersonId;
  final String? delegateName;
  final String? taskSource;
  final String? activityId;
  final String? taskTitle;
  final String? taskDescription;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? locationVenue;
  final String? remarks;
  final String? statusCode;
  final String? statusName;

  const LoTaskDto({
    this.id,
    this.loId,
    this.loFullName,
    this.loAssignId,
    this.delegatePersonId,
    this.delegateName,
    this.taskSource,
    this.activityId,
    this.taskTitle,
    this.taskDescription,
    this.scheduledDate,
    this.scheduledTime,
    this.locationVenue,
    this.remarks,
    this.statusCode,
    this.statusName,
  });

  factory LoTaskDto.fromJson(Map<String, dynamic> json) => LoTaskDto(
        id: json['id']?.toString(),
        loId: json['loId']?.toString(),
        loFullName: json['loFullName']?.toString(),
        loAssignId: json['loAssignId']?.toString(),
        delegatePersonId: json['delegatePersonId']?.toString(),
        delegateName: json['delegateName']?.toString(),
        taskSource: json['taskSource']?.toString(),
        activityId: json['activityId']?.toString(),
        taskTitle: json['taskTitle']?.toString(),
        taskDescription: json['taskDescription']?.toString(),
        scheduledDate: json['scheduledDate']?.toString(),
        scheduledTime: json['scheduledTime']?.toString(),
        locationVenue: json['locationVenue']?.toString(),
        remarks: json['remarks']?.toString(),
        statusCode: json['statusCode']?.toString(),
        statusName: json['statusName']?.toString(),
      );
}

class CaptchaChallenge {
  final String captchaId;
  final String imageBase64;

  const CaptchaChallenge({
    required this.captchaId,
    required this.imageBase64,
  });

  factory CaptchaChallenge.fromJson(Map<String, dynamic> json) =>
      CaptchaChallenge(
        captchaId: json['captchaId']?.toString() ?? '',
        imageBase64: json['imageBase64']?.toString() ?? '',
      );
}

class JwtSession {
  final String accessToken;
  final String? tokenType;
  final int? expiresInMs;
  final String? userId;
  final String email;
  final String role;

  const JwtSession({
    required this.accessToken,
    required this.email,
    required this.role,
    this.tokenType,
    this.expiresInMs,
    this.userId,
  });

  factory JwtSession.fromJson(Map<String, dynamic> json) => JwtSession(
        accessToken: json['accessToken']?.toString() ?? '',
        tokenType: json['tokenType']?.toString(),
        expiresInMs: (json['expiresInMs'] as num?)?.toInt(),
        userId: json['userId']?.toString(),
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
      );

  DateTime get expiresAt {
    final ms = expiresInMs ?? const Duration(hours: 8).inMilliseconds;
    return DateTime.now().add(Duration(milliseconds: ms));
  }
}

class LoExperienceDto {
  final String? id;
  final String? eventName;
  final int? year;
  final String? roleResponsibilities;
  final String? delegateDetails;

  const LoExperienceDto({
    this.id,
    this.eventName,
    this.year,
    this.roleResponsibilities,
    this.delegateDetails,
  });

  factory LoExperienceDto.fromJson(Map<String, dynamic> json) =>
      LoExperienceDto(
        id: json['id']?.toString(),
        eventName: json['eventName']?.toString() ?? json['event']?.toString(),
        year: (json['year'] as num?)?.toInt(),
        roleResponsibilities: json['roleResponsibilities']?.toString() ??
            json['role']?.toString(),
        delegateDetails: json['delegateDetails']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (eventName != null) 'eventName': eventName,
        if (year != null) 'year': year,
        if (roleResponsibilities != null)
          'roleResponsibilities': roleResponsibilities,
        if (delegateDetails != null) 'delegateDetails': delegateDetails,
      };
}

class ConnectingFlightDraft {
  final String flightNumber;
  final String terminal;
  final String date;
  final String time;

  const ConnectingFlightDraft({
    this.flightNumber = '',
    this.terminal = '',
    this.date = '',
    this.time = '',
  });

  Map<String, dynamic> toJson() => {
        'flightNumber': flightNumber,
        'terminal': terminal,
        'date': date,
        'time': time,
      };

  factory ConnectingFlightDraft.fromJson(Map<String, dynamic> json) =>
      ConnectingFlightDraft(
        flightNumber: json['flightNumber']?.toString() ?? '',
        terminal: json['terminal']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
      );
}
