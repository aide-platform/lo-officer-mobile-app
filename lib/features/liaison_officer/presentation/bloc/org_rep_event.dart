part of 'org_rep_bloc.dart';

abstract class OrgRepEvent {}

class OrgRepLoadRequested extends OrgRepEvent {}

class OrgRepNominateRequested extends OrgRepEvent {
  OrgRepNominateRequested(this.body);
  final Map<String, dynamic> body;
}

class OrgRepReminderRequested extends OrgRepEvent {
  OrgRepReminderRequested(this.loId);
  final String loId;
}

class OrgRepBulkReminderRequested extends OrgRepEvent {}

class OrgRepImportTemplateRequested extends OrgRepEvent {}

class OrgRepBulkImportRequested extends OrgRepEvent {
  OrgRepBulkImportRequested({
    required this.bytes,
    required this.filename,
  });
  final List<int> bytes;
  final String filename;
}

class OrgRepSubNodalCreateRequested extends OrgRepEvent {
  OrgRepSubNodalCreateRequested(this.body);
  final Map<String, dynamic> body;
}

class OrgRepSubNodalUpdateRequested extends OrgRepEvent {
  OrgRepSubNodalUpdateRequested(this.id, this.body);
  final String id;
  final Map<String, dynamic> body;
}

class OrgRepSubNodalDeleteRequested extends OrgRepEvent {
  OrgRepSubNodalDeleteRequested(this.id);
  final String id;
}

class OrgRepLoadLoDetail extends OrgRepEvent {
  OrgRepLoadLoDetail(this.loId);
  final String loId;
}

class OrgRepBadgeDownloadRequested extends OrgRepEvent {
  OrgRepBadgeDownloadRequested({
    required this.passId,
    this.filename,
  });
  final String passId;
  final String? filename;
}

class OrgRepClearMessages extends OrgRepEvent {}
