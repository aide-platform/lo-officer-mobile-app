part of 'nodal_lo_bloc.dart';

abstract class NodalLoEvent {}

class NodalLoLoadRequested extends NodalLoEvent {}

class NodalLoClearMessages extends NodalLoEvent {}

// ── LO.2.1 Organisation types ───────────────────────────────────────────────

class NodalLoCreateOrgType extends NodalLoEvent {
  NodalLoCreateOrgType(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateOrgType extends NodalLoEvent {
  NodalLoUpdateOrgType(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class NodalLoSetOrgTypeActive extends NodalLoEvent {
  NodalLoSetOrgTypeActive(this.id, this.active);
  final String id;
  final bool active;
}

// ── LO.3.1 Organisations ────────────────────────────────────────────────────

class NodalLoCreateOrganisation extends NodalLoEvent {
  NodalLoCreateOrganisation(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateOrganisation extends NodalLoEvent {
  NodalLoUpdateOrganisation(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

// ── LO.2.3 Email templates ──────────────────────────────────────────────────

class NodalLoCreateEmailTemplate extends NodalLoEvent {
  NodalLoCreateEmailTemplate(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateEmailTemplate extends NodalLoEvent {
  NodalLoUpdateEmailTemplate(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class NodalLoDeleteEmailTemplate extends NodalLoEvent {
  NodalLoDeleteEmailTemplate(this.id);
  final String id;
}

// ── LO.2.4 Activities ───────────────────────────────────────────────────────

class NodalLoCreateActivity extends NodalLoEvent {
  NodalLoCreateActivity(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateActivity extends NodalLoEvent {
  NodalLoUpdateActivity(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class NodalLoSetActivityActive extends NodalLoEvent {
  NodalLoSetActivityActive(this.id, this.active);
  final String id;
  final bool active;
}

// ── LO.2.2 DO letter templates ──────────────────────────────────────────────

class NodalLoCreateDoTemplate extends NodalLoEvent {
  NodalLoCreateDoTemplate({
    required this.payload,
    this.fileBytes,
    this.filename,
  });
  final Map<String, dynamic> payload;
  final Uint8List? fileBytes;
  final String? filename;
}

class NodalLoUpdateDoTemplate extends NodalLoEvent {
  NodalLoUpdateDoTemplate(
    this.id, {
    required this.payload,
    this.fileBytes,
    this.filename,
  });
  final String id;
  final Map<String, dynamic> payload;
  final Uint8List? fileBytes;
  final String? filename;
}

class NodalLoDeleteDoTemplate extends NodalLoEvent {
  NodalLoDeleteDoTemplate(this.id);
  final String id;
}

class NodalLoDownloadDoTemplate extends NodalLoEvent {
  NodalLoDownloadDoTemplate(this.id, {this.filename});
  final String id;
  final String? filename;
}

// ── LO.3.2 / LO.3.3 Org DO + nomination ─────────────────────────────────────

class NodalLoRefreshOrgStatuses extends NodalLoEvent {}

class NodalLoDownloadOrgDo extends NodalLoEvent {
  NodalLoDownloadOrgDo(this.orgId, {this.filename});
  final String orgId;
  final String? filename;
}

class NodalLoUploadSignedDo extends NodalLoEvent {
  NodalLoUploadSignedDo({
    required this.orgId,
    required this.bytes,
    required this.filename,
    required this.signingAuthority,
    required this.checklist,
  });
  final String orgId;
  final Uint8List bytes;
  final String filename;
  final String signingAuthority;
  final Map<String, bool> checklist;
}

class NodalLoSendNomination extends NodalLoEvent {
  NodalLoSendNomination({
    required this.orgId,
    required this.emailTemplateId,
    this.attachments = const [],
  });
  final String orgId;
  final String emailTemplateId;
  final List<PickedAttachment> attachments;
}

class NodalLoSendNominationBulk extends NodalLoEvent {
  NodalLoSendNominationBulk({
    required this.orgIds,
    required this.emailTemplateId,
  });
  final List<String> orgIds;
  final String emailTemplateId;
}

// ── LO.6 LO review ──────────────────────────────────────────────────────────

class NodalLoSetLoFilters extends NodalLoEvent {
  NodalLoSetLoFilters({
    this.orgName,
    this.orgTypeName,
    this.profileStatus,
    this.language,
    this.availability,
    this.clearOrgName = false,
    this.clearOrgTypeName = false,
    this.clearProfileStatus = false,
    this.clearLanguage = false,
    this.clearAvailability = false,
  });
  final String? orgName;
  final String? orgTypeName;
  final String? profileStatus;
  final String? language;
  final String? availability;
  final bool clearOrgName;
  final bool clearOrgTypeName;
  final bool clearProfileStatus;
  final bool clearLanguage;
  final bool clearAvailability;
}

class NodalLoLoadLoDetail extends NodalLoEvent {
  NodalLoLoadLoDetail(this.loId);
  final String loId;
}

class NodalLoClearLoDetail extends NodalLoEvent {}

class NodalLoSendLoReminder extends NodalLoEvent {
  NodalLoSendLoReminder(this.loId);
  final String loId;
}

class NodalLoSendPendingLoReminders extends NodalLoEvent {}

class NodalLoSetLiaisonActive extends NodalLoEvent {
  NodalLoSetLiaisonActive(this.loId, this.active);
  final String loId;
  final bool active;
}

class NodalLoCreateLiaisonOfficer extends NodalLoEvent {
  NodalLoCreateLiaisonOfficer(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateLiaisonOfficer extends NodalLoEvent {
  NodalLoUpdateLiaisonOfficer(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class NodalLoDeleteLiaisonOfficer extends NodalLoEvent {
  NodalLoDeleteLiaisonOfficer(this.id);
  final String id;
}

class NodalLoDeleteOrganisation extends NodalLoEvent {
  NodalLoDeleteOrganisation(this.id);
  final String id;
}

// ── LO.7 Badges ─────────────────────────────────────────────────────────────

class NodalLoToggleLoSelection extends NodalLoEvent {
  NodalLoToggleLoSelection(this.loId);
  final String loId;
}

class NodalLoClearLoSelection extends NodalLoEvent {}

class NodalLoAssignBadge extends NodalLoEvent {
  NodalLoAssignBadge({this.personIds, this.badgeCatId});
  final List<String>? personIds;
  final String? badgeCatId;
}

class NodalLoDownloadBadge extends NodalLoEvent {
  NodalLoDownloadBadge(this.passId, {this.filename});
  final String passId;
  final String? filename;
}

// ── LO.8 Assignments + tasks ────────────────────────────────────────────────

class NodalLoCreateAssignment extends NodalLoEvent {
  NodalLoCreateAssignment(this.body);
  final Map<String, dynamic> body;
}

class NodalLoDeleteAssignment extends NodalLoEvent {
  NodalLoDeleteAssignment(this.id);
  final String id;
}

class NodalLoCreateTask extends NodalLoEvent {
  NodalLoCreateTask(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateTask extends NodalLoEvent {
  NodalLoUpdateTask(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class NodalLoDeleteTask extends NodalLoEvent {
  NodalLoDeleteTask(this.id);
  final String id;
}

class NodalLoSetTaskFilters extends NodalLoEvent {
  NodalLoSetTaskFilters({
    this.loId,
    this.delegateName,
    this.taskSource,
    this.status,
    this.date,
    this.clearLoId = false,
    this.clearDelegateName = false,
    this.clearTaskSource = false,
    this.clearStatus = false,
    this.clearDate = false,
  });
  final String? loId;
  final String? delegateName;
  final String? taskSource;
  final String? status;
  final String? date;
  final bool clearLoId;
  final bool clearDelegateName;
  final bool clearTaskSource;
  final bool clearStatus;
  final bool clearDate;
}

class NodalLoCreateSubNodal extends NodalLoEvent {
  NodalLoCreateSubNodal(this.body);
  final Map<String, dynamic> body;
}

class NodalLoUpdateSubNodal extends NodalLoEvent {
  NodalLoUpdateSubNodal(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class NodalLoDeleteSubNodal extends NodalLoEvent {
  NodalLoDeleteSubNodal(this.id);
  final String id;
}
