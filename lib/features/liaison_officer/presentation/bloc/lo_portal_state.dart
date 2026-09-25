part of 'lo_portal_bloc.dart';

enum LoPortalStatus { initial, loading, saving, ready, failure }

class LoPortalState {
  final LoPortalStatus status;
  final LiaisonOfficerDto? profile;
  final List<MyLoAssignmentDto> delegates;
  final List<LoTaskDto> tasks;
  final List<Map<String, dynamic>> alerts;
  final List<LoExperienceDto> experiences;
  final List<String> languages;
  final Map<String, List<Map<String, dynamic>>> vehiclesByAssignment;
  final Map<String, List<Map<String, dynamic>>> nominationsByAssignment;
  final Map<String, List<LoItineraryItem>> itineraryByAssignment;
  final Map<String, List<ConnectingFlightDraft>> arrivalConnectingByAssignment;
  final Map<String, List<ConnectingFlightDraft>>
      departureConnectingByAssignment;
  final List<LoIssueReport> issues;
  final int alertLeadMinutes;
  final int pendingSyncCount;
  final String? errorMessage;
  final String? infoMessage;
  final List<int>? lastDownloadBytes;
  final String? lastDownloadFilename;

  const LoPortalState({
    this.status = LoPortalStatus.initial,
    this.profile,
    this.delegates = const [],
    this.tasks = const [],
    this.alerts = const [],
    this.experiences = const [],
    this.languages = const [],
    this.vehiclesByAssignment = const {},
    this.nominationsByAssignment = const {},
    this.itineraryByAssignment = const {},
    this.arrivalConnectingByAssignment = const {},
    this.departureConnectingByAssignment = const {},
    this.issues = const [],
    this.alertLeadMinutes = 60,
    this.pendingSyncCount = 0,
    this.errorMessage,
    this.infoMessage,
    this.lastDownloadBytes,
    this.lastDownloadFilename,
  });

  LoPortalState copyWith({
    LoPortalStatus? status,
    LiaisonOfficerDto? profile,
    List<MyLoAssignmentDto>? delegates,
    List<LoTaskDto>? tasks,
    List<Map<String, dynamic>>? alerts,
    List<LoExperienceDto>? experiences,
    List<String>? languages,
    Map<String, List<Map<String, dynamic>>>? vehiclesByAssignment,
    Map<String, List<Map<String, dynamic>>>? nominationsByAssignment,
    Map<String, List<LoItineraryItem>>? itineraryByAssignment,
    Map<String, List<ConnectingFlightDraft>>? arrivalConnectingByAssignment,
    Map<String, List<ConnectingFlightDraft>>? departureConnectingByAssignment,
    List<LoIssueReport>? issues,
    int? alertLeadMinutes,
    int? pendingSyncCount,
    String? errorMessage,
    String? infoMessage,
    List<int>? lastDownloadBytes,
    String? lastDownloadFilename,
    bool clearError = false,
    bool clearInfo = false,
    bool clearDownload = false,
  }) {
    return LoPortalState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      delegates: delegates ?? this.delegates,
      tasks: tasks ?? this.tasks,
      alerts: alerts ?? this.alerts,
      experiences: experiences ?? this.experiences,
      languages: languages ?? this.languages,
      vehiclesByAssignment:
          vehiclesByAssignment ?? this.vehiclesByAssignment,
      nominationsByAssignment:
          nominationsByAssignment ?? this.nominationsByAssignment,
      itineraryByAssignment:
          itineraryByAssignment ?? this.itineraryByAssignment,
      arrivalConnectingByAssignment: arrivalConnectingByAssignment ??
          this.arrivalConnectingByAssignment,
      departureConnectingByAssignment: departureConnectingByAssignment ??
          this.departureConnectingByAssignment,
      issues: issues ?? this.issues,
      alertLeadMinutes: alertLeadMinutes ?? this.alertLeadMinutes,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      lastDownloadBytes: clearDownload
          ? null
          : (lastDownloadBytes ?? this.lastDownloadBytes),
      lastDownloadFilename: clearDownload
          ? null
          : (lastDownloadFilename ?? this.lastDownloadFilename),
    );
  }
}
