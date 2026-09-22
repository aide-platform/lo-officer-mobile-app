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
  final List<DoLetterTemplateDto> doLetterTemplates;
  final Map<String, Map<String, dynamic>> orgStatuses;
  final Map<String, dynamic>? badgeQuota;
  final List<Map<String, dynamic>> assignableDelegates;
  final Set<String> selectedLoIds;
  final String? filterOrgName;
  final String? filterOrgTypeName;
  final String? filterProfileStatus;
  final String? filterLanguage;
  final String? filterAvailability;
  final String? filterTaskLoId;
  final String? filterTaskDelegate;
  final String? filterTaskSource;
  final String? filterTaskStatus;
  final String? filterTaskDate;
  final List<OrgSubNodalOfficerDto> subNodals;
  final LiaisonOfficerDto? detailLo;
  final List<LoExperienceDto> detailExperiences;
  final List<String> detailLanguages;
  final bool detailLoading;
  final List<int>? lastDownloadBytes;
  final String? lastDownloadFilename;
  final String? errorMessage;
  final String? infoMessage;

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
    this.orgStatuses = const {},
    this.badgeQuota,
    this.assignableDelegates = const [],
    this.selectedLoIds = const {},
    this.filterOrgName,
    this.filterOrgTypeName,
    this.filterProfileStatus,
    this.filterLanguage,
    this.filterAvailability,
    this.filterTaskLoId,
    this.filterTaskDelegate,
    this.filterTaskSource,
    this.filterTaskStatus,
    this.filterTaskDate,
    this.subNodals = const [],
    this.detailLo,
    this.detailExperiences = const [],
    this.detailLanguages = const [],
    this.detailLoading = false,
    this.lastDownloadBytes,
    this.lastDownloadFilename,
    this.errorMessage,
    this.infoMessage,
  });

  int get badgeRemaining {
    final q = badgeQuota;
    if (q == null) return 0;
    final rem = q['remaining'] ?? q['remainingQuota'] ?? q['available'];
    if (rem is num) return rem.toInt();
    return int.tryParse(rem?.toString() ?? '') ?? 0;
  }

  List<LiaisonOfficerDto> get filteredLiaisonOfficers {
    return liaisonOfficers.where((lo) {
      final orgQ = filterOrgName?.trim().toLowerCase();
      if (orgQ != null && orgQ.isNotEmpty) {
        if (!(lo.orgName ?? '').toLowerCase().contains(orgQ)) return false;
      }
      final typeQ = filterOrgTypeName?.trim().toLowerCase();
      if (typeQ != null && typeQ.isNotEmpty) {
        if (!(lo.orgTypeName ?? '').toLowerCase().contains(typeQ)) return false;
      }
      final statusQ = filterProfileStatus?.trim();
      if (statusQ != null && statusQ.isNotEmpty) {
        if ((lo.profileStatus ?? '') != statusQ) return false;
      }
      final langQ = filterLanguage?.trim().toLowerCase();
      if (langQ != null && langQ.isNotEmpty) {
        final langs = lo.languages.map((e) => e.toLowerCase()).toList();
        if (!langs.any((l) => l.contains(langQ))) return false;
      }
      final availQ = filterAvailability?.trim().toLowerCase();
      if (availQ != null && availQ.isNotEmpty) {
        if (!(lo.availabilityStatus ?? '').toLowerCase().contains(availQ)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<LoTaskDto> get filteredTasks {
    return tasks.where((t) {
      if (filterTaskLoId != null && filterTaskLoId!.isNotEmpty) {
        if (t.loId != filterTaskLoId) return false;
      }
      final delQ = filterTaskDelegate?.trim().toLowerCase();
      if (delQ != null && delQ.isNotEmpty) {
        if (!(t.delegateName ?? '').toLowerCase().contains(delQ)) return false;
      }
      if (filterTaskSource != null && filterTaskSource!.isNotEmpty) {
        if ((t.taskSource ?? '') != filterTaskSource) return false;
      }
      if (filterTaskStatus != null && filterTaskStatus!.isNotEmpty) {
        final code = t.statusCode ?? '';
        final name = t.statusName ?? '';
        if (code != filterTaskStatus && name != filterTaskStatus) return false;
      }
      final dateQ = filterTaskDate?.trim();
      if (dateQ != null && dateQ.isNotEmpty) {
        if ((t.scheduledDate ?? '') != dateQ) return false;
      }
      return true;
    }).toList();
  }

  NodalLoState copyWith({
    NodalLoStatus? status,
    List<LoOrgTypeDto>? orgTypes,
    List<LoOrganisationDto>? organisations,
    List<EmailTemplateDto>? emailTemplates,
    List<LoActivityDto>? activities,
    List<LiaisonOfficerDto>? liaisonOfficers,
    List<LoAssignmentDto>? assignments,
    List<LoTaskDto>? tasks,
    List<DoLetterTemplateDto>? doLetterTemplates,
    Map<String, Map<String, dynamic>>? orgStatuses,
    Map<String, dynamic>? badgeQuota,
    List<Map<String, dynamic>>? assignableDelegates,
    Set<String>? selectedLoIds,
    String? filterOrgName,
    String? filterOrgTypeName,
    String? filterProfileStatus,
    String? filterLanguage,
    String? filterAvailability,
    String? filterTaskLoId,
    String? filterTaskDelegate,
    String? filterTaskSource,
    String? filterTaskStatus,
    String? filterTaskDate,
    List<OrgSubNodalOfficerDto>? subNodals,
    LiaisonOfficerDto? detailLo,
    List<LoExperienceDto>? detailExperiences,
    List<String>? detailLanguages,
    bool? detailLoading,
    List<int>? lastDownloadBytes,
    String? lastDownloadFilename,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
    bool clearDownload = false,
    bool clearDetailLo = false,
    bool clearFilterOrgName = false,
    bool clearFilterOrgTypeName = false,
    bool clearFilterProfileStatus = false,
    bool clearFilterLanguage = false,
    bool clearFilterAvailability = false,
    bool clearFilterTaskLoId = false,
    bool clearFilterTaskDelegate = false,
    bool clearFilterTaskSource = false,
    bool clearFilterTaskStatus = false,
    bool clearFilterTaskDate = false,
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
      orgStatuses: orgStatuses ?? this.orgStatuses,
      badgeQuota: badgeQuota ?? this.badgeQuota,
      assignableDelegates: assignableDelegates ?? this.assignableDelegates,
      selectedLoIds: selectedLoIds ?? this.selectedLoIds,
      filterOrgName:
          clearFilterOrgName ? null : (filterOrgName ?? this.filterOrgName),
      filterOrgTypeName: clearFilterOrgTypeName
          ? null
          : (filterOrgTypeName ?? this.filterOrgTypeName),
      filterProfileStatus: clearFilterProfileStatus
          ? null
          : (filterProfileStatus ?? this.filterProfileStatus),
      filterLanguage: clearFilterLanguage
          ? null
          : (filterLanguage ?? this.filterLanguage),
      filterAvailability: clearFilterAvailability
          ? null
          : (filterAvailability ?? this.filterAvailability),
      filterTaskLoId:
          clearFilterTaskLoId ? null : (filterTaskLoId ?? this.filterTaskLoId),
      filterTaskDelegate: clearFilterTaskDelegate
          ? null
          : (filterTaskDelegate ?? this.filterTaskDelegate),
      filterTaskSource: clearFilterTaskSource
          ? null
          : (filterTaskSource ?? this.filterTaskSource),
      filterTaskStatus: clearFilterTaskStatus
          ? null
          : (filterTaskStatus ?? this.filterTaskStatus),
      filterTaskDate:
          clearFilterTaskDate ? null : (filterTaskDate ?? this.filterTaskDate),
      subNodals: subNodals ?? this.subNodals,
      detailLo: clearDetailLo ? null : (detailLo ?? this.detailLo),
      detailExperiences: detailExperiences ?? this.detailExperiences,
      detailLanguages: detailLanguages ?? this.detailLanguages,
      detailLoading: detailLoading ?? this.detailLoading,
      lastDownloadBytes: clearDownload
          ? null
          : (lastDownloadBytes ?? this.lastDownloadBytes),
      lastDownloadFilename: clearDownload
          ? null
          : (lastDownloadFilename ?? this.lastDownloadFilename),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
