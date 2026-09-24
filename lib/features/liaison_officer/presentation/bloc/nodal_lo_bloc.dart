import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';

part 'nodal_lo_event.dart';
part 'nodal_lo_state.dart';

class NodalLoBloc extends Bloc<NodalLoEvent, NodalLoState> {
  NodalLoBloc({required this.repository}) : super(const NodalLoState()) {
    on<NodalLoLoadRequested>(_onLoad);
    on<NodalLoClearMessages>(_onClearMessages);

    on<NodalLoCreateOrgType>(_onCreateOrgType);
    on<NodalLoUpdateOrgType>(_onUpdateOrgType);
    on<NodalLoSetOrgTypeActive>(_onSetOrgTypeActive);

    on<NodalLoCreateOrganisation>(_onCreateOrg);
    on<NodalLoUpdateOrganisation>(_onUpdateOrg);
    on<NodalLoDeleteOrganisation>(_onDeleteOrganisation);

    on<NodalLoCreateEmailTemplate>(_onCreateEmail);
    on<NodalLoUpdateEmailTemplate>(_onUpdateEmail);
    on<NodalLoDeleteEmailTemplate>(_onDeleteEmail);

    on<NodalLoCreateActivity>(_onCreateActivity);
    on<NodalLoUpdateActivity>(_onUpdateActivity);
    on<NodalLoSetActivityActive>(_onSetActivityActive);

    on<NodalLoCreateDoTemplate>(_onCreateDoTemplate);
    on<NodalLoUpdateDoTemplate>(_onUpdateDoTemplate);
    on<NodalLoDeleteDoTemplate>(_onDeleteDoTemplate);
    on<NodalLoDownloadDoTemplate>(_onDownloadDoTemplate);

    on<NodalLoRefreshOrgStatuses>(_onRefreshOrgStatuses);
    on<NodalLoDownloadOrgDo>(_onDownloadOrgDo);
    on<NodalLoUploadSignedDo>(_onUploadSignedDo);
    on<NodalLoSendNomination>(_onSendNomination);
    on<NodalLoSendNominationBulk>(_onSendNominationBulk);

    on<NodalLoSetLoFilters>(_onSetLoFilters);
    on<NodalLoLoadLoDetail>(_onLoadLoDetail);
    on<NodalLoClearLoDetail>(_onClearLoDetail);
    on<NodalLoSendLoReminder>(_onSendLoReminder);
    on<NodalLoSendPendingLoReminders>(_onSendPendingLoReminders);
    on<NodalLoSetLiaisonActive>(_onSetLiaisonActive);
    on<NodalLoCreateLiaisonOfficer>(_onCreateLiaisonOfficer);
    on<NodalLoUpdateLiaisonOfficer>(_onUpdateLiaisonOfficer);
    on<NodalLoDeleteLiaisonOfficer>(_onDeleteLiaisonOfficer);

    on<NodalLoToggleLoSelection>(_onToggleLoSelection);
    on<NodalLoClearLoSelection>(_onClearLoSelection);
    on<NodalLoAssignBadge>(_onAssignBadge);
    on<NodalLoDownloadBadge>(_onDownloadBadge);

    on<NodalLoCreateAssignment>(_onCreateAssignment);
    on<NodalLoDeleteAssignment>(_onDeleteAssignment);
    on<NodalLoCreateTask>(_onCreateTask);
    on<NodalLoUpdateTask>(_onUpdateTask);
    on<NodalLoDeleteTask>(_onDeleteTask);
    on<NodalLoSetTaskFilters>(_onSetTaskFilters);
    on<NodalLoCreateSubNodal>(_onCreateSub);
    on<NodalLoUpdateSubNodal>(_onUpdateSub);
    on<NodalLoDeleteSubNodal>(_onDeleteSub);
  }

  final NodalLoRepository repository;

  Future<Map<String, Map<String, dynamic>>> _loadOrgStatuses(
    List<LoOrganisationDto> orgs,
  ) async {
    final map = <String, Map<String, dynamic>>{};
    for (final o in orgs) {
      final id = o.id;
      if (id == null) continue;
      map[id] = await repository.orgDoLetterStatus(id);
    }
    return map;
  }

  void _fail(Emitter<NodalLoState> emit, Object e) {
    emit(state.copyWith(
      status: NodalLoStatus.failure,
      errorMessage: e.toString(),
      clearInfo: true,
    ));
  }

  Future<void> _onLoad(
    NodalLoLoadRequested event,
    Emitter<NodalLoState> emit,
  ) async {
    emit(state.copyWith(
      status: NodalLoStatus.loading,
      clearError: true,
      clearInfo: true,
    ));
    try {
      final orgTypes = await repository.listOrgTypes();
      final orgs = await repository.listOrganisations();
      final emails = await repository.listEmailTemplates();
      final activities = await repository.listActivities();
      final los = await repository.listLiaisonOfficers();
      final assignments = await repository.listAssignments();
      final tasks = await repository.listTasks();
      final doLetters = await repository.listDoLetterTemplates();
      final quota = await repository.getBadgeQuota();
      final delegates = await repository.listAssignableDelegates();
      final statuses = await _loadOrgStatuses(orgs);
      final subs = await repository.listSubNodals();
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgTypes: orgTypes,
        organisations: orgs,
        emailTemplates: emails,
        activities: activities,
        liaisonOfficers: los,
        assignments: assignments,
        tasks: tasks,
        doLetterTemplates: doLetters,
        badgeQuota: quota,
        assignableDelegates: delegates,
        orgStatuses: statuses,
        subNodals: subs,
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  void _onClearMessages(
    NodalLoClearMessages event,
    Emitter<NodalLoState> emit,
  ) {
    emit(state.copyWith(
      clearError: true,
      clearInfo: true,
      clearDownload: true,
    ));
  }

  Future<void> _onCreateOrgType(
    NodalLoCreateOrgType event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createOrgType(event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgTypes: [...state.orgTypes, item],
        infoMessage: 'Organisation type created.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateOrgType(
    NodalLoUpdateOrgType event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.updateOrgType(event.id, event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgTypes: [
          for (final t in state.orgTypes) t.id == event.id ? item : t,
        ],
        infoMessage: 'Organisation type updated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onSetOrgTypeActive(
    NodalLoSetOrgTypeActive event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.setOrgTypeActive(event.id, event.active);
      final refreshed = await repository.listOrgTypes();
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgTypes: refreshed,
        infoMessage: event.active ? 'Type activated.' : 'Type deactivated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateOrg(
    NodalLoCreateOrganisation event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createOrganisation(event.body);
      final orgs = [...state.organisations, item];
      final statuses = Map<String, Map<String, dynamic>>.from(state.orgStatuses);
      if (item.id != null) {
        statuses[item.id!] = await repository.orgDoLetterStatus(item.id!);
      }
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        organisations: orgs,
        orgStatuses: statuses,
        infoMessage: 'Organisation created.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateOrg(
    NodalLoUpdateOrganisation event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item =
          await repository.updateOrganisation(event.id, event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        organisations: [
          for (final o in state.organisations)
            o.id == event.id ? item : o,
        ],
        infoMessage: 'Organisation updated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteOrganisation(
    NodalLoDeleteOrganisation event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteOrganisation(event.id);
      final statuses = Map<String, Map<String, dynamic>>.from(state.orgStatuses)
        ..remove(event.id);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        organisations: [
          for (final o in state.organisations)
            if (o.id != event.id) o,
        ],
        orgStatuses: statuses,
        infoMessage: 'Organisation deleted.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateEmail(
    NodalLoCreateEmailTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createEmailTemplate(event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        emailTemplates: [...state.emailTemplates, item],
        infoMessage: 'Email template created.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateEmail(
    NodalLoUpdateEmailTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item =
          await repository.updateEmailTemplate(event.id, event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        emailTemplates: [
          for (final e in state.emailTemplates)
            e.id == event.id ? item : e,
        ],
        infoMessage: 'Email template updated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteEmail(
    NodalLoDeleteEmailTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteEmailTemplate(event.id);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        emailTemplates:
            state.emailTemplates.where((e) => e.id != event.id).toList(),
        infoMessage: 'Email template deleted.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateActivity(
    NodalLoCreateActivity event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createActivity(event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        activities: [...state.activities, item],
        infoMessage: 'Activity created.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateActivity(
    NodalLoUpdateActivity event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.updateActivity(event.id, event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        activities: [
          for (final a in state.activities)
            a.id == event.id ? item : a,
        ],
        infoMessage: 'Activity updated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onSetActivityActive(
    NodalLoSetActivityActive event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.setActivityActive(event.id, event.active);
      final refreshed = await repository.listActivities();
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        activities: refreshed,
        infoMessage:
            event.active ? 'Activity activated.' : 'Activity deactivated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateDoTemplate(
    NodalLoCreateDoTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createDoLetterTemplate(
        payload: event.payload,
        fileBytes: event.fileBytes,
        filename: event.filename,
      );
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        doLetterTemplates: [...state.doLetterTemplates, item],
        infoMessage: 'DO letter template created.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateDoTemplate(
    NodalLoUpdateDoTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.updateDoLetterTemplate(
        event.id,
        payload: event.payload,
        fileBytes: event.fileBytes,
        filename: event.filename,
      );
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        doLetterTemplates: [
          for (final t in state.doLetterTemplates)
            t.id == event.id ? item : t,
        ],
        infoMessage: 'DO letter template updated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteDoTemplate(
    NodalLoDeleteDoTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteDoLetterTemplate(event.id);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        doLetterTemplates:
            state.doLetterTemplates.where((t) => t.id != event.id).toList(),
        infoMessage: 'DO letter template deleted.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDownloadDoTemplate(
    NodalLoDownloadDoTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final bytes = await repository.downloadDoLetterTemplateFile(event.id);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        lastDownloadBytes: bytes,
        lastDownloadFilename: event.filename ?? 'do-template-${event.id}.pdf',
        infoMessage: 'DO template ready to share.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onRefreshOrgStatuses(
    NodalLoRefreshOrgStatuses event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final statuses = await _loadOrgStatuses(state.organisations);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgStatuses: statuses,
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDownloadOrgDo(
    NodalLoDownloadOrgDo event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final bytes = await repository.downloadOrgDoLetter(event.orgId);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        lastDownloadBytes: bytes,
        lastDownloadFilename:
            event.filename ?? 'do-letter-${event.orgId}.pdf',
        infoMessage: bytes.isEmpty
            ? 'No DO letter file available.'
            : 'DO letter ready to share.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUploadSignedDo(
    NodalLoUploadSignedDo event,
    Emitter<NodalLoState> emit,
  ) async {
    final incomplete =
        event.checklist.entries.where((e) => !e.value).map((e) => e.key);
    if (incomplete.isNotEmpty) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage:
            'Confirm all checklist items before uploading signed DO.',
      ));
      return;
    }
    try {
      await repository.uploadSignedDoLetter(
        orgId: event.orgId,
        bytes: event.bytes,
        filename: event.filename,
        signingAuthority: event.signingAuthority,
        checklist: event.checklist,
      );
      final statuses = Map<String, Map<String, dynamic>>.from(state.orgStatuses);
      statuses[event.orgId] =
          await repository.orgDoLetterStatus(event.orgId);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgStatuses: statuses,
        infoMessage: 'Signed DO letter uploaded.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onSendNomination(
    NodalLoSendNomination event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.sendNominationEmail(
        orgId: event.orgId,
        emailTemplateId: event.emailTemplateId,
        attachments: event.attachments,
      );
      final statuses = Map<String, Map<String, dynamic>>.from(state.orgStatuses);
      statuses[event.orgId] =
          await repository.orgDoLetterStatus(event.orgId);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgStatuses: statuses,
        infoMessage: 'Nomination email sent.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onSendNominationBulk(
    NodalLoSendNominationBulk event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.sendNominationEmailBulk(
        orgIds: event.orgIds,
        emailTemplateId: event.emailTemplateId,
      );
      final statuses = await _loadOrgStatuses(state.organisations);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        orgStatuses: statuses,
        infoMessage:
            'Nomination email sent to ${event.orgIds.length} organisation(s).',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  void _onSetLoFilters(
    NodalLoSetLoFilters event,
    Emitter<NodalLoState> emit,
  ) {
    emit(state.copyWith(
      filterOrgName: event.orgName,
      filterOrgTypeName: event.orgTypeName,
      filterProfileStatus: event.profileStatus,
      filterLanguage: event.language,
      filterAvailability: event.availability,
      clearFilterOrgName: event.clearOrgName,
      clearFilterOrgTypeName: event.clearOrgTypeName,
      clearFilterProfileStatus: event.clearProfileStatus,
      clearFilterLanguage: event.clearLanguage,
      clearFilterAvailability: event.clearAvailability,
    ));
  }

  Future<void> _onLoadLoDetail(
    NodalLoLoadLoDetail event,
    Emitter<NodalLoState> emit,
  ) async {
    emit(state.copyWith(
      detailLoading: true,
      clearDetailLo: true,
      detailExperiences: const [],
      detailLanguages: const [],
      clearError: true,
    ));
    try {
      final lo = await repository.getLiaisonOfficer(event.loId);
      final experiences = await repository.getLoExperiences(event.loId);
      final languages = await repository.getLoLanguages(event.loId);
      LiaisonOfficerDto? resolved = lo;
      if (resolved == null) {
        for (final existing in state.liaisonOfficers) {
          if (existing.id == event.loId) {
            resolved = existing;
            break;
          }
        }
      }
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        detailLo: resolved,
        detailExperiences: experiences,
        detailLanguages: languages,
        detailLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(detailLoading: false));
      _fail(emit, e);
    }
  }

  void _onClearLoDetail(
    NodalLoClearLoDetail event,
    Emitter<NodalLoState> emit,
  ) {
    emit(state.copyWith(
      clearDetailLo: true,
      detailExperiences: const [],
      detailLanguages: const [],
      detailLoading: false,
    ));
  }

  Future<void> _onSendLoReminder(
    NodalLoSendLoReminder event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.sendLoReminder(event.loId);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        infoMessage: 'Reminder sent.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onSendPendingLoReminders(
    NodalLoSendPendingLoReminders event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.sendPendingLoReminders();
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        infoMessage: 'Reminders sent to incomplete LO profiles.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onSetLiaisonActive(
    NodalLoSetLiaisonActive event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.setLiaisonOfficerActive(event.loId, event.active);
      final los = await repository.listLiaisonOfficers();
      LiaisonOfficerDto? detail = state.detailLo;
      if (detail?.id == event.loId) {
        for (final lo in los) {
          if (lo.id == event.loId) {
            detail = lo;
            break;
          }
        }
      }
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        liaisonOfficers: los,
        detailLo: detail,
        infoMessage: event.active ? 'LO activated.' : 'LO deactivated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateLiaisonOfficer(
    NodalLoCreateLiaisonOfficer event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createLiaisonOfficer(event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        liaisonOfficers: [...state.liaisonOfficers, item],
        infoMessage: 'Liaison Officer added.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateLiaisonOfficer(
    NodalLoUpdateLiaisonOfficer event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item =
          await repository.updateLiaisonOfficer(event.id, event.body);
      LiaisonOfficerDto? detail = state.detailLo;
      if (detail?.id == event.id) detail = item;
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        liaisonOfficers: [
          for (final lo in state.liaisonOfficers)
            lo.id == event.id ? item : lo,
        ],
        detailLo: detail,
        infoMessage: 'Liaison Officer updated.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteLiaisonOfficer(
    NodalLoDeleteLiaisonOfficer event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteLiaisonOfficer(event.id);
      final clearDetail = state.detailLo?.id == event.id;
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        liaisonOfficers: [
          for (final lo in state.liaisonOfficers)
            if (lo.id != event.id) lo,
        ],
        clearDetailLo: clearDetail,
        selectedLoIds: Set<String>.from(state.selectedLoIds)..remove(event.id),
        infoMessage: 'Liaison Officer removed.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  void _onToggleLoSelection(
    NodalLoToggleLoSelection event,
    Emitter<NodalLoState> emit,
  ) {
    final next = Set<String>.from(state.selectedLoIds);
    if (next.contains(event.loId)) {
      next.remove(event.loId);
    } else {
      next.add(event.loId);
    }
    emit(state.copyWith(selectedLoIds: next));
  }

  void _onClearLoSelection(
    NodalLoClearLoSelection event,
    Emitter<NodalLoState> emit,
  ) {
    emit(state.copyWith(selectedLoIds: const {}));
  }

  Future<void> _onAssignBadge(
    NodalLoAssignBadge event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final personIds = event.personIds ??
          state.liaisonOfficers
              .where((lo) =>
                  lo.id != null && state.selectedLoIds.contains(lo.id))
              .map((lo) => lo.personId)
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toList();

      if (personIds.isEmpty) {
        emit(state.copyWith(
          status: NodalLoStatus.failure,
          errorMessage:
              'Select LOs with personId before assigning badges.',
        ));
        return;
      }
      if (personIds.length > state.badgeRemaining) {
        emit(state.copyWith(
          status: NodalLoStatus.failure,
          errorMessage:
              'Badge quota exceeded. Remaining: ${state.badgeRemaining}.',
        ));
        return;
      }

      await repository.assignBadge({
        'personIds': personIds,
        if (event.badgeCatId != null) 'badgeCatId': event.badgeCatId,
      });
      final quota = await repository.getBadgeQuota();
      final los = await repository.listLiaisonOfficers();

      await MockEmailNotifier.send(
        to: 'nodal_officer@aeroindia.test',
        subject: 'Badges assigned',
        body: 'Badges assigned to ${personIds.length} LO(s).',
      );

      emit(state.copyWith(
        status: NodalLoStatus.ready,
        badgeQuota: quota,
        liaisonOfficers: los,
        selectedLoIds: const {},
        infoMessage: 'Badges assigned to ${personIds.length} LO(s).',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDownloadBadge(
    NodalLoDownloadBadge event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final bytes = await repository.downloadBadge(event.passId);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        lastDownloadBytes: bytes,
        lastDownloadFilename:
            event.filename ?? 'badge-${event.passId}.pdf',
        infoMessage: 'Badge ready to share.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateAssignment(
    NodalLoCreateAssignment event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createAssignment(event.body);
      await MockEmailNotifier.send(
        to: 'liaison@test.com',
        subject: 'New LO assignment',
        body:
            'You have been assigned to ${item.delegateName ?? 'a delegate'}.',
      );
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        assignments: [...state.assignments, item],
        infoMessage: 'LO assigned to delegate.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteAssignment(
    NodalLoDeleteAssignment event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteAssignment(event.id);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        assignments:
            state.assignments.where((a) => a.id != event.id).toList(),
        infoMessage: 'Assignment removed.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onCreateTask(
    NodalLoCreateTask event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createTask(event.body);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        tasks: [...state.tasks, item],
        infoMessage: 'Task created.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateTask(
    NodalLoUpdateTask event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.updateTask(event.id, event.body);
      await MockEmailNotifier.send(
        to: 'lo@example.com',
        subject: 'LO task updated',
        body: item.taskTitle ?? 'Task updated',
      );
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        tasks: [
          for (final t in state.tasks) t.id == event.id ? item : t,
        ],
        infoMessage: 'Task updated (notification queued).',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteTask(
    NodalLoDeleteTask event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteTask(event.id);
      emit(state.copyWith(
        status: NodalLoStatus.ready,
        tasks: [
          for (final t in state.tasks)
            if (t.id != event.id) t,
        ],
        infoMessage: 'Task deleted.',
        clearError: true,
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  void _onSetTaskFilters(
    NodalLoSetTaskFilters event,
    Emitter<NodalLoState> emit,
  ) {
    emit(state.copyWith(
      filterTaskLoId: event.loId,
      filterTaskDelegate: event.delegateName,
      filterTaskSource: event.taskSource,
      filterTaskStatus: event.status,
      filterTaskDate: event.date,
      clearFilterTaskLoId: event.clearLoId,
      clearFilterTaskDelegate: event.clearDelegateName,
      clearFilterTaskSource: event.clearTaskSource,
      clearFilterTaskStatus: event.clearStatus,
      clearFilterTaskDate: event.clearDate,
    ));
  }

  Future<void> _onCreateSub(
    NodalLoCreateSubNodal event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.createSubNodal(event.body);
      emit(state.copyWith(
        subNodals: [...state.subNodals, item],
        infoMessage: 'Sub nodal officer added',
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onUpdateSub(
    NodalLoUpdateSubNodal event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await repository.updateSubNodal(event.id, event.body);
      emit(state.copyWith(
        subNodals: [
          for (final s in state.subNodals) s.id == event.id ? item : s,
        ],
        infoMessage: 'Sub nodal officer updated',
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }

  Future<void> _onDeleteSub(
    NodalLoDeleteSubNodal event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await repository.deleteSubNodal(event.id);
      emit(state.copyWith(
        subNodals: state.subNodals.where((s) => s.id != event.id).toList(),
        infoMessage: 'Sub nodal officer removed',
      ));
    } catch (e) {
      _fail(emit, e);
    }
  }
}
