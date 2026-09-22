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

  Future<List<EmailTemplateDto>> listEmailTemplates();
  Future<EmailTemplateDto> createEmailTemplate(Map<String, dynamic> body);
  Future<EmailTemplateDto> updateEmailTemplate(
    String id,
    Map<String, dynamic> body,
  );

  Future<List<LoActivityDto>> listActivities();
  Future<LoActivityDto> createActivity(Map<String, dynamic> body);
  Future<LoActivityDto> updateActivity(String id, Map<String, dynamic> body);
  Future<void> setActivityActive(String id, bool active);

  Future<List<LiaisonOfficerDto>> listLiaisonOfficers();
  Future<LiaisonOfficerDto?> getLiaisonOfficer(String id);

  Future<List<LoAssignmentDto>> listAssignments();
  Future<LoAssignmentDto> createAssignment(Map<String, dynamic> body);
  Future<void> deleteAssignment(String id);
  Future<List<Map<String, dynamic>>> listAssignableDelegates();

  Future<List<LoTaskDto>> listTasks();
  Future<LoTaskDto> createTask(Map<String, dynamic> body);
  Future<LoTaskDto> updateTask(String id, Map<String, dynamic> body);
  Future<LoTaskDto> updateTaskStatus({
    required String id,
    required String statusCode,
    String? remarks,
  });

  Future<List<Map<String, dynamic>>> listDoLetterTemplates();
  Future<Map<String, dynamic>?> getBadgeQuota();
  Future<void> assignBadge(Map<String, dynamic> body);
}
