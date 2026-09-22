import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';

class MockLoPortalRepository implements LoPortalRepository {
  final List<MyLoAssignmentDto> _delegates = [
    const MyLoAssignmentDto(
      assignmentId: 'asn-1',
      fullName: 'Air Marshal Demo VIP',
      salutation: 'Air Marshal',
      designation: 'Commander',
      organisation: 'IAF',
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

  @override
  Future<LiaisonOfficerDto?> getMyProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const LiaisonOfficerDto(
      id: 'lo-1',
      firstName: 'Demo',
      lastName: 'Liaison',
      fullName: 'Demo Liaison',
      orgName: 'BEL',
      orgTypeName: 'DPSU',
      officialEmail: 'liaison@test.com',
      profileStatus: 'DRAFT',
      profileComplete: false,
    );
  }

  @override
  Future<LiaisonOfficerDto> updateMyProfile(Map<String, dynamic> body) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return LiaisonOfficerDto(
      id: 'lo-1',
      firstName: body['firstName']?.toString() ?? 'Demo',
      lastName: body['lastName']?.toString() ?? 'Liaison',
      fullName:
          '${body['firstName'] ?? 'Demo'} ${body['lastName'] ?? 'Liaison'}',
      orgName: 'BEL',
      orgTypeName: 'DPSU',
      officialEmail: 'liaison@test.com',
      profileStatus: 'SUBMITTED',
      profileComplete: true,
      designation: body['designation']?.toString(),
      rank: body['rank']?.toString(),
      personalEmail: body['personalEmail']?.toString(),
      personalContact: body['personalContact']?.toString(),
      officialContact: body['officialContact']?.toString(),
      whatsappNumber: body['whatsappNumber']?.toString(),
      aadhaarNumber: body['aadhaarNumber']?.toString(),
      orgIdNumber: body['orgIdNumber']?.toString(),
      dateOfBirth: body['dateOfBirth']?.toString(),
      hasPrevLoExp: body['hasPrevLoExp'] as bool?,
    );
  }

  @override
  Future<List<MyLoAssignmentDto>> getMyDelegates() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.of(_delegates);
  }

  @override
  Future<List<LoTaskDto>> getMyTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.of(_tasks);
  }

  @override
  Future<LoTaskDto> updateTaskStatus({
    required String taskId,
    required String statusCode,
    String? remarks,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx < 0) throw StateError('Task not found');
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
      statusName: statusCode.replaceAll('_', ' ').toLowerCase(),
    );
    _tasks[idx] = updated;
    return updated;
  }

  @override
  Future<MyLoAssignmentDto> updateTravel({
    required String assignmentId,
    required Map<String, dynamic> body,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final idx = _delegates.indexWhere((d) => d.assignmentId == assignmentId);
    if (idx < 0) throw StateError('Assignment not found');
    final cur = _delegates[idx];
    final updated = MyLoAssignmentDto(
      assignmentId: cur.assignmentId,
      fullName: cur.fullName,
      salutation: cur.salutation,
      designation: cur.designation,
      organisation: cur.organisation,
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
}
