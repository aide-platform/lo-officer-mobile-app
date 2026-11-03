import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
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

/// Pull-to-refresh: reload the portal and wait until it settles. Never hangs
/// the spinner: gives up after 45 s or when the bloc closes (logout).
Future<void> refreshPortal(BuildContext context) async {
  final bloc = context.read<LoPortalBloc>();
  if (bloc.isClosed) return;
  final done = bloc.stream
      .firstWhere(
        (s) =>
            s.status == LoPortalStatus.ready ||
            s.status == LoPortalStatus.failure,
      )
      .timeout(const Duration(seconds: 45));
  bloc.add(LoPortalLoadRequested());
  try {
    await done;
  } catch (_) {}
}

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
    on<LoPortalGenderLookupsRequested>(_onGenderLookups);
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

  /// Runs an optional call; on failure keeps [fallback] instead of failing the load.
  Future<T> _orElse<T>(Future<T> Function() call, T fallback) async {
    try {
      return await call();
    } catch (_) {
      return fallback;
    }
  }

  bool _loadInFlight = false;

  /// Handlers run concurrently, so "Sync now" + pull-to-refresh could flush
  /// the offline queue twice. A load already running answers both callers.
  Future<void> _onLoad(
    LoPortalLoadRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    try {
      await _load(emit);
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> _load(Emitter<LoPortalState> emit) async {
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

    // A corrupt or old-format cache must not leave the portal stuck loading.
    final cachedProfile = await _orElse<LiaisonOfficerDto?>(
      LoPortalCache.loadProfile,
      null,
    );
    final cachedDelegates = await _orElse(
      LoPortalCache.loadDelegates,
      const <MyLoAssignmentDto>[],
    );
    final cachedTasks = await _orElse(
      LoPortalCache.loadTasks,
      const <LoTaskDto>[],
    );
    final alerts = await _orElse(
      LoPortalCache.loadAlerts,
      const <Map<String, dynamic>>[],
    );
    final cachedIssues = await _orElse(
      LoOfflineStore.listIssues,
      const <LoIssueReport>[],
    );
    final cachedHelplines = await _orElse(
      LoOfflineStore.loadHelplines,
      const <LoHelplineDto>[],
    );
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
      // Profile extras are optional for the portal: a failure here must not
      // flip the whole screen to "offline" when delegates and tasks loaded.
      final experiences = await _orElse(
        repository.listExperiences,
        state.experiences,
      );
      final languages = _preferLanguages(
        _dedupeLanguages(
          await _orElse(repository.listLanguages, const <String>[]),
        ),
        state.languages,
      );
      final issues = await _orElse(repository.listReportedIssues, cachedIssues);
      // Logged out while loading: do not write this officer's data back.
      if (isClosed) return;
      final previousTaskIds = cachedTasks
          .map((t) => (t.id ?? '').trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      await LoPortalCache.saveProfile(profile);
      await LoPortalCache.saveDelegates(delegates);
      await LoPortalCache.saveTasks(tasks);
      await LoOfflineStore.cacheDelegates(delegates);
      await LoOfflineStore.cacheTasks(tasks);
      final helplines = await _loadHelplines(cachedHelplines);

      // One "new task" alert per task id — dedupeKey keeps it to a single row
      // across refreshes, and the previousTaskIds guard means a fresh install
      // does not stage an alert for every historical task on first load.
      if (previousTaskIds.isNotEmpty) {
        for (final t in tasks) {
          final id = (t.id ?? '').trim();
          if (id.isEmpty || previousTaskIds.contains(id)) continue;
          await LoPortalCache.pushAlert(
            dedupeKey: 'task-new:$id',
            title: 'New task assigned',
            body: t.taskScope == 'LO'
                ? (t.taskTitle ?? 'Task')
                : '${t.taskTitle ?? 'Task'} for ${t.delegateName ?? 'delegate'}'
                      .trim(),
          );
        }
      }

      for (final t in tasks) {
        if (t.scheduledDate != null &&
            (t.statusCode == null ||
                t.statusCode == 'PENDING' ||
                t.statusCode == 'IN_PROGRESS')) {
          final id = (t.id ?? '').trim();
          final key = id.isNotEmpty
              ? 'task-reminder:$id'
              : 'task-reminder:${t.taskTitle}:${t.scheduledDate}:${t.scheduledTime}';
          await LoPortalCache.pushAlert(
            dedupeKey: key,
            title: 'Upcoming task',
            body:
                '${t.taskTitle ?? 'Task'}'
                        '${t.taskScope == 'LO' ? '' : ' for ${t.delegateName ?? 'delegate'}'} '
                        'on ${LoDisplayFormat.dateAndTime(t.scheduledDate, t.scheduledTime)} '
                        '(alert ${lead}m before)'
                    .trim(),
          );
        }
      }
      await _syncBroadcastAlerts();
      final refreshedAlerts = await LoPortalCache.loadAlerts();
      // Reminders are a convenience; a plugin error must not turn a good
      // load into "offline".
      await _orElse<void>(
        () => PushNotificationService.instance.scheduleTaskLeadReminders(
          tasks: tasks,
          leadMinutes: lead,
        ),
        null,
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
        } catch (e) {
          // Keep only for network/server trouble. A 4xx (task removed,
          // already completed, not mine) will never succeed, so drop it.
          if (_isRetryable(e)) remaining.add(item);
        }
      }
      // Keep items queued while this flush was sending.
      final added = _addedSince(queue, await LoOfflineStore.peekQueue());
      await LoOfflineStore.replaceQueue([...remaining, ...added]);
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
        } catch (e) {
          if (_isRetryable(e)) remaining.add(item);
        }
      }
      final added = _addedSince(
        movements,
        await LoOfflineStore.peekMovementQueue(),
      );
      await LoOfflineStore.replaceMovementQueue([...remaining, ...added]);
    }

    // Issue reporting was removed from the app; drop what older builds saved.
    await LoOfflineStore.clearIssues();
  }

  /// Items in [now] that were not in the [sent] snapshot.
  static List<Map<String, dynamic>> _addedSince(
    List<Map<String, dynamic>> sent,
    List<Map<String, dynamic>> now,
  ) {
    String key(Map<String, dynamic> m) => jsonEncode(m);
    final seen = sent.map(key).toSet();
    return now.where((m) => !seen.contains(key(m))).toList();
  }

  /// True when a queued write failed for a reason that may pass later:
  /// no response (offline, timeout), 401 (session expired, sign in again),
  /// 408, 429 or 5xx.
  static bool _isRetryable(Object e) {
    int? status;
    if (e is DioException) {
      status = e.response?.statusCode;
      final inner = e.error;
      if (status == null && inner is ApiException) status = inner.statusCode;
      if (status == null) return true;
    } else if (e is ApiException) {
      status = e.statusCode;
      if (status == null) return false; // server answered success=false
    } else {
      return true;
    }
    return status == 401 || status == 408 || status == 429 || status >= 500;
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
      // The save already succeeded, so a failed refresh keeps current rows.
      final languages = _preferLanguages(
        _dedupeLanguages(
          await _orElse(repository.listLanguages, state.languages),
        ),
        state.languages,
      );
      final experiences = await _orElse(
        repository.listExperiences,
        state.experiences,
      );
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
      LoFirebaseMonitor.instance.logFeature(
        LoMonitoringEvents.featureProfileSave,
      );
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
    final LoTaskDto updated;
    try {
      updated = await repository.updateTaskStatus(
        taskId: event.taskId,
        statusCode: event.statusCode,
        remarks: event.remarks,
      );
    } catch (e) {
      // Queue only what can pass later; a rejection (task removed, not
      // mine, invalid status) is shown as is instead of "queued".
      if (!_isRetryable(e)) {
        emit(
          state.copyWith(
            status: LoPortalStatus.failure,
            errorMessage: apiErrorMessage(e),
          ),
        );
        return;
      }
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
      return;
    }
    try {
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
      LoFirebaseMonitor.instance.logFeature(
        LoMonitoringEvents.featureTaskStatus,
      );
    } catch (_) {
      // The server already has the new status; only the local cache or
      // alert write failed. Show the update anyway.
      emit(
        state.copyWith(
          tasks: state.tasks
              .map((t) => t.id == updated.id ? updated : t)
              .toList(),
          status: LoPortalStatus.ready,
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
      LoFirebaseMonitor.instance.logFeature(
        LoMonitoringEvents.featureIssueReport,
      );
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
    final issues = await _orElse(repository.listReportedIssues, state.issues);
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
    await _orElse<void>(_syncBroadcastAlerts, null);
    emit(
      state.copyWith(
        alerts: await _orElse(LoPortalCache.loadAlerts, state.alerts),
      ),
    );
  }

  /// Copies LO Committee broadcasts into local alerts, one row per message,
  /// so a push that was missed or dismissed still shows under Alerts.
  Future<void> _syncBroadcastAlerts() async {
    final broadcasts = await _orElse(
      repository.getMyBroadcasts,
      const <LoBroadcastDto>[],
    );
    for (final b in broadcasts) {
      await LoPortalCache.pushAlert(
        dedupeKey: 'broadcast:${b.id}',
        title: b.title.isEmpty ? 'LO Committee' : b.title,
        body: b.body,
        at: b.createdAt,
      );
    }
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
      // The upload succeeded; a failed refresh keeps the current profile.
      final profile = await _orElse(repository.getMyProfile, state.profile);
      if (profile != null) {
        await LoPortalCache.saveProfile(profile);
      }
      emit(
        state.copyWith(
          profile: profile,
          alerts: await _orElse(LoPortalCache.loadAlerts, state.alerts),
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
          errorMessage: 'Upload failed (${event.filename}): ${apiErrorMessage(e)}',
          failedUploadKind: event.kind,
          failedUploadSeq: state.failedUploadSeq + 1,
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
      // Add first: if it fails the original row is still there.
      final exp = await repository.addExperience(event.body);
      await repository.deleteExperience(event.id);
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

  Future<void> _onGenderLookups(
    LoPortalGenderLookupsRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    if (state.genderOptions.isNotEmpty) return;
    try {
      final options = await repository.listGenderLookups();
      emit(state.copyWith(genderOptions: options));
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
    // Offline: keep what was loaded before instead of an unhandled error.
    final vehicles = await _orElse(
      () => repository.getVehicles(event.assignmentId),
      state.vehiclesByAssignment[event.assignmentId] ??
          const <Map<String, dynamic>>[],
    );
    final nominations = await _orElse(
      () => repository.getNominations(event.assignmentId),
      state.nominationsByAssignment[event.assignmentId] ??
          const <Map<String, dynamic>>[],
    );
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
    try {
      await PushNotificationService.instance.scheduleTaskLeadReminders(
        tasks: state.tasks,
        leadMinutes: event.minutes,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoPortalStatus.failure,
          errorMessage: 'Could not schedule task reminders: $e',
        ),
      );
    }
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
          lastDownloadSaveToDevice: true,
          clearError: true,
          clearInfo: true,
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
    final extras = local.where((e) => !fetchedKeys.contains(e.toLowerCase()));
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
