import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/core/services/push_notification_service.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_portal_cache.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'lo_portal_event.dart';
part 'lo_portal_state.dart';

class LoPortalBloc extends Bloc<LoPortalEvent, LoPortalState> {
  LoPortalBloc({required this.repository}) : super(const LoPortalState()) {
    on<LoPortalLoadRequested>(_onLoad);
    on<LoPortalProfileSaved>(_onSaveProfile);
    on<LoPortalTaskStatusUpdated>(_onTaskStatus);
    on<LoPortalTravelUpdated>(_onTravel);
    on<LoPortalMovementUpdated>(_onMovement);
    on<LoPortalIssueReported>(_onIssueReported);
    on<LoPortalIssueRetryRequested>(_onIssueRetry);
    on<LoPortalIssuesRefreshRequested>(_onIssuesRefresh);
    on<LoPortalPendingSyncRefreshRequested>(_onPendingSyncRefresh);
    on<LoPortalAlertsRefreshRequested>(_onAlerts);
    on<LoPortalUploadRequested>(_onUpload);
    on<LoPortalExperienceAdded>(_onExpAdd);
    on<LoPortalExperienceDeleted>(_onExpDel);
    on<LoPortalExperienceReplaced>(_onExpReplace);
    on<LoPortalLanguagesSaved>(_onLangs);
    on<LoPortalLanguageLookupsRequested>(_onLanguageLookups);
    on<LoPortalDelegateExtrasRequested>(_onExtras);
    on<LoPortalAlertLeadMinutesChanged>(_onLead);
    on<LoPortalBadgeDownloadRequested>(_onBadgeDownload);
    on<LoPortalDocumentFetchRequested>(_onDocumentFetch);
    on<LoPortalLocalFileShareRequested>(_onLocalFileShare);
    on<LoPortalClearDocumentPreview>(_onClearDocumentPreview);
    on<LoPortalClearMessages>(_onClearMessages);
  }

  final LoPortalRepository repository;

  Future<int> _refreshPendingCount() => LoOfflineStore.pendingSyncCount();

  /// 404 and an empty list hide the card. A network error keeps the last cache.
  Future<List<LoHelplineDto>> _loadHelplines(List<LoHelplineDto> cached) async {
    try {
      final helplines = await repository.getHelplines();
      await LoOfflineStore.cacheHelplines(helplines);
      return helplines;
    } catch (_) {
      return cached;
    }
  }

  Future<void> _onLoad(
    LoPortalLoadRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LoPortalStatus.loading,
        clearError: true,
        clearProfileSaveAck: true,
        clearDocumentPreview: true,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final lead = prefs.getInt('lo_alert_lead_minutes') ?? 60;

    final cachedProfile = await LoPortalCache.loadProfile();
    final cachedDelegates = await LoPortalCache.loadDelegates();
    final cachedTasks = await LoPortalCache.loadTasks();
    final alerts = await LoPortalCache.loadAlerts();
    final cachedIssues = await LoOfflineStore.listIssues();
    final cachedHelplines = await LoOfflineStore.loadHelplines();
    final pending = await _refreshPendingCount();
    if (cachedProfile != null ||
        cachedDelegates.isNotEmpty ||
        cachedTasks.isNotEmpty ||
        cachedHelplines.isNotEmpty) {
      emit(
        state.copyWith(
          status: LoPortalStatus.loading,
          profile: cachedProfile,
          delegates: cachedDelegates,
          tasks: cachedTasks,
          alerts: alerts,
          issues: cachedIssues,
          helplines: cachedHelplines,
          alertLeadMinutes: lead,
          pendingSyncCount: pending,
        ),
      );
    }

    try {
      await _flushOfflineQueue();
      final profile = await repository.getMyProfile();
      final delegates = await repository.getMyDelegates();
      final tasks = await repository.getMyTasks();
      final experiences = await repository.listExperiences();
      final languages = _preferLanguages(
        _dedupeLanguages(await repository.listLanguages()),
        state.languages,
      );
      final issues = await repository.listReportedIssues();
      await LoPortalCache.saveProfile(profile);
      await LoPortalCache.saveDelegates(delegates);
      await LoPortalCache.saveTasks(tasks);
      await LoOfflineStore.cacheDelegates(delegates);
      await LoOfflineStore.cacheTasks(tasks);
      final helplines = await _loadHelplines(cachedHelplines);

      for (final t in tasks) {
        if (t.scheduledDate != null &&
            (t.statusCode == null ||
                t.statusCode == 'PENDING' ||
                t.statusCode == 'IN_PROGRESS')) {
          await LoPortalCache.pushAlert(
            title: 'Upcoming task',
            body:
                '${t.taskTitle ?? 'Task'} for ${t.delegateName ?? 'delegate'} '
                        'on ${LoDisplayFormat.dateAndTime(t.scheduledDate, t.scheduledTime)} '
                        '(alert ${lead}m before)'
                    .trim(),
          );
        }
      }
      final refreshedAlerts = await LoPortalCache.loadAlerts();
      await PushNotificationService.instance.scheduleTaskLeadReminders(
        tasks: tasks,
        leadMinutes: lead,
      );

      emit(
        state.copyWith(
          status: LoPortalStatus.ready,
          profile: profile,
          delegates: delegates,
          tasks: tasks,
          experiences: experiences,
          languages: languages,
          issues: issues,
          helplines: helplines,
          alerts: refreshedAlerts,
          alertLeadMinutes: lead,
          pendingSyncCount: await _refreshPendingCount(),
          clearError: true,
          clearInfo: true,
        ),
      );
    } catch (e) {
      if (cachedProfile != null ||
          cachedDelegates.isNotEmpty ||
          cachedTasks.isNotEmpty) {
        emit(
          state.copyWith(
            status: LoPortalStatus.ready,
            errorMessage:
                'Offline — showing cached data. ${apiErrorMessage(e)}',
            issues: cachedIssues,
            helplines: cachedHelplines,
            alertLeadMinutes: lead,
            pendingSyncCount: await _refreshPendingCount(),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
    }
  }

  Future<void> _flushOfflineQueue() async {
    final queue = await LoOfflineStore.peekQueue();
    if (queue.isNotEmpty) {
      final remaining = <Map<String, dynamic>>[];
      for (final item in queue) {
        final taskId = item['taskId']?.toString();
        final statusCode = item['statusCode']?.toString();
        if (taskId == null || statusCode == null) continue;
        try {
          await repository.updateTaskStatus(
            taskId: taskId,
            statusCode: statusCode,
            remarks: item['remarks']?.toString(),
          );
        } catch (_) {
          remaining.add(item);
        }
      }
      await LoOfflineStore.replaceQueue(remaining);
    }

    final movements = await LoOfflineStore.peekMovementQueue();
    if (movements.isNotEmpty) {
      final remaining = <Map<String, dynamic>>[];
      for (final item in movements) {
        final assignmentId = item['assignmentId']?.toString();
        final bodyRaw = item['body'];
        if (assignmentId == null || bodyRaw is! Map) {
          continue;
        }
        try {
          final body = Map<String, dynamic>.from(bodyRaw);
          await repository.updateTravel(assignmentId: assignmentId, body: body);
          await repository.updateArrivalFlight(
            assignmentId: assignmentId,
            body: body,
          );
        } catch (_) {
          remaining.add(item);
        }
      }
      await LoOfflineStore.replaceMovementQueue(remaining);
    }

    final pendingIssues = await LoOfflineStore.listPendingIssues();
    for (final issue in pendingIssues) {
      try {
        await repository.reportIssue(issue);
      } catch (_) {
        // Left unsynced in Hive for next flush / manual retry.
      }
    }
  }

  Future<void> _onSaveProfile(
    LoPortalProfileSaved event,
    Emitter<LoPortalState> emit,
  ) async {
    emit(state.copyWith(status: LoPortalStatus.saving, clearError: true));
    try {
      final profile = await repository.updateMyProfile(event.body);
      await LoPortalCache.saveProfile(profile);
      await LoPortalCache.pushAlert(
        title: 'Profile submitted',
        body:
            'Your LO profile status is ${profile.profileStatus ?? 'SUBMITTED'}.',
      );
      // Refresh languages / experiences / documents from CAP after submit.
      final languages = _preferLanguages(
        _dedupeLanguages(await repository.listLanguages()),
        state.languages,
      );
      final experiences = await repository.listExperiences();
      final alerts = await LoPortalCache.loadAlerts();
      emit(
        state.copyWith(
          status: LoPortalStatus.ready,
          profile: profile,
          languages: languages,
          experiences: experiences,
          alerts: alerts,
          clearError: true,
          clearInfo: true,
          profileSaveAck: true,
        ),
      );
      LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureProfileSave);
      // Full portal reload so shell gate + delegates stay in sync.
      add(LoPortalLoadRequested());
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onTaskStatus(
    LoPortalTaskStatusUpdated event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final updated = await repository.updateTaskStatus(
        taskId: event.taskId,
        statusCode: event.statusCode,
        remarks: event.remarks,
      );
      final tasks = state.tasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList();
      await LoPortalCache.saveTasks(tasks);
      await LoPortalCache.pushAlert(
        title: 'Task status updated',
        body: '${updated.taskTitle ?? 'Task'} → ${updated.statusCode}',
      );
      emit(
        state.copyWith(
          tasks: tasks,
          alerts: await LoPortalCache.loadAlerts(),
          status: LoPortalStatus.ready,
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
      LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureTaskStatus);
    } catch (e) {
      await LoOfflineStore.enqueueTaskStatus(
        taskId: event.taskId,
        statusCode: event.statusCode,
        remarks: event.remarks,
      );
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage:
              'Offline — status queued for sync: ${apiErrorMessage(e)}',
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
    }
  }

  Future<void> _onTravel(
    LoPortalTravelUpdated event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      var updated = await repository.updateTravel(
        assignmentId: event.assignmentId,
        body: event.body,
      );
      updated = await repository.updateArrivalFlight(
        assignmentId: event.assignmentId,
        body: event.body,
      );
      final delegates = state.delegates
          .map((d) => d.assignmentId == updated.assignmentId ? updated : d)
          .toList();
      await LoPortalCache.saveDelegates(delegates);
      await LoPortalCache.pushAlert(
        title: 'Travel details updated',
        body: 'Travel updated for ${updated.fullName ?? 'delegate'}.',
      );
      final arrivalConnecting = <String, List<ConnectingFlightDraft>>{
        ...state.arrivalConnectingByAssignment,
      };
      final departureConnecting = <String, List<ConnectingFlightDraft>>{
        ...state.departureConnectingByAssignment,
      };
      final arrivalRaw = event.body['arrivalConnectingFlights'];
      if (arrivalRaw is List) {
        arrivalConnecting[event.assignmentId] = arrivalRaw
            .whereType<Map>()
            .map(
              (e) =>
                  ConnectingFlightDraft.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
      final departureRaw = event.body['departureConnectingFlights'];
      if (departureRaw is List) {
        departureConnecting[event.assignmentId] = departureRaw
            .whereType<Map>()
            .map(
              (e) =>
                  ConnectingFlightDraft.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
      emit(
        state.copyWith(
          delegates: delegates,
          arrivalConnectingByAssignment: arrivalConnecting,
          departureConnectingByAssignment: departureConnecting,
          alerts: await LoPortalCache.loadAlerts(),
          status: LoPortalStatus.ready,
        ),
      );
      LoFirebaseMonitor.instance.logFeature(
        LoMonitoringEvents.featureTravelUpdate,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onMovement(
    LoPortalMovementUpdated event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final updated = await repository.updateMovement(
        assignmentId: event.assignmentId,
        movement: event.movement,
      );
      final delegates = state.delegates
          .map((d) => d.assignmentId == updated.assignmentId ? updated : d)
          .toList();
      await LoPortalCache.saveDelegates(delegates);
      await LoPortalCache.pushAlert(
        title: 'Movement updated',
        body:
            '${event.movement.kind.label} logged for ${updated.fullName ?? 'delegate'}.',
      );
      emit(
        state.copyWith(
          delegates: delegates,
          alerts: await LoPortalCache.loadAlerts(),
          status: LoPortalStatus.ready,
          infoMessage: '${event.movement.kind.label} status saved.',
          clearError: true,
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
      LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureMovement);
    } catch (e) {
      await LoOfflineStore.enqueueMovement(
        assignmentId: event.assignmentId,
        body: event.movement.toTravelBody(),
      );
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage:
              'Offline — movement queued for sync: ${apiErrorMessage(e)}',
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
    }
  }

  Future<void> _onIssueReported(
    LoPortalIssueReported event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final saved = await repository.reportIssue(event.issue);
      final issues = await repository.listReportedIssues();
      final submitted = saved.synced;
      await LoPortalCache.pushAlert(
        title: submitted ? 'Issue submitted' : 'Issue queued offline',
        body: submitted
            ? '${saved.title} was submitted.'
            : '${saved.title} — queued for sync. Share to escalate now if needed.',
      );
      emit(
        state.copyWith(
          issues: issues,
          alerts: await LoPortalCache.loadAlerts(),
          status: LoPortalStatus.ready,
          infoMessage: submitted
              ? 'Issue submitted successfully.'
              : 'Issue saved on device and queued for sync when online.',
          clearError: true,
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
      LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureIssueReport);
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
    }
  }

  Future<void> _onIssueRetry(
    LoPortalIssueRetryRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    LoIssueReport? target;
    for (final i in state.issues) {
      if (i.id == event.issueId) {
        target = i;
        break;
      }
    }
    if (target == null || target.synced) return;
    try {
      final saved = await repository.reportIssue(target);
      final issues = await repository.listReportedIssues();
      emit(
        state.copyWith(
          issues: issues,
          status: LoPortalStatus.ready,
          infoMessage: saved.synced
              ? 'Issue synced.'
              : 'Still offline — will retry on next load.',
          clearError: true,
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: 'Sync failed: ${apiErrorMessage(e)}',
          pendingSyncCount: await _refreshPendingCount(),
        ),
      );
    }
  }

  Future<void> _onIssuesRefresh(
    LoPortalIssuesRefreshRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    final issues = await repository.listReportedIssues();
    emit(
      state.copyWith(
        issues: issues,
        pendingSyncCount: await _refreshPendingCount(),
      ),
    );
  }

  Future<void> _onPendingSyncRefresh(
    LoPortalPendingSyncRefreshRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    emit(state.copyWith(pendingSyncCount: await _refreshPendingCount()));
  }

  Future<void> _onAlerts(
    LoPortalAlertsRefreshRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    emit(state.copyWith(alerts: await LoPortalCache.loadAlerts()));
  }

  Future<void> _onUpload(
    LoPortalUploadRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      switch (event.kind) {
        case LoUploadKind.photo:
          await repository.uploadPhoto(event.bytes, event.filename);
        case LoUploadKind.signature:
          await repository.uploadSignature(event.bytes, event.filename);
        case LoUploadKind.orgBadgeFront:
          await repository.uploadOrgBadgeFront(event.bytes, event.filename);
        case LoUploadKind.orgBadgeBack:
          await repository.uploadOrgBadgeBack(event.bytes, event.filename);
        case LoUploadKind.aadhaarFront:
          await repository.uploadAadhaarFront(event.bytes, event.filename);
        case LoUploadKind.aadhaarBack:
          await repository.uploadAadhaarBack(event.bytes, event.filename);
      }
      await LoPortalCache.pushAlert(
        title: 'Upload complete',
        body: event.filename,
      );
      final profile = await repository.getMyProfile();
      if (profile != null) {
        await LoPortalCache.saveProfile(profile);
      }
      emit(
        state.copyWith(
          profile: profile,
          alerts: await LoPortalCache.loadAlerts(),
          status: LoPortalStatus.ready,
          clearError: true,
        ),
      );
      LoFirebaseMonitor.instance.logFeature(
        LoMonitoringEvents.featureDocumentUpload,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onExpAdd(
    LoPortalExperienceAdded event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final exp = await repository.addExperience(event.body);
      emit(
        state.copyWith(
          experiences: [...state.experiences, exp],
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onExpReplace(
    LoPortalExperienceReplaced event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      await repository.deleteExperience(event.id);
      final exp = await repository.addExperience(event.body);
      emit(
        state.copyWith(
          experiences: [
            for (final row in state.experiences)
              if (row.id != event.id) row,
            exp,
          ],
          clearError: true,
        ),
      );
    } catch (e) {
      List<LoExperienceDto> experiences = state.experiences;
      try {
        experiences = await repository.listExperiences();
      } catch (_) {}
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
          experiences: experiences,
        ),
      );
    }
  }

  Future<void> _onExpDel(
    LoPortalExperienceDeleted event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      await repository.deleteExperience(event.id);
      emit(
        state.copyWith(
          experiences: state.experiences
              .where((e) => e.id != event.id)
              .toList(),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onLanguageLookups(
    LoPortalLanguageLookupsRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    if (state.languageOptions.isNotEmpty) return;
    try {
      final options = await repository.listLanguageLookups();
      emit(state.copyWith(languageOptions: options));
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onLangs(
    LoPortalLanguagesSaved event,
    Emitter<LoPortalState> emit,
  ) async {
    final requested = LoPortalBloc._dedupeLanguages(event.languages);
    try {
      await repository.setLanguages(requested);
      final fetched = LoPortalBloc._dedupeLanguages(
        await repository.listLanguages(),
      );
      emit(
        state.copyWith(
          languages: _preferLanguages(fetched, requested),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
          languages: requested,
        ),
      );
    }
  }

  Future<void> _onExtras(
    LoPortalDelegateExtrasRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    final vehicles = await repository.getVehicles(event.assignmentId);
    final nominations = await repository.getNominations(event.assignmentId);
    MyLoAssignmentDto? assignment;
    for (final d in state.delegates) {
      if (d.assignmentId == event.assignmentId) {
        assignment = d;
        break;
      }
    }
    final itinerary = LoItineraryItem.compose(
      assignment:
          assignment ?? MyLoAssignmentDto(assignmentId: event.assignmentId),
      nominations: nominations,
      vehicles: vehicles,
    );
    emit(
      state.copyWith(
        vehiclesByAssignment: {
          ...state.vehiclesByAssignment,
          event.assignmentId: vehicles,
        },
        nominationsByAssignment: {
          ...state.nominationsByAssignment,
          event.assignmentId: nominations,
        },
        itineraryByAssignment: {
          ...state.itineraryByAssignment,
          event.assignmentId: itinerary,
        },
      ),
    );
  }

  Future<void> _onLead(
    LoPortalAlertLeadMinutesChanged event,
    Emitter<LoPortalState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lo_alert_lead_minutes', event.minutes);
    emit(state.copyWith(alertLeadMinutes: event.minutes));
    await PushNotificationService.instance.scheduleTaskLeadReminders(
      tasks: state.tasks,
      leadMinutes: event.minutes,
    );
  }

  Future<void> _onBadgeDownload(
    LoPortalBadgeDownloadRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final bytes = await repository.downloadBadge(event.passId);
      emit(
        state.copyWith(
          status: LoPortalStatus.ready,
          lastDownloadBytes: bytes,
          lastDownloadFilename: event.filename ?? 'badge-${event.passId}.pdf',
          infoMessage: 'Badge ready to share.',
          clearError: true,
        ),
      );
      LoFirebaseMonitor.instance.logFeature(
        LoMonitoringEvents.featureBadgeDownload,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onDocumentFetch(
    LoPortalDocumentFetchRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final bytes = await repository.downloadProfileFile(event.fileId);
      if (event.share) {
        emit(
          state.copyWith(
            status: LoPortalStatus.ready,
            lastDownloadBytes: bytes,
            lastDownloadFilename: event.filename,
            clearError: true,
            clearInfo: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: LoPortalStatus.ready,
          documentPreviewBytes: bytes,
          documentPreviewName: event.filename,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: apiErrorMessage(e),
        ),
      );
    }
  }

  void _onLocalFileShare(
    LoPortalLocalFileShareRequested event,
    Emitter<LoPortalState> emit,
  ) {
    emit(
      state.copyWith(
        status: LoPortalStatus.ready,
        lastDownloadBytes: event.bytes,
        lastDownloadFilename: event.filename,
        clearError: true,
        clearInfo: true,
      ),
    );
  }

  void _onClearDocumentPreview(
    LoPortalClearDocumentPreview event,
    Emitter<LoPortalState> emit,
  ) {
    emit(state.copyWith(clearDocumentPreview: true));
  }

  void _onClearMessages(
    LoPortalClearMessages event,
    Emitter<LoPortalState> emit,
  ) {
    emit(
      state.copyWith(clearInfo: true, clearError: true, clearDownload: true),
    );
  }

  static List<String> _preferLanguages(
    List<String> fetched,
    List<String> local,
  ) {
    if (fetched.isEmpty) return local;
    final fetchedKeys = fetched.map((e) => e.toLowerCase()).toSet();
    final extras = local.where(
      (e) => !fetchedKeys.contains(e.toLowerCase()),
    );
    if (extras.isEmpty) return fetched;
    return _dedupeLanguages([...fetched, ...extras]);
  }

  static List<String> _dedupeLanguages(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final lang in raw) {
      final t = lang.trim();
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(t);
    }
    return out;
  }
}

enum LoUploadKind {
  photo,
  signature,
  orgBadgeFront,
  orgBadgeBack,
  aadhaarFront,
  aadhaarBack,
}
