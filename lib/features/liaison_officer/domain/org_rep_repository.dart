import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

abstract class OrgRepRepository {
  Future<Map<String, dynamic>?> getMyOrganisation();
  Future<List<LiaisonOfficerDto>> listLos();
  Future<LiaisonOfficerDto?> getLo(String loId);
  Future<LiaisonOfficerDto> nominateLo(Map<String, dynamic> body);
  Future<void> sendReminder(String loId);
  Future<void> sendPendingReminders();
  Future<List<int>> downloadImportTemplate();
  Future<void> bulkImport(List<int> bytes, String filename);

  Future<List<OrgSubNodalOfficerDto>> listSubNodals();
  Future<OrgSubNodalOfficerDto> createSubNodal(Map<String, dynamic> body);
  Future<OrgSubNodalOfficerDto> updateSubNodal(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteSubNodal(String id);

  Future<List<int>> downloadBadge(String passId);
}
