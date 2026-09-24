import 'dart:typed_data';

import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

abstract class NodalLoRepository {
  Future<List<LoOrgTypeDto>> listOrgTypes();
  Future<LoOrgTypeDto> createOrgType(Map<String, dynamic> body);
  Future<LoOrgTypeDto> updateOrgType(String id, Map<String, dynamic> body);
  Future<void> setOrgTypeActive(String id, bool active);

  Future<List<LoOrganisationDto>> listOrganisations();
  Future<LoOrganisationDto> createOrganisation(Map<String, dynamic> body);
  Future<LoOrganisationDto> updateOrganisation(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteOrganisation(String id);

  Future<List<EmailTemplateDto>> listEmailTemplates();
  Future<EmailTemplateDto> createEmailTemplate(Map<String, dynamic> body);
  Future<EmailTemplateDto> updateEmailTemplate(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteEmailTemplate(String id);

  Future<List<LoActivityDto>> listActivities();
  Future<LoActivityDto> createActivity(Map<String, dynamic> body);
  Future<LoActivityDto> updateActivity(String id, Map<String, dynamic> body);
  Future<void> setActivityActive(String id, bool active);

  Future<List<LiaisonOfficerDto>> listLiaisonOfficers();
  Future<LiaisonOfficerDto?> getLiaisonOfficer(String id);
  Future<LiaisonOfficerDto> createLiaisonOfficer(Map<String, dynamic> body);
  Future<LiaisonOfficerDto> updateLiaisonOfficer(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteLiaisonOfficer(String id);
  Future<List<LoExperienceDto>> getLoExperiences(String loId);
  Future<List<String>> getLoLanguages(String loId);
  Future<void> sendLoReminder(String loId);
  Future<void> sendPendingLoReminders();
  Future<void> setLiaisonOfficerActive(String loId, bool active);
  Future<List<int>> fetchFileBytes(String fileId);

  Future<List<LoAssignmentDto>> listAssignments();
  Future<LoAssignmentDto> createAssignment(Map<String, dynamic> body);
  Future<void> deleteAssignment(String id);
  Future<List<Map<String, dynamic>>> listAssignableDelegates();
  Future<Map<String, dynamic>?> getDelegateProfile({
    required String attendeeType,
    required String attendeeId,
  });

  Future<List<LoTaskDto>> listTasks();
  Future<LoTaskDto> createTask(Map<String, dynamic> body);
  Future<LoTaskDto> updateTask(String id, Map<String, dynamic> body);
  Future<void> deleteTask(String id);
  Future<LoTaskDto> updateTaskStatus({
    required String id,
    required String statusCode,
    String? remarks,
  });

  Future<List<DoLetterTemplateDto>> listDoLetterTemplates();
  Future<DoLetterTemplateDto> createDoLetterTemplate({
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  });
  Future<DoLetterTemplateDto> updateDoLetterTemplate(
    String id, {
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  });
  Future<void> deleteDoLetterTemplate(String id);
  Future<List<int>> downloadDoLetterTemplateFile(String id);

  /// LO.3.2 — resolve template by org type and return PDF bytes (or empty).
  Future<List<int>> downloadOrgDoLetter(String orgId);

  /// LO.3.2 — upload signed PDF after checklist confirmation.
  Future<void> uploadSignedDoLetter({
    required String orgId,
    required Uint8List bytes,
    required String filename,
    required String signingAuthority,
    required Map<String, bool> checklist,
  });

  /// LO.3.3 — send nomination email (individual).
  Future<void> sendNominationEmail({
    required String orgId,
    required String emailTemplateId,
    List<PickedAttachment> attachments,
  });

  Future<void> sendNominationEmailBulk({
    required List<String> orgIds,
    required String emailTemplateId,
  });

  Future<Map<String, dynamic>> orgDoLetterStatus(String orgId);

  Future<Map<String, dynamic>?> getBadgeQuota();
  Future<void> assignBadge(Map<String, dynamic> body);
  Future<List<int>> downloadBadge(String passId);

  Future<List<OrgSubNodalOfficerDto>> listSubNodals();
  Future<OrgSubNodalOfficerDto> createSubNodal(Map<String, dynamic> body);
  Future<OrgSubNodalOfficerDto> updateSubNodal(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteSubNodal(String id);
}

class PickedAttachment {
  const PickedAttachment({required this.bytes, required this.filename});
  final Uint8List bytes;
  final String filename;
}
