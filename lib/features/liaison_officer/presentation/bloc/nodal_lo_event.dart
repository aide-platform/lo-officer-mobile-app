part of 'nodal_lo_bloc.dart';

abstract class NodalLoEvent {}

class NodalLoLoadRequested extends NodalLoEvent {}

class NodalLoCreateOrgType extends NodalLoEvent {
  NodalLoCreateOrgType(this.body);
  final Map<String, dynamic> body;
}

class NodalLoCreateOrganisation extends NodalLoEvent {
  NodalLoCreateOrganisation(this.body);
  final Map<String, dynamic> body;
}

class NodalLoCreateActivity extends NodalLoEvent {
  NodalLoCreateActivity(this.body);
  final Map<String, dynamic> body;
}

class NodalLoCreateEmailTemplate extends NodalLoEvent {
  NodalLoCreateEmailTemplate(this.body);
  final Map<String, dynamic> body;
}

class NodalLoCreateAssignment extends NodalLoEvent {
  NodalLoCreateAssignment(this.body);
  final Map<String, dynamic> body;
}

class NodalLoCreateTask extends NodalLoEvent {
  NodalLoCreateTask(this.body);
  final Map<String, dynamic> body;
}

class NodalLoAssignBadge extends NodalLoEvent {
  NodalLoAssignBadge(this.body);
  final Map<String, dynamic> body;
}

class NodalLoDeleteAssignment extends NodalLoEvent {
  NodalLoDeleteAssignment(this.id);
  final String id;
}
