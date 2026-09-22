part of 'nodal_lo_bloc.dart';

enum NodalLoStatus { initial, loading, ready, failure }

class NodalLoState {
  final NodalLoStatus status;
  final List<LoOrgTypeDto> orgTypes;
  final List<LoOrganisationDto> organisations;
  final List<EmailTemplateDto> emailTemplates;
  final List<LoActivityDto> activities;
  final List<LiaisonOfficerDto> liaisonOfficers;
  final List<LoAssignmentDto> assignments;
  final List<LoTaskDto> tasks;
  final List<Map<String, dynamic>> doLetterTemplates;
  final Map<String, dynamic>? badgeQuota;
  final List<Map<String, dynamic>> assignableDelegates;
  final String? errorMessage;

  const NodalLoState({
    this.status = NodalLoStatus.initial,
    this.orgTypes = const [],
    this.organisations = const [],
    this.emailTemplates = const [],
    this.activities = const [],
    this.liaisonOfficers = const [],
    this.assignments = const [],
    this.tasks = const [],
    this.doLetterTemplates = const [],
    this.badgeQuota,
    this.assignableDelegates = const [],
    this.errorMessage,
  });

  NodalLoState copyWith({
    NodalLoStatus? status,
    List<LoOrgTypeDto>? orgTypes,
    List<LoOrganisationDto>? organisations,
    List<EmailTemplateDto>? emailTemplates,
    List<LoActivityDto>? activities,
    List<LiaisonOfficerDto>? liaisonOfficers,
    List<LoAssignmentDto>? assignments,
    List<LoTaskDto>? tasks,
    List<Map<String, dynamic>>? doLetterTemplates,
    Map<String, dynamic>? badgeQuota,
    List<Map<String, dynamic>>? assignableDelegates,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NodalLoState(
      status: status ?? this.status,
      orgTypes: orgTypes ?? this.orgTypes,
      organisations: organisations ?? this.organisations,
      emailTemplates: emailTemplates ?? this.emailTemplates,
      activities: activities ?? this.activities,
      liaisonOfficers: liaisonOfficers ?? this.liaisonOfficers,
      assignments: assignments ?? this.assignments,
      tasks: tasks ?? this.tasks,
      doLetterTemplates: doLetterTemplates ?? this.doLetterTemplates,
      badgeQuota: badgeQuota ?? this.badgeQuota,
      assignableDelegates: assignableDelegates ?? this.assignableDelegates,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
