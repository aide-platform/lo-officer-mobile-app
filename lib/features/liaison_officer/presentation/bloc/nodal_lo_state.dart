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
    final parsed = int.tryParse(rem?.toString() ?? '');
    if (parsed != null) return parsed;
    final lines = q['badgeLines'];
    if (lines is List) {
      var sum = 0;
      for (final row in lines) {
        if (row is Map) {
          final a = row['available'] ?? row['remaining'];
          if (a is num) sum += a.toInt();
        }
      }
      return sum;
    }
    return 0;
  }

  /// Unique VIP person ids from assignments + assignable delegate roster.
  int get totalVips {
    final ids = <String>{};
    for (final d in assignableDelegates) {
      final id = d['personId']?.toString() ?? d['attendeeId']?.toString();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    for (final a in assignments) {
      if (a.personId != null && a.personId!.isNotEmpty) ids.add(a.personId!);
    }
    return ids.length;
  }

  int get vipsAssigned {
    final ids = <String>{};
    for (final a in assignments) {
      if (a.personId != null && a.personId!.isNotEmpty) ids.add(a.personId!);
    }
    return ids.length;
  }

  int get losWithVipAssignment {
    final ids = <String>{};
    for (final a in assignments) {
      if (a.loId != null && a.loId!.isNotEmpty) ids.add(a.loId!);
    }
    return ids.length;
  }

  int get losWithoutVipAssignment =>
      (liaisonOfficers.length - losWithVipAssignment).clamp(0, 1 << 30);

  int get completedTasks => tasks
      .where((t) => (t.statusCode ?? '').toUpperCase() == 'COMPLETED')
      .length;

  int get pendingTasksCount => tasks
      .where((t) => (t.statusCode ?? '').toUpperCase() == 'PENDING')
      .length;

  int get inProgressTasksCount => tasks
      .where((t) => (t.statusCode ?? '').toUpperCase() == 'IN_PROGRESS')
      .length;

  int get losWithPriorExperience =>
      liaisonOfficers.where((e) => e.hasPrevLoExp == true).length;

  int get activeLos =>
      liaisonOfficers.where((e) => e.isActive != false).length;

  Map<String, int> get orgsByTypeCount {
    final map = <String, int>{};
    for (final o in organisations) {
      final key = o.orgTypeName?.trim().isNotEmpty == true
          ? o.orgTypeName!
          : 'Other';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get loProfileStatusCounts {
    final map = <String, int>{};
    for (final lo in liaisonOfficers) {
      final key = (lo.profileStatus ?? 'UNKNOWN').trim();
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Distinct VIP personIds grouped by LO organisation name.
  List<MapEntry<String, int>> get orgWiseVipSummary {
    final byOrg = <String, Set<String>>{};
    for (final a in assignments) {
      if (a.personId == null || a.personId!.isEmpty) continue;
      var org = a.loOrgName?.trim();
      if (org == null || org.isEmpty) {
        for (final lo in liaisonOfficers) {
          if (lo.id == a.loId) {
            org = lo.orgName?.trim();
            break;
          }
        }
      }
      org = (org == null || org.isEmpty) ? 'Unknown org' : org;
      byOrg.putIfAbsent(org, () => <String>{}).add(a.personId!);
    }
    final list = byOrg.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  /// Per-organisation rollup: LOs, VIPs assigned, tasks (video Organisation-wise Details).
  List<({String name, String type, int los, int vips, int tasks, int completed})>
      get orgWiseDetails {
    final vipByOrg = <String, Set<String>>{};
    final loCountByOrg = <String, int>{};
    for (final lo in liaisonOfficers) {
      final key = lo.orgName?.trim().isNotEmpty == true
          ? lo.orgName!.trim()
          : 'Unknown org';
      loCountByOrg[key] = (loCountByOrg[key] ?? 0) + 1;
    }
    for (final a in assignments) {
      if (a.personId == null || a.personId!.isEmpty) continue;
      var org = a.loOrgName?.trim();
      if (org == null || org.isEmpty) {
        for (final lo in liaisonOfficers) {
          if (lo.id == a.loId) {
            org = lo.orgName?.trim();
            break;
          }
        }
      }
      org = (org == null || org.isEmpty) ? 'Unknown org' : org;
      vipByOrg.putIfAbsent(org, () => <String>{}).add(a.personId!);
    }
    final taskByOrg = <String, int>{};
    final completedByOrg = <String, int>{};
    for (final t in tasks) {
      String? org;
      for (final lo in liaisonOfficers) {
        if (lo.id == t.loId) {
          org = lo.orgName?.trim();
          break;
        }
      }
      final key = (org == null || org.isEmpty) ? 'Unknown org' : org;
      taskByOrg[key] = (taskByOrg[key] ?? 0) + 1;
      if ((t.statusCode ?? '').toUpperCase() == 'COMPLETED') {
        completedByOrg[key] = (completedByOrg[key] ?? 0) + 1;
      }
    }

    final names = <String>{
      ...organisations.map((o) => o.orgName),
      ...loCountByOrg.keys,
      ...vipByOrg.keys,
    };
    final rows = <({String name, String type, int los, int vips, int tasks, int completed})>[];
    for (final name in names) {
      LoOrganisationDto? match;
      for (final o in organisations) {
        if (o.orgName == name) {
          match = o;
          break;
        }
      }
      rows.add((
        name: name,
        type: match?.orgTypeName ?? '—',
        los: loCountByOrg[name] ?? match?.loCount ?? 0,
        vips: vipByOrg[name]?.length ?? 0,
        tasks: taskByOrg[name] ?? 0,
        completed: completedByOrg[name] ?? 0,
      ));
    }
    rows.sort((a, b) => b.vips.compareTo(a.vips));
    return rows;
  }

  /// Type-wise rollup: orgs, LOs, VIPs (video Organisation Type-wise Summary).
  List<({String type, int orgs, int los, int withVip, int withoutVip, int vips})>
      get typeWiseSummary {
    final orgsByType = <String, int>{};
    for (final o in organisations) {
      final t = o.orgTypeName?.trim().isNotEmpty == true
          ? o.orgTypeName!
          : 'Other';
      orgsByType[t] = (orgsByType[t] ?? 0) + 1;
    }
    final loByType = <String, List<LiaisonOfficerDto>>{};
    for (final lo in liaisonOfficers) {
      final t = lo.orgTypeName?.trim().isNotEmpty == true
          ? lo.orgTypeName!
          : 'Other';
      loByType.putIfAbsent(t, () => []).add(lo);
    }
    final vipLoIds = {
      for (final a in assignments)
        if (a.loId != null && a.loId!.isNotEmpty) a.loId!,
    };
    final vipByType = <String, Set<String>>{};
    for (final a in assignments) {
      if (a.personId == null || a.personId!.isEmpty) continue;
      String? type;
      for (final lo in liaisonOfficers) {
        if (lo.id == a.loId) {
          type = lo.orgTypeName?.trim();
          break;
        }
      }
      type = (type == null || type.isEmpty) ? 'Other' : type;
      vipByType.putIfAbsent(type, () => <String>{}).add(a.personId!);
    }
    final types = <String>{...orgsByType.keys, ...loByType.keys};
    final rows = <({String type, int orgs, int los, int withVip, int withoutVip, int vips})>[];
    for (final t in types) {
      final los = loByType[t] ?? const [];
      final withVip =
          los.where((lo) => lo.id != null && vipLoIds.contains(lo.id)).length;
      rows.add((
        type: t,
        orgs: orgsByType[t] ?? 0,
        los: los.length,
        withVip: withVip,
        withoutVip: (los.length - withVip).clamp(0, 1 << 30),
        vips: vipByType[t]?.length ?? 0,
      ));
    }
    rows.sort((a, b) => b.orgs.compareTo(a.orgs));
    return rows;
  }

  /// Delegate coverage: VIPs with ≥1 LO / total VIP roster.
  String get delegateCoverageLabel {
    final total = totalVips;
    final assigned = vipsAssigned;
    return '$assigned of $total VIP(s) have at least one LO assigned.';
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
