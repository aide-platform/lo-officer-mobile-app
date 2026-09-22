import 'dart:typed_data';

import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

abstract class LoPortalRepository {
  Future<LiaisonOfficerDto?> getMyProfile();
  Future<LiaisonOfficerDto> updateMyProfile(Map<String, dynamic> body);
  Future<List<MyLoAssignmentDto>> getMyDelegates();
  Future<List<LoTaskDto>> getMyTasks();
  Future<LoTaskDto> updateTaskStatus({
    required String taskId,
    required String statusCode,
    String? remarks,
  });
  Future<MyLoAssignmentDto> updateTravel({
    required String assignmentId,
    required Map<String, dynamic> body,
  });

  /// CAP `PUT …/assignments/{id}/arrival-flight` (actual arrival for LO.9).
  Future<MyLoAssignmentDto> updateArrivalFlight({
    required String assignmentId,
    required Map<String, dynamic> body,
  });

  Future<void> uploadPhoto(Uint8List bytes, String filename);
  Future<void> uploadSignature(Uint8List bytes, String filename);
  Future<void> uploadOrgBadgeFront(Uint8List bytes, String filename);
  Future<void> uploadOrgBadgeBack(Uint8List bytes, String filename);
  Future<void> uploadAadhaarFront(Uint8List bytes, String filename);
  Future<void> uploadAadhaarBack(Uint8List bytes, String filename);

  Future<List<LoExperienceDto>> listExperiences();
  Future<LoExperienceDto> addExperience(Map<String, dynamic> body);
  Future<void> deleteExperience(String id);

  Future<List<String>> listLanguages();
  Future<void> setLanguages(List<String> languages);

  Future<List<Map<String, dynamic>>> getVehicles(String assignmentId);
  Future<List<Map<String, dynamic>>> getNominations(String assignmentId);

  Future<List<int>> downloadBadge(String passId);
}
