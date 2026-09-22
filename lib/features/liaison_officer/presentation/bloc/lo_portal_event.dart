part of 'lo_portal_bloc.dart';

abstract class LoPortalEvent {}

class LoPortalLoadRequested extends LoPortalEvent {}

class LoPortalProfileSaved extends LoPortalEvent {
  LoPortalProfileSaved(this.body);
  final Map<String, dynamic> body;
}

class LoPortalTaskStatusUpdated extends LoPortalEvent {
  LoPortalTaskStatusUpdated({
    required this.taskId,
    required this.statusCode,
    this.remarks,
  });
  final String taskId;
  final String statusCode;
  final String? remarks;
}

class LoPortalTravelUpdated extends LoPortalEvent {
  LoPortalTravelUpdated({
    required this.assignmentId,
    required this.body,
  });
  final String assignmentId;
  final Map<String, dynamic> body;
}

class LoPortalAlertsRefreshRequested extends LoPortalEvent {}
