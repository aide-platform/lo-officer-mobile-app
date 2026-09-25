import 'dart:typed_data';

import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';

class MockLoPortalRepository implements LoPortalRepository {
  final List<MyLoAssignmentDto> _delegates = [
    const MyLoAssignmentDto(
      assignmentId: 'asn-1',
      personId: 'per-1',
      attendeeId: 'att-1',
      delegateType: 'FOREIGN_INVITEE',
      fullName: 'Air Marshal Demo VIP',
      salutation: 'Air Marshal',
      designation: 'Commander',
      organisation: 'IAF',
      ministry: 'Ministry of Defence',
      gender: 'Male',
      countryName: 'India',
      protocolEquiv: 'Secretary',
      email: 'vip@example.com',
      mobileNumber: '+911234567890',
      arrivalFlight: 'AI 802',
      arrivalTerminal: 'T2',
      arrivalDate: '2026-02-10',
      arrivalTime: '14:30',
      departureFlight: 'AI 803',
      departureTerminal: 'T2',
      departureDate: '2026-02-14',
      departureTime: '18:00',
      family: [
        MyLoFamilyDto(
          salutation: 'Mrs.',
          fullName: 'Demo Spouse',
          gender: 'Female',
          relation: 'Spouse',
          passportNumber: 'P1234567',
          passportValidity: '2030-01-01',
        ),
      ],
    ),
  ];

  final List<LoTaskDto> _tasks = [
    const LoTaskDto(
      id: 'task-1',
      loAssignId: 'asn-1',
      delegateName: 'Air Marshal Demo VIP',
      taskSource: 'CUSTOM',
      taskTitle: 'Airport reception',
      taskDescription: 'Receive VIP at T2 arrivals.',
      scheduledDate: '2026-02-10',
      scheduledTime: '14:00',
      locationVenue: 'Kempegowda Airport T2',
      statusCode: 'PENDING',
      statusName: 'Pending',
    ),
  ];

  final List<LoExperienceDto> _experiences = [];
  final List<({String id, String languageName})> _languageRows = [
    (id: 'lang-row-1', languageName: 'English'),
    (id: 'lang-row-2', languageName: 'Hindi'),
  ];
  final Map<String, List<ConnectingFlightDraft>> _arrivalConnecting = {};
  final Map<String, List<ConnectingFlightDraft>> _departureConnecting = {};

  LiaisonOfficerDto _profile = const LiaisonOfficerDto(
    id: 'lo-1',
    personId: 'person-lo-1',
    firstName: 'Demo',
    lastName: 'Liaison',
    fullName: 'Demo Liaison',
    orgName: 'BEL',
    orgTypeName: 'DPSU',
    officialEmail: 'liaison@test.com',
    profileStatus: 'DRAFT',
    profileComplete: false,
    currentPassId: 'pass-lo-1',
    currentPassNumber: 'L-2001',
  );

  @override
  Future<LiaisonOfficerDto?> getMyProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _profile;
  }

  @override
  Future<LiaisonOfficerDto> updateMyProfile(Map<String, dynamic> body) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _profile = LiaisonOfficerDto(
      id: _profile.id,
      personId: _profile.personId,
      firstName: body['firstName']?.toString() ?? _profile.firstName,
      lastName: body['lastName']?.toString() ?? _profile.lastName,
      fullName:
          '${body['firstName'] ?? _profile.firstName} ${body['lastName'] ?? _profile.lastName}',
      orgName: _profile.orgName,
      orgTypeName: _profile.orgTypeName,
      officialEmail: body['officialEmail']?.toString() ?? _profile.officialEmail,
      personalEmail: body['personalEmail']?.toString(),
      personalContact: body['personalContact']?.toString(),
      officialContact: body['officialContact']?.toString(),
      whatsappNumber: body['whatsappNumber']?.toString(),
      aadhaarNumber: body['aadhaarNumber']?.toString(),
      orgIdNumber: body['orgIdNumber']?.toString(),
      dateOfBirth: body['dateOfBirth']?.toString(),
      genderName: body['genderName']?.toString(),
      genderId: body['genderId']?.toString(),
      designation: body['designation']?.toString(),
      rank: body['rank']?.toString(),
      salutationName: body['salutation']?.toString(),
      hasPrevLoExp: body['hasPrevLoExp'] as bool?,
      profileStatus: 'SUBMITTED',
      profileComplete: true,
    );
    return _profile;
  }

  @override
  Future<List<MyLoAssignmentDto>> getMyDelegates() async => List.of(_delegates);

  @override
  Future<List<LoTaskDto>> getMyTasks() async => List.of(_tasks);

  @override
  Future<LoTaskDto> updateTaskStatus({
    required String taskId,
    required String statusCode,
    String? remarks,
  }) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    final updated = LoTaskDto(
      id: _tasks[idx].id,
      loAssignId: _tasks[idx].loAssignId,
      delegateName: _tasks[idx].delegateName,
      taskSource: _tasks[idx].taskSource,
      taskTitle: _tasks[idx].taskTitle,
      taskDescription: _tasks[idx].taskDescription,
      scheduledDate: _tasks[idx].scheduledDate,
      scheduledTime: _tasks[idx].scheduledTime,
      locationVenue: _tasks[idx].locationVenue,
      remarks: remarks ?? _tasks[idx].remarks,
      statusCode: statusCode,
      statusName: statusCode.replaceAll('_', ' '),
    );
    _tasks[idx] = updated;
    return updated;
  }

  @override
  Future<MyLoAssignmentDto> updateTravel({
    required String assignmentId,
    required Map<String, dynamic> body,
  }) async {
    final idx = _delegates.indexWhere((d) => d.assignmentId == assignmentId);
    final cur = _delegates[idx];
    final arrivalRaw = body['arrivalConnectingFlights'];
    if (arrivalRaw is List) {
      _arrivalConnecting[assignmentId] = arrivalRaw
          .whereType<Map>()
          .map((e) =>
              ConnectingFlightDraft.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final departureRaw = body['departureConnectingFlights'];
    if (departureRaw is List) {
      _departureConnecting[assignmentId] = departureRaw
          .whereType<Map>()
          .map((e) =>
              ConnectingFlightDraft.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final updated = MyLoAssignmentDto(
      assignmentId: cur.assignmentId,
      personId: cur.personId,
      attendeeId: cur.attendeeId,
      delegateType: cur.delegateType,
      fullName: cur.fullName,
      salutation: cur.salutation,
      designation: cur.designation,
      organisation: cur.organisation,
      ministry: cur.ministry,
      gender: cur.gender,
      protocolEquiv: cur.protocolEquiv,
      email: cur.email,
      mobileNumber: cur.mobileNumber,
      family: cur.family,
      arrivalFlight: body['arrivalFlight']?.toString() ?? cur.arrivalFlight,
      arrivalTerminal:
          body['arrivalTerminal']?.toString() ?? cur.arrivalTerminal,
      arrivalDate: body['arrivalDate']?.toString() ?? cur.arrivalDate,
      arrivalTime: body['arrivalTime']?.toString() ?? cur.arrivalTime,
      departureFlight:
          body['departureFlight']?.toString() ?? cur.departureFlight,
      departureTerminal:
          body['departureTerminal']?.toString() ?? cur.departureTerminal,
      departureDate: body['departureDate']?.toString() ?? cur.departureDate,
      departureTime: body['departureTime']?.toString() ?? cur.departureTime,
    );
    _delegates[idx] = updated;
    return updated;
  }

  @override
  Future<MyLoAssignmentDto> updateArrivalFlight({
    required String assignmentId,
    required Map<String, dynamic> body,
  }) async {
    final idx = _delegates.indexWhere((d) => d.assignmentId == assignmentId);
    final cur = _delegates[idx];
    final updated = MyLoAssignmentDto(
      assignmentId: cur.assignmentId,
      personId: cur.personId,
      attendeeId: cur.attendeeId,
      delegateType: cur.delegateType,
      fullName: cur.fullName,
      salutation: cur.salutation,
      designation: cur.designation,
      organisation: cur.organisation,
      ministry: cur.ministry,
      gender: cur.gender,
      protocolEquiv: cur.protocolEquiv,
      email: cur.email,
      mobileNumber: cur.mobileNumber,
      family: cur.family,
      arrivalFlight: body['arrivalFlight']?.toString() ?? cur.arrivalFlight,
      arrivalTerminal:
          body['arrivalTerminal']?.toString() ?? cur.arrivalTerminal,
      arrivalDate: body['arrivalDate']?.toString() ?? cur.arrivalDate,
      arrivalTime: body['arrivalTime']?.toString() ?? cur.arrivalTime,
      departureFlight: cur.departureFlight,
      departureTerminal: cur.departureTerminal,
      departureDate: cur.departureDate,
      departureTime: cur.departureTime,
      passportNumber: cur.passportNumber,
      passportExpiry: cur.passportExpiry,
      decorations: cur.decorations,
    );
    _delegates[idx] = updated;
    return updated;
  }

  @override
  Future<void> uploadPhoto(Uint8List bytes, String filename) async {}

  @override
  Future<void> uploadSignature(Uint8List bytes, String filename) async {}

  @override
  Future<void> uploadOrgBadgeFront(Uint8List bytes, String filename) async {}

  @override
  Future<void> uploadOrgBadgeBack(Uint8List bytes, String filename) async {}

  @override
  Future<void> uploadAadhaarFront(Uint8List bytes, String filename) async {}

  @override
  Future<void> uploadAadhaarBack(Uint8List bytes, String filename) async {}

  @override
  Future<List<LoExperienceDto>> listExperiences() async =>
      List.of(_experiences);

  @override
  Future<LoExperienceDto> addExperience(Map<String, dynamic> body) async {
    final e = LoExperienceDto(
      id: 'exp-${_experiences.length + 1}',
      eventName: body['eventName']?.toString(),
      year: (body['year'] as num?)?.toInt(),
      roleResponsibilities: body['roleResponsibilities']?.toString(),
      delegateDetails: body['delegateDetails']?.toString(),
    );
    _experiences.add(e);
    return e;
  }

  @override
  Future<void> deleteExperience(String id) async {
    _experiences.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<String>> listLanguages() async =>
      _languageRows.map((e) => e.languageName).toList();

  /// Test helper: row ids currently stored for languages.
  List<String> get languageRowIds =>
      _languageRows.map((e) => e.id).toList(growable: false);

  @override
  Future<void> setLanguages(List<String> languages) async {
    final desired = languages
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    _languageRows.removeWhere((e) => !desired.contains(e.languageName));
    final existing = _languageRows.map((e) => e.languageName).toSet();
    var next = _languageRows.length + 1;
    for (final lang in desired) {
      if (existing.contains(lang)) continue;
      _languageRows.add((id: 'lang-row-$next', languageName: lang));
      next++;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVehicles(String assignmentId) async => [
        {
          'vehicleType': 'SUV',
          'vehicleNumber': 'KA-01-AB-1234',
          'driverName': 'Ramesh',
          'driverContact': '+919876543210',
        },
      ];

  @override
  Future<List<Map<String, dynamic>>> getNominations(String assignmentId) async =>
      [
        {
          'eventName': 'RM Dinner',
          'eventDate': '2026-02-11',
          'eventTime': '19:30',
          'venue': 'VIP Lounge',
        },
        {
          'eventName': 'Inaugural Function',
          'eventDate': '2026-02-12',
          'eventTime': '10:00',
          'venue': 'Main Arena',
        },
      ];

  final List<LoIssueReport> _issues = [];

  @override
  Future<MyLoAssignmentDto> updateMovement({
    required String assignmentId,
    required LoMovementUpdate movement,
  }) async {
    return updateTravel(
      assignmentId: assignmentId,
      body: movement.toTravelBody(),
    );
  }

  @override
  Future<List<LoItineraryItem>> getItinerary(String assignmentId) async {
    final assignment = _delegates.firstWhere(
      (d) => d.assignmentId == assignmentId,
      orElse: () => MyLoAssignmentDto(assignmentId: assignmentId),
    );
    return LoItineraryItem.compose(
      assignment: assignment,
      nominations: await getNominations(assignmentId),
      vehicles: await getVehicles(assignmentId),
    );
  }

  @override
  Future<LoIssueReport> reportIssue(LoIssueReport issue) async {
    final submitted = issue.copyWith(synced: true, status: 'submitted');
    _issues.insert(0, submitted);
    return submitted;
  }

  @override
  Future<List<LoIssueReport>> listReportedIssues() async =>
      List.unmodifiable(_issues);

  @override
  Future<List<int>> downloadBadge(String passId) async =>
      'BADGE-$passId'.codeUnits;
}
