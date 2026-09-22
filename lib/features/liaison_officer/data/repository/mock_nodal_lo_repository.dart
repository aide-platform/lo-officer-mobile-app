import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';

class MockNodalLoRepository implements NodalLoRepository {
  final List<LoOrgTypeDto> _orgTypes = [
    const LoOrgTypeDto(
      id: 'ot-1',
      displayName: 'DPSU',
      description: 'Defence PSU',
      isActive: true,
    ),
  ];

  final List<LoOrganisationDto> _orgs = [
    const LoOrganisationDto(
      id: 'org-1',
      orgName: 'Bharat Electronics Limited',
      orgTypeId: 'ot-1',
      orgTypeName: 'DPSU',
      headName: 'Demo Head',
      headDesignation: 'CMD',
      primaryEmail: 'org@bel.co.in',
      primaryContact: '+919999999999',
      loCount: 3,
      loSubmittedCount: 1,
      isActive: true,
    ),
  ];

  final List<EmailTemplateDto> _emails = [
    const EmailTemplateDto(
      id: 'et-1',
      name: 'Nomination Request',
      purposeTag: 'DO Letter Communication',
      subject: 'Request to nominate Liaison Officers',
      body: 'Dear Sir/Madam, please nominate LOs...',
      isActive: true,
    ),
  ];

  final List<LoActivityDto> _activities = [
    const LoActivityDto(
      id: 'act-1',
      activityTitle: 'Airport Reception',
      activityDesc: 'Receive VIP at airport',
      isActive: true,
    ),
  ];

  final List<LiaisonOfficerDto> _los = [
    const LiaisonOfficerDto(
      id: 'lo-1',
      fullName: 'Demo Liaison',
      firstName: 'Demo',
      lastName: 'Liaison',
      orgName: 'BEL',
      orgTypeName: 'DPSU',
      profileStatus: 'SUBMITTED',
      profileComplete: true,
      officialEmail: 'liaison@test.com',
    ),
  ];

  final List<LoAssignmentDto> _assignments = [];
  final List<LoTaskDto> _tasks = [];

  @override
  Future<List<LoOrgTypeDto>> listOrgTypes() async => List.of(_orgTypes);

  @override
  Future<LoOrgTypeDto> createOrgType(Map<String, dynamic> body) async {
    final item = LoOrgTypeDto(
      id: 'ot-${_orgTypes.length + 1}',
      displayName: body['displayName']?.toString() ?? '',
      description: body['description']?.toString(),
      isActive: true,
    );
    _orgTypes.add(item);
    return item;
  }

  @override
  Future<LoOrgTypeDto> updateOrgType(String id, Map<String, dynamic> body) async {
    final idx = _orgTypes.indexWhere((e) => e.id == id);
    final item = LoOrgTypeDto(
      id: id,
      displayName: body['displayName']?.toString() ?? _orgTypes[idx].displayName,
      description: body['description']?.toString(),
      isActive: _orgTypes[idx].isActive,
    );
    _orgTypes[idx] = item;
    return item;
  }

  @override
  Future<void> setOrgTypeActive(String id, bool active) async {}

  @override
  Future<List<LoOrganisationDto>> listOrganisations() async => List.of(_orgs);

  @override
  Future<LoOrganisationDto> createOrganisation(Map<String, dynamic> body) async {
    final item = LoOrganisationDto(
      id: 'org-${_orgs.length + 1}',
      orgName: body['orgName']?.toString() ?? '',
      orgTypeId: body['orgTypeId']?.toString(),
      orgTypeName: 'DPSU',
      headName: body['headName']?.toString() ?? '',
      headDesignation: body['headDesignation']?.toString() ?? '',
      address: body['address']?.toString(),
      primaryEmail: body['primaryEmail']?.toString() ?? '',
      primaryContact: body['primaryContact']?.toString() ?? '',
      altEmail: body['altEmail']?.toString(),
      altContact: body['altContact']?.toString(),
      remarks: body['remarks']?.toString(),
      isActive: true,
      loCount: 0,
      loSubmittedCount: 0,
    );
    _orgs.add(item);
    return item;
  }

  @override
  Future<LoOrganisationDto> updateOrganisation(
    String id,
    Map<String, dynamic> body,
  ) async {
    return createOrganisation({...body, 'id': id});
  }

  @override
  Future<List<EmailTemplateDto>> listEmailTemplates() async => List.of(_emails);

  @override
  Future<EmailTemplateDto> createEmailTemplate(Map<String, dynamic> body) async {
    final item = EmailTemplateDto(
      id: 'et-${_emails.length + 1}',
      name: body['name']?.toString() ?? '',
      subject: body['subject']?.toString() ?? '',
      body: body['body']?.toString() ?? '',
      purposeTag: body['purposeTag']?.toString(),
      isActive: true,
    );
    _emails.add(item);
    return item;
  }

  @override
  Future<EmailTemplateDto> updateEmailTemplate(
    String id,
    Map<String, dynamic> body,
  ) async =>
      createEmailTemplate(body);

  @override
  Future<List<LoActivityDto>> listActivities() async => List.of(_activities);

  @override
  Future<LoActivityDto> createActivity(Map<String, dynamic> body) async {
    final item = LoActivityDto(
      id: 'act-${_activities.length + 1}',
      activityTitle: body['activityTitle']?.toString() ?? '',
      activityDesc: body['activityDesc']?.toString(),
      isActive: true,
    );
    _activities.add(item);
    return item;
  }

  @override
  Future<LoActivityDto> updateActivity(String id, Map<String, dynamic> body) async =>
      createActivity(body);

  @override
  Future<void> setActivityActive(String id, bool active) async {}

  @override
  Future<List<LiaisonOfficerDto>> listLiaisonOfficers() async => List.of(_los);

  @override
  Future<LiaisonOfficerDto?> getLiaisonOfficer(String id) async =>
      _los.cast<LiaisonOfficerDto?>().firstWhere(
            (e) => e?.id == id,
            orElse: () => null,
          );

  @override
  Future<List<LoAssignmentDto>> listAssignments() async =>
      List.of(_assignments);

  @override
  Future<LoAssignmentDto> createAssignment(Map<String, dynamic> body) async {
    final item = LoAssignmentDto(
      id: 'asg-${_assignments.length + 1}',
      loId: body['loId']?.toString(),
      loFullName: 'Demo Liaison',
      personId: body['personId']?.toString(),
      delegateName: body['delegateName']?.toString() ?? 'Delegate',
      delegateType: body['delegateType']?.toString(),
    );
    _assignments.add(item);
    return item;
  }

  @override
  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Map<String, dynamic>>> listAssignableDelegates() async => [
        {
          'attendeeId': 'del-1',
          'personId': 'per-1',
          'fullName': 'Air Marshal Demo VIP',
          'attendeeType': 'FOREIGN_INVITEE',
        },
      ];

  @override
  Future<List<LoTaskDto>> listTasks() async => List.of(_tasks);

  @override
  Future<LoTaskDto> createTask(Map<String, dynamic> body) async {
    final item = LoTaskDto(
      id: 'task-${_tasks.length + 1}',
      loId: body['loId']?.toString(),
      loAssignId: body['loAssignId']?.toString(),
      delegateName: body['delegateName']?.toString(),
      taskSource: body['taskSource']?.toString() ?? 'CUSTOM',
      activityId: body['activityId']?.toString(),
      taskTitle: body['taskTitle']?.toString() ?? '',
      taskDescription: body['taskDescription']?.toString(),
      scheduledDate: body['scheduledDate']?.toString(),
      scheduledTime: body['scheduledTime']?.toString(),
      locationVenue: body['locationVenue']?.toString(),
      remarks: body['remarks']?.toString(),
      statusCode: 'PENDING',
      statusName: 'Pending',
      loFullName: 'Demo Liaison',
    );
    _tasks.add(item);
    return item;
  }

  @override
  Future<LoTaskDto> updateTask(String id, Map<String, dynamic> body) async =>
      createTask(body);

  @override
  Future<LoTaskDto> updateTaskStatus({
    required String id,
    required String statusCode,
    String? remarks,
  }) async {
    return LoTaskDto(
      id: id,
      statusCode: statusCode,
      statusName: statusCode,
      taskTitle: 'Updated',
      loAssignId: 'x',
      taskSource: 'CUSTOM',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listDoLetterTemplates() async => [
        {
          'id': 'do-1',
          'name': 'Standard LO Nomination DO',
          'signingAuthority': 'Chairman, LO Committee',
        },
      ];

  @override
  Future<Map<String, dynamic>?> getBadgeQuota() async => {
        'allocated': 100,
        'used': 12,
        'remaining': 88,
      };

  @override
  Future<void> assignBadge(Map<String, dynamic> body) async {}
}
