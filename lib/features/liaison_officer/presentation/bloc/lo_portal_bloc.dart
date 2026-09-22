import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_portal_cache.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';

part 'lo_portal_event.dart';
part 'lo_portal_state.dart';

class LoPortalBloc extends Bloc<LoPortalEvent, LoPortalState> {
  LoPortalBloc({required LoPortalRepository repository})
      : _repository = repository,
        super(const LoPortalState()) {
    on<LoPortalLoadRequested>(_onLoad);
    on<LoPortalProfileSaved>(_onSaveProfile);
    on<LoPortalTaskStatusUpdated>(_onTaskStatus);
    on<LoPortalTravelUpdated>(_onTravel);
    on<LoPortalAlertsRefreshRequested>(_onAlerts);
  }

  final LoPortalRepository _repository;

  Future<void> _onLoad(
    LoPortalLoadRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    emit(state.copyWith(status: LoPortalStatus.loading, clearError: true));

    final cachedProfile = await LoPortalCache.loadProfile();
    final cachedDelegates = await LoPortalCache.loadDelegates();
    final cachedTasks = await LoPortalCache.loadTasks();
    final alerts = await LoPortalCache.loadAlerts();
    if (cachedProfile != null ||
        cachedDelegates.isNotEmpty ||
        cachedTasks.isNotEmpty) {
      emit(state.copyWith(
        status: LoPortalStatus.loading,
        profile: cachedProfile,
        delegates: cachedDelegates,
        tasks: cachedTasks,
        alerts: alerts,
      ));
    }

    try {
      final profile = await _repository.getMyProfile();
      final delegates = await _repository.getMyDelegates();
      final tasks = await _repository.getMyTasks();
      await LoPortalCache.saveProfile(profile);
      await LoPortalCache.saveDelegates(delegates);
      await LoPortalCache.saveTasks(tasks);

      for (final t in tasks) {
        if (t.scheduledDate != null &&
            (t.statusCode == null ||
                t.statusCode == 'PENDING' ||
                t.statusCode == 'IN_PROGRESS')) {
          await LoPortalCache.pushAlert(
            title: 'Upcoming task',
            body:
                '${t.taskTitle ?? 'Task'} for ${t.delegateName ?? 'delegate'} '
                'on ${t.scheduledDate} ${t.scheduledTime ?? ''}'.trim(),
          );
        }
      }
      final refreshedAlerts = await LoPortalCache.loadAlerts();

      emit(state.copyWith(
        status: LoPortalStatus.ready,
        profile: profile,
        delegates: delegates,
        tasks: tasks,
        alerts: refreshedAlerts,
      ));
    } catch (e) {
      if (cachedProfile != null ||
          cachedDelegates.isNotEmpty ||
          cachedTasks.isNotEmpty) {
        emit(state.copyWith(
          status: LoPortalStatus.ready,
          errorMessage: 'Showing cached data. $e',
        ));
        return;
      }
      emit(state.copyWith(
        status: LoPortalStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSaveProfile(
    LoPortalProfileSaved event,
    Emitter<LoPortalState> emit,
  ) async {
    emit(state.copyWith(status: LoPortalStatus.saving, clearError: true));
    try {
      final profile = await _repository.updateMyProfile(event.body);
      await LoPortalCache.saveProfile(profile);
      await LoPortalCache.pushAlert(
        title: 'Profile updated',
        body: 'Your LO profile was submitted/updated.',
      );
      final alerts = await LoPortalCache.loadAlerts();
      emit(state.copyWith(
        status: LoPortalStatus.ready,
        profile: profile,
        alerts: alerts,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoPortalStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTaskStatus(
    LoPortalTaskStatusUpdated event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final updated = await _repository.updateTaskStatus(
        taskId: event.taskId,
        statusCode: event.statusCode,
        remarks: event.remarks,
      );
      final tasks =
          state.tasks.map((t) => t.id == updated.id ? updated : t).toList();
      await LoPortalCache.saveTasks(tasks);
      await LoPortalCache.pushAlert(
        title: 'Task status updated',
        body: '${updated.taskTitle ?? 'Task'} → ${updated.statusCode}',
      );
      final alerts = await LoPortalCache.loadAlerts();
      emit(state.copyWith(
        tasks: tasks,
        alerts: alerts,
        status: LoPortalStatus.ready,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoPortalStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTravel(
    LoPortalTravelUpdated event,
    Emitter<LoPortalState> emit,
  ) async {
    try {
      final updated = await _repository.updateTravel(
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
      final alerts = await LoPortalCache.loadAlerts();
      emit(state.copyWith(
        delegates: delegates,
        alerts: alerts,
        status: LoPortalStatus.ready,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoPortalStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAlerts(
    LoPortalAlertsRefreshRequested event,
    Emitter<LoPortalState> emit,
  ) async {
    final alerts = await LoPortalCache.loadAlerts();
    emit(state.copyWith(alerts: alerts));
  }
}
