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

class LoPortalUploadRequested extends LoPortalEvent {
  LoPortalUploadRequested({
    required this.kind,
    required this.bytes,
    required this.filename,
  });
  final LoUploadKind kind;
  final Uint8List bytes;
  final String filename;
}

class LoPortalExperienceAdded extends LoPortalEvent {
  LoPortalExperienceAdded(this.body);
  final Map<String, dynamic> body;
}

class LoPortalExperienceDeleted extends LoPortalEvent {
  LoPortalExperienceDeleted(this.id);
  final String id;
}

class LoPortalLanguagesSaved extends LoPortalEvent {
  LoPortalLanguagesSaved(this.languages);
  final List<String> languages;
}

class LoPortalDelegateExtrasRequested extends LoPortalEvent {
  LoPortalDelegateExtrasRequested(this.assignmentId);
  final String assignmentId;
}

class LoPortalAlertLeadMinutesChanged extends LoPortalEvent {
  LoPortalAlertLeadMinutesChanged(this.minutes);
  final int minutes;
}

class LoPortalBadgeDownloadRequested extends LoPortalEvent {
  LoPortalBadgeDownloadRequested({
    required this.passId,
    this.filename,
  });
  final String passId;
  final String? filename;
}

class LoPortalClearMessages extends LoPortalEvent {}
