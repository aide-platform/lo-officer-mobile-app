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
}
