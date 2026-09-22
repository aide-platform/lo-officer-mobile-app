part of 'lo_portal_bloc.dart';

enum LoPortalStatus { initial, loading, saving, ready, failure }

class LoPortalState {
  final LoPortalStatus status;
  final LiaisonOfficerDto? profile;
  final List<MyLoAssignmentDto> delegates;
  final List<LoTaskDto> tasks;
  final List<Map<String, dynamic>> alerts;
  final String? errorMessage;

  const LoPortalState({
    this.status = LoPortalStatus.initial,
    this.profile,
    this.delegates = const [],
    this.tasks = const [],
    this.alerts = const [],
    this.errorMessage,
  });

  LoPortalState copyWith({
    LoPortalStatus? status,
    LiaisonOfficerDto? profile,
    List<MyLoAssignmentDto>? delegates,
    List<LoTaskDto>? tasks,
    List<Map<String, dynamic>>? alerts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoPortalState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      delegates: delegates ?? this.delegates,
      tasks: tasks ?? this.tasks,
      alerts: alerts ?? this.alerts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
