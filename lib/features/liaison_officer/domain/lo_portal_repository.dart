import 'dart:typed_data';

import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';

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

  /// First-class movement update (arrival / transfer / venue / departure).
  Future<MyLoAssignmentDto> updateMovement({
    required String assignmentId,
    required LoMovementUpdate movement,
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

  /// Composed itinerary from travel + nominations + vehicles (no CAP endpoint).
  Future<List<LoItineraryItem>> getItinerary(String assignmentId);

  /// Report operational issue — CAP POST; Hive offline queue on failure.
  Future<LoIssueReport> reportIssue(LoIssueReport issue);

  Future<List<LoIssueReport>> listReportedIssues();

  Future<List<int>> downloadBadge(String passId);
}
