/// CAP DTO models used across LO portals.

class LiaisonOfficerDto {
  final String? id;
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
  final String? currentPassNumber;
  final String? currentBadgeCatName;

  const LiaisonOfficerDto({
    this.id,
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
    this.currentPassNumber,
    this.currentBadgeCatName,
  });

  factory LiaisonOfficerDto.fromJson(Map<String, dynamic> json) {
    return LiaisonOfficerDto(
      id: json['id']?.toString(),
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
      currentPassNumber: json['currentPassNumber']?.toString(),
      currentBadgeCatName: json['currentBadgeCatName']?.toString(),
    );
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
  final String? countryName;
  final String? protocolEquiv;
  final String? vipCategory;
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
    this.countryName,
    this.protocolEquiv,
    this.vipCategory,
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
    this.family = const [],
  });

  factory MyLoAssignmentDto.fromJson(Map<String, dynamic> json) {
    final familyRaw = json['family'];
    return MyLoAssignmentDto(
      assignmentId: json['assignmentId']?.toString(),
      delegateType: json['delegateType']?.toString(),
      personId: json['personId']?.toString(),
      attendeeId: json['attendeeId']?.toString(),
      salutation: json['salutation']?.toString(),
      fullName: json['fullName']?.toString(),
      designation: json['designation']?.toString(),
      organisation: json['organisation']?.toString(),
      countryName: json['countryName']?.toString(),
      protocolEquiv: json['protocolEquiv']?.toString(),
      vipCategory: json['vipCategory']?.toString(),
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

class LoOrgTypeDto {
  final String? id;
  final String? code;
  final String displayName;
  final String? description;
  final bool? isActive;

  const LoOrgTypeDto({
    this.id,
    this.code,
    required this.displayName,
    this.description,
    this.isActive,
  });

  factory LoOrgTypeDto.fromJson(Map<String, dynamic> json) => LoOrgTypeDto(
        id: json['id']?.toString(),
        code: json['code']?.toString(),
        displayName: json['displayName']?.toString() ?? '',
        description: json['description']?.toString(),
        isActive: json['isActive'] as bool?,
      );
}

class LoOrganisationDto {
  final String? id;
  final String orgName;
  final String? orgTypeId;
  final String? orgTypeName;
  final String headName;
  final String headDesignation;
  final String? address;
  final String primaryEmail;
  final String? altEmail;
  final String primaryContact;
  final String? altContact;
  final String? remarks;
  final bool? isActive;
  final int? loCount;
  final int? loSubmittedCount;

  const LoOrganisationDto({
    this.id,
    required this.orgName,
    this.orgTypeId,
    this.orgTypeName,
    required this.headName,
    required this.headDesignation,
    this.address,
    required this.primaryEmail,
    this.altEmail,
    required this.primaryContact,
    this.altContact,
    this.remarks,
    this.isActive,
    this.loCount,
    this.loSubmittedCount,
  });

  factory LoOrganisationDto.fromJson(Map<String, dynamic> json) =>
      LoOrganisationDto(
        id: json['id']?.toString(),
        orgName: json['orgName']?.toString() ?? '',
        orgTypeId: json['orgTypeId']?.toString(),
        orgTypeName: json['orgTypeName']?.toString(),
        headName: json['headName']?.toString() ?? '',
        headDesignation: json['headDesignation']?.toString() ?? '',
        address: json['address']?.toString(),
        primaryEmail: json['primaryEmail']?.toString() ?? '',
        altEmail: json['altEmail']?.toString(),
        primaryContact: json['primaryContact']?.toString() ?? '',
        altContact: json['altContact']?.toString(),
        remarks: json['remarks']?.toString(),
        isActive: json['isActive'] as bool?,
        loCount: (json['loCount'] as num?)?.toInt(),
        loSubmittedCount: (json['loSubmittedCount'] as num?)?.toInt(),
      );

  Map<String, dynamic> toCreateJson() => {
        'orgName': orgName,
        'orgTypeId': orgTypeId,
        'headName': headName,
        'headDesignation': headDesignation,
        if (address != null) 'address': address,
        'primaryEmail': primaryEmail,
        if (altEmail != null) 'altEmail': altEmail,
        'primaryContact': primaryContact,
        if (altContact != null) 'altContact': altContact,
        if (remarks != null) 'remarks': remarks,
      };
}

class LoActivityDto {
  final String? id;
  final String activityTitle;
  final String? activityDesc;
  final bool? isActive;

  const LoActivityDto({
    this.id,
    required this.activityTitle,
    this.activityDesc,
    this.isActive,
  });

  factory LoActivityDto.fromJson(Map<String, dynamic> json) => LoActivityDto(
        id: json['id']?.toString(),
        activityTitle: json['activityTitle']?.toString() ?? '',
        activityDesc: json['activityDesc']?.toString(),
        isActive: json['isActive'] as bool?,
      );
}

class LoAssignmentDto {
  final String? id;
  final String? loId;
  final String? loFullName;
  final String? loOrgName;
  final String? personId;
  final String? delegateName;
  final String? delegateCountry;
  final String? delegateType;

  const LoAssignmentDto({
    this.id,
    this.loId,
    this.loFullName,
    this.loOrgName,
    this.personId,
    this.delegateName,
    this.delegateCountry,
    this.delegateType,
  });

  factory LoAssignmentDto.fromJson(Map<String, dynamic> json) =>
      LoAssignmentDto(
        id: json['id']?.toString(),
        loId: json['loId']?.toString(),
        loFullName: json['loFullName']?.toString(),
        loOrgName: json['loOrgName']?.toString(),
        personId: json['personId']?.toString(),
        delegateName: json['delegateName']?.toString(),
        delegateCountry: json['delegateCountry']?.toString(),
        delegateType: json['delegateType']?.toString(),
      );
}

class EmailTemplateDto {
  final String? id;
  final String name;
  final String subject;
  final String body;
  final String? purposeTag;
  final bool? isActive;

  const EmailTemplateDto({
    this.id,
    required this.name,
    required this.subject,
    required this.body,
    this.purposeTag,
    this.isActive,
  });

  factory EmailTemplateDto.fromJson(Map<String, dynamic> json) =>
      EmailTemplateDto(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        purposeTag: json['purposeTag']?.toString(),
        isActive: json['isActive'] as bool?,
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
