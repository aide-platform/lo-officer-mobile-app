import 'dart:typed_data';

import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import 'package:liaison_officer/features/liaison_officer/data/local/do_letter_local_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/pdf/do_letter_pdf_builder.dart';
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
      address: 'Bengaluru',
      loCount: 3,
      loSubmittedCount: 1,
      loggedInCount: 2,
      profilesCompletedCount: 1,
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
      personId: 'person-lo-1',
      fullName: 'Demo Liaison',
      firstName: 'Demo',
      lastName: 'Liaison',
      orgId: 'org-1',
      orgName: 'Bharat Electronics Limited',
      orgTypeName: 'DPSU',
      officialEmail: 'liaison@test.com',
      profileStatus: 'SUBMITTED',
      profileComplete: true,
      languages: ['English', 'Hindi'],
      availabilityStatus: 'Available',
      currentPassId: 'pass-1',
      currentPassNumber: 'LO-1001',
      currentBadgeCatId: 'badge-cat-1',
      currentBadgeCatName: 'LO Badge',
    ),
  ];

  final List<LoAssignmentDto> _assignments = [];
  final List<LoTaskDto> _tasks = [];
  final List<DoLetterTemplateDto> _doTemplates = [
    const DoLetterTemplateDto(
      id: 'do-1',
      templateName: 'Standard LO Nomination DO',
      signingAuthority: 'Chairman, LO Committee',
      recipientType: 'ot-1',
      applicableOrgTypeIds: ['ot-1'],
      isActive: true,
      templateFileName: 'lo-do.pdf',
    ),
  ];

  Map<String, dynamic> _quota = {
    'allocated': 100,
    'used': 12,
    'remaining': 88,
    'badgeCatId': 'badge-cat-1',
  };

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
      description: body['description']?.toString() ?? _orgTypes[idx].description,
      isActive: _orgTypes[idx].isActive,
    );
    _orgTypes[idx] = item;
    return item;
  }

  @override
  Future<void> setOrgTypeActive(String id, bool active) async {
    final idx = _orgTypes.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _orgTypes[idx];
    _orgTypes[idx] = LoOrgTypeDto(
      id: cur.id,
      code: cur.code,
      displayName: cur.displayName,
      description: cur.description,
      isActive: active,
    );
  }

  @override
  Future<List<LoOrganisationDto>> listOrganisations() async => List.of(_orgs);

  @override
  Future<LoOrganisationDto> createOrganisation(Map<String, dynamic> body) async {
    final typeId = body['orgTypeId']?.toString();
    String? typeName;
    for (final t in _orgTypes) {
      if (t.id == typeId) typeName = t.displayName;
    }
    final item = LoOrganisationDto(
      id: 'org-${_orgs.length + 1}',
      orgName: body['orgName']?.toString() ?? '',
      orgTypeId: typeId,
      orgTypeName: typeName,
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
    final idx = _orgs.indexWhere((e) => e.id == id);
    final created = await createOrganisation(body);
    final item = LoOrganisationDto(
      id: id,
      orgName: created.orgName,
      orgTypeId: created.orgTypeId,
      orgTypeName: created.orgTypeName,
      headName: created.headName,
      headDesignation: created.headDesignation,
      address: created.address,
      primaryEmail: created.primaryEmail,
      primaryContact: created.primaryContact,
      altEmail: created.altEmail,
      altContact: created.altContact,
      remarks: created.remarks,
      isActive: true,
      loCount: _orgs[idx].loCount,
      loSubmittedCount: _orgs[idx].loSubmittedCount,
    );
    _orgs[idx] = item;
    _orgs.removeLast();
    return item;
  }

  @override
  Future<void> deleteOrganisation(String id) async {
    _orgs.removeWhere((e) => e.id == id);
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
  ) async {
    final idx = _emails.indexWhere((e) => e.id == id);
    final item = EmailTemplateDto(
      id: id,
      name: body['name']?.toString() ?? _emails[idx].name,
      subject: body['subject']?.toString() ?? _emails[idx].subject,
      body: body['body']?.toString() ?? _emails[idx].body,
      purposeTag: body['purposeTag']?.toString() ?? _emails[idx].purposeTag,
      isActive: body['isActive'] as bool? ?? _emails[idx].isActive,
    );
    _emails[idx] = item;
    return item;
  }

  @override
  Future<void> deleteEmailTemplate(String id) async {
    _emails.removeWhere((e) => e.id == id);
  }

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
  Future<LoActivityDto> updateActivity(String id, Map<String, dynamic> body) async {
    final idx = _activities.indexWhere((e) => e.id == id);
    final item = LoActivityDto(
      id: id,
      activityTitle:
          body['activityTitle']?.toString() ?? _activities[idx].activityTitle,
      activityDesc:
          body['activityDesc']?.toString() ?? _activities[idx].activityDesc,
      isActive: body['isActive'] as bool? ?? _activities[idx].isActive,
    );
    _activities[idx] = item;
    return item;
  }

  @override
  Future<void> setActivityActive(String id, bool active) async {
    final idx = _activities.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final cur = _activities[idx];
    _activities[idx] = LoActivityDto(
      id: cur.id,
      activityTitle: cur.activityTitle,
      activityDesc: cur.activityDesc,
      isActive: active,
    );
  }

  @override
  Future<List<LiaisonOfficerDto>> listLiaisonOfficers() async => List.of(_los);

  @override
  Future<LiaisonOfficerDto?> getLiaisonOfficer(String id) async {
    for (final lo in _los) {
      if (lo.id == id) return lo;
    }
    return null;
  }

  @override
  Future<LiaisonOfficerDto> createLiaisonOfficer(
    Map<String, dynamic> body,
  ) async {
    final orgId = body['orgId']?.toString();
    String? orgName;
    String? orgTypeName;
    for (final o in _orgs) {
      if (o.id == orgId) {
        orgName = o.orgName;
        orgTypeName = o.orgTypeName;
        break;
      }
    }
    final first = body['firstName']?.toString() ?? '';
    final last = body['lastName']?.toString() ?? '';
    final item = LiaisonOfficerDto(
      id: 'lo-${_los.length + 1}',
      orgId: orgId,
      orgName: orgName,
      orgTypeName: orgTypeName,
      salutationName: body['salutation']?.toString(),
      firstName: first,
      lastName: last,
      fullName: '$first $last'.trim(),
      rank: body['rank']?.toString(),
      designation: body['designation']?.toString(),
      officialEmail: body['primaryEmail']?.toString(),
      officialContact: body['primaryMobile']?.toString(),
      profileStatus: 'PENDING',
      profileComplete: false,
      isActive: true,
      photoFileId: 'mock-photo-1',
      signatureFileId: 'mock-sig-1',
    );
    _los.add(item);
    return item;
  }

  @override
  Future<LiaisonOfficerDto> updateLiaisonOfficer(
    String id,
    Map<String, dynamic> body,
  ) async {
    final i = _los.indexWhere((e) => e.id == id);
    if (i < 0) throw StateError('LO not found');
    final cur = _los[i];
    final orgId = body['orgId']?.toString() ?? cur.orgId;
    String? orgName = cur.orgName;
    String? orgTypeName = cur.orgTypeName;
    for (final o in _orgs) {
      if (o.id == orgId) {
        orgName = o.orgName;
        orgTypeName = o.orgTypeName;
        break;
      }
    }
    final first = body['firstName']?.toString() ?? cur.firstName ?? '';
    final last = body['lastName']?.toString() ?? cur.lastName ?? '';
    final item = LiaisonOfficerDto(
      id: id,
      personId: cur.personId,
      orgId: orgId,
      orgName: orgName,
      orgTypeName: orgTypeName,
      salutationName: body['salutation']?.toString() ?? cur.salutationName,
      firstName: first,
      lastName: last,
      fullName: '$first $last'.trim(),
      rank: body['rank']?.toString() ?? cur.rank,
      designation: body['designation']?.toString() ?? cur.designation,
      officialEmail: body['primaryEmail']?.toString() ?? cur.officialEmail,
      officialContact:
          body['primaryMobile']?.toString() ?? cur.officialContact,
      profileStatus: cur.profileStatus,
      profileComplete: cur.profileComplete,
      isActive: cur.isActive,
      photoFileId: cur.photoFileId,
      signatureFileId: cur.signatureFileId,
      aadhaarFrontId: cur.aadhaarFrontId,
      aadhaarBackId: cur.aadhaarBackId,
      orgBadgeFrontId: cur.orgBadgeFrontId,
      orgBadgeBackId: cur.orgBadgeBackId,
      currentPassId: cur.currentPassId,
      currentPassNumber: cur.currentPassNumber,
    );
    _los[i] = item;
    return item;
  }

  @override
  Future<void> deleteLiaisonOfficer(String id) async {
    _los.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<int>> fetchFileBytes(String fileId) async {
    // Minimal 1x1 PNG
    return const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ];
  }

  @override
  Future<List<LoExperienceDto>> getLoExperiences(String loId) async => [
        const LoExperienceDto(
          id: 'exp-1',
          eventName: 'Aero India 2023',
          year: 2023,
          roleResponsibilities: 'LO for foreign delegation',
          delegateDetails: 'Air Chief',
        ),
      ];

  @override
  Future<List<String>> getLoLanguages(String loId) async =>
      ['English', 'Hindi', 'French'];

  @override
  Future<void> sendLoReminder(String loId) async {}

  @override
  Future<void> sendPendingLoReminders() async {}

  @override
  Future<void> setLiaisonOfficerActive(String loId, bool active) async {
    final i = _los.indexWhere((e) => e.id == loId);
    if (i < 0) return;
    final cur = _los[i];
    _los[i] = LiaisonOfficerDto(
      id: cur.id,
      firstName: cur.firstName,
      lastName: cur.lastName,
      fullName: cur.fullName,
      orgName: cur.orgName,
      orgTypeName: cur.orgTypeName,
      officialEmail: cur.officialEmail,
      profileStatus: cur.profileStatus,
      profileComplete: cur.profileComplete,
      isActive: active,
    );
  }

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
    await MockEmailNotifier.send(
      to: 'liaison@test.com',
      subject: 'New LO assignment',
      body: 'You have been assigned to ${item.delegateName}',
    );
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
          'designation': 'Air Marshal',
          'attendeeType': 'FOREIGN_INVITEE',
          'countryName': 'Algeria',
          'arrivalDate': '2026-12-09',
          'arrivalTime': '12:12',
          'departureDate': '2026-12-25',
          'departureTime': '12:12',
          'familyCount': 0,
        },
        {
          'attendeeId': 'del-2',
          'personId': 'per-2',
          'fullName': 'Dr. Murali Krishna',
          'designation': 'RRM',
          'attendeeType': 'FOREIGN_INVITEE',
          'countryName': 'Algeria',
          'arrivalDate': '2026-12-09',
          'arrivalTime': '12:12',
          'departureDate': '2026-12-25',
          'departureTime': '12:12',
          'familyCount': 0,
        },
      ];

  @override
  Future<Map<String, dynamic>?> getDelegateProfile({
    required String attendeeType,
    required String attendeeId,
  }) async =>
      {
        'fullName': 'Air Marshal Demo VIP',
        'passportNumber': 'Z1234567',
        'decorations': 'AVSM',
        'ministry': 'Defence',
      };

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
    await MockEmailNotifier.send(
      to: 'liaison@test.com',
      subject: 'New task assigned',
      body: item.taskTitle ?? '',
    );
    return item;
  }

  @override
  Future<LoTaskDto> updateTask(String id, Map<String, dynamic> body) async {
    final idx = _tasks.indexWhere((e) => e.id == id);
    if (idx < 0) throw StateError('Task not found');
    final cur = _tasks[idx];
    final item = LoTaskDto(
      id: id,
      loId: body['loId']?.toString() ?? cur.loId,
      loAssignId: body['loAssignId']?.toString() ?? cur.loAssignId,
      delegateName: body['delegateName']?.toString() ?? cur.delegateName,
      taskSource: body['taskSource']?.toString() ?? cur.taskSource,
      activityId: body['activityId']?.toString() ?? cur.activityId,
      taskTitle: body['taskTitle']?.toString() ?? cur.taskTitle,
      taskDescription:
          body['taskDescription']?.toString() ?? cur.taskDescription,
      scheduledDate: body['scheduledDate']?.toString() ?? cur.scheduledDate,
      scheduledTime: body['scheduledTime']?.toString() ?? cur.scheduledTime,
      locationVenue: body['locationVenue']?.toString() ?? cur.locationVenue,
      remarks: body['remarks']?.toString() ?? cur.remarks,
      statusCode: cur.statusCode,
      statusName: cur.statusName,
    );
    _tasks[idx] = item;
    return item;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((e) => e.id == id);
  }


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
      remarks: remarks,
    );
  }

  @override
  Future<List<DoLetterTemplateDto>> listDoLetterTemplates() async =>
      List.of(_doTemplates);

  @override
  Future<DoLetterTemplateDto> createDoLetterTemplate({
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    final recipient = payload['recipientType']?.toString() ?? '';
    final item = DoLetterTemplateDto(
      id: 'do-${_doTemplates.length + 1}',
      templateName: payload['templateName']?.toString() ?? '',
      signingAuthority: payload['signingAuthority']?.toString() ?? '',
      recipientType: recipient,
      applicableOrgTypeIds: recipient
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      isActive: true,
      templateFileName: filename ?? 'template.pdf',
    );
    _doTemplates.add(item);
    return item;
  }

  @override
  Future<DoLetterTemplateDto> updateDoLetterTemplate(
    String id, {
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    final created = await createDoLetterTemplate(
      payload: payload,
      fileBytes: fileBytes,
      filename: filename,
    );
    final idx = _doTemplates.indexWhere((e) => e.id == id);
    final item = DoLetterTemplateDto(
      id: id,
      templateName: created.templateName,
      signingAuthority: created.signingAuthority,
      recipientType: created.recipientType,
      applicableOrgTypeIds: created.applicableOrgTypeIds,
      isActive: payload['isActive'] as bool? ?? true,
      templateFileName: created.templateFileName,
    );
    if (idx >= 0) {
      _doTemplates[idx] = item;
      _doTemplates.removeLast();
    }
    return item;
  }

  @override
  Future<void> deleteDoLetterTemplate(String id) async {
    _doTemplates.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<int>> downloadDoLetterTemplateFile(String id) async =>
      '%PDF-1.4 mock DO letter for $id'.codeUnits;

  @override
  Future<List<int>> downloadOrgDoLetter(String orgId) async {
    LoOrganisationDto? org;
    for (final o in _orgs) {
      if (o.id == orgId) org = o;
    }
    if (org == null) return const [];
    DoLetterTemplateDto? t;
    for (final tpl in _doTemplates) {
      if (org.orgTypeId != null &&
          (tpl.applicableOrgTypeIds.contains(org.orgTypeId) ||
              tpl.recipientType == org.orgTypeId)) {
        t = tpl;
        break;
      }
    }
    t ??= _doTemplates.isEmpty ? null : _doTemplates.first;
    return DoLetterPdfBuilder.build(org: org, template: t);
  }

  @override
  Future<void> uploadSignedDoLetter({
    required String orgId,
    required Uint8List bytes,
    required String filename,
    required String signingAuthority,
    required Map<String, bool> checklist,
  }) async {
    if (checklist.values.any((v) => !v)) {
      throw Exception('All checklist items must be confirmed.');
    }
    await DoLetterLocalStore.markSigned(
      orgId: orgId,
      signingAuthority: signingAuthority,
      pdfBytes: bytes,
    );
  }

  @override
  Future<void> sendNominationEmail({
    required String orgId,
    required String emailTemplateId,
    List<PickedAttachment> attachments = const [],
  }) async {
    LoOrganisationDto? org;
    for (final o in _orgs) {
      if (o.id == orgId) org = o;
    }
    EmailTemplateDto? tpl;
    for (final e in _emails) {
      if (e.id == emailTemplateId) tpl = e;
    }
    final merged = List<PickedAttachment>.from(attachments);
    final tag = (tpl?.purposeTag ?? '').toLowerCase();
    if (tag.contains('do letter') || tag.contains('do_letter')) {
      final signed = await DoLetterLocalStore.signedPdfBytes(orgId);
      if (signed != null && signed.isNotEmpty) {
        merged.insert(
          0,
          PickedAttachment(bytes: signed, filename: 'signed-do-$orgId.pdf'),
        );
      }
    }
    await MockEmailNotifier.send(
      to: org?.primaryEmail ?? orgId,
      subject: tpl?.subject ?? 'Nomination',
      body:
          '${tpl?.body ?? 'Please nominate LOs'}\n\nAttachments: ${merged.map((e) => e.filename).join(', ')}',
    );
    await DoLetterLocalStore.markNominationSent(orgId);
  }

  @override
  Future<void> sendNominationEmailBulk({
    required List<String> orgIds,
    required String emailTemplateId,
  }) async {
    for (final id in orgIds) {
      await sendNominationEmail(orgId: id, emailTemplateId: emailTemplateId);
    }
  }

  @override
  Future<Map<String, dynamic>> orgDoLetterStatus(String orgId) =>
      DoLetterLocalStore.statusFor(orgId);

  @override
  Future<Map<String, dynamic>?> getBadgeQuota() async => Map.of(_quota);

  @override
  Future<void> assignBadge(Map<String, dynamic> body) async {
    final ids = (body['personIds'] as List?) ?? const [];
    final remaining = (_quota['remaining'] as num?)?.toInt() ?? 0;
    if (ids.length > remaining) {
      throw Exception('Badge quota exceeded. Remaining: $remaining');
    }
    _quota = {
      ..._quota,
      'used': ((_quota['used'] as num?)?.toInt() ?? 0) + ids.length,
      'remaining': remaining - ids.length,
    };
  }

  @override
  Future<List<int>> downloadBadge(String passId) async =>
      'BADGE-$passId'.codeUnits;

  final List<OrgSubNodalOfficerDto> _subNodals = [
    const OrgSubNodalOfficerDto(
      id: 'sn-nodal-1',
      fullName: 'Committee Sub Nodal',
      email: 'subnodal@aeroindia.gov.in',
      mobile: '+919888877766',
      designation: 'Deputy Nodal',
      isActive: true,
    ),
  ];

  @override
  Future<List<OrgSubNodalOfficerDto>> listSubNodals() async =>
      List.of(_subNodals);

  @override
  Future<OrgSubNodalOfficerDto> createSubNodal(Map<String, dynamic> body) async {
    final item = OrgSubNodalOfficerDto(
      id: 'sn-${DateTime.now().millisecondsSinceEpoch}',
      fullName: body['fullName']?.toString() ?? '',
      email: body['email']?.toString() ?? '',
      mobile: body['mobile']?.toString(),
      designation: body['designation']?.toString(),
      isActive: body['isActive'] as bool? ?? true,
      canApprove: body['canApprove'] as bool?,
    );
    _subNodals.add(item);
    return item;
  }

  @override
  Future<OrgSubNodalOfficerDto> updateSubNodal(
    String id,
    Map<String, dynamic> body,
  ) async {
    final i = _subNodals.indexWhere((e) => e.id == id);
    final prev = i >= 0 ? _subNodals[i] : null;
    final item = OrgSubNodalOfficerDto(
      id: id,
      orgId: prev?.orgId,
      orgName: prev?.orgName,
      fullName: body['fullName']?.toString() ?? prev?.fullName ?? '',
      email: body['email']?.toString() ?? prev?.email ?? '',
      mobile: body['mobile']?.toString() ?? prev?.mobile,
      designation: body['designation']?.toString() ?? prev?.designation,
      isActive: body['isActive'] as bool? ?? prev?.isActive,
      canApprove: body['canApprove'] as bool? ?? prev?.canApprove,
    );
    if (i >= 0) _subNodals[i] = item;
    return item;
  }

  @override
  Future<void> deleteSubNodal(String id) async {
    _subNodals.removeWhere((e) => e.id == id);
  }
}
