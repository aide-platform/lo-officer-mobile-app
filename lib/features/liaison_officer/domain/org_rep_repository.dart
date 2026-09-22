import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

abstract class OrgRepRepository {
  Future<Map<String, dynamic>?> getMyOrganisation();
  Future<List<LiaisonOfficerDto>> listLos();
  Future<LiaisonOfficerDto> nominateLo(Map<String, dynamic> body);
  Future<void> sendReminder(String loId);
  Future<void> sendPendingReminders();
  Future<List<int>> downloadImportTemplate();
  Future<void> bulkImport(List<int> bytes, String filename);
}
