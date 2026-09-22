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
