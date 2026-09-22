import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';

part 'nodal_lo_event.dart';
part 'nodal_lo_state.dart';

class NodalLoBloc extends Bloc<NodalLoEvent, NodalLoState> {
  NodalLoBloc({required NodalLoRepository repository})
      : _repository = repository,
        super(const NodalLoState()) {
    on<NodalLoLoadRequested>(_onLoad);
    on<NodalLoCreateOrgType>(_onCreateOrgType);
    on<NodalLoCreateOrganisation>(_onCreateOrg);
    on<NodalLoCreateActivity>(_onCreateActivity);
    on<NodalLoCreateEmailTemplate>(_onCreateEmail);
    on<NodalLoCreateAssignment>(_onCreateAssignment);
    on<NodalLoCreateTask>(_onCreateTask);
    on<NodalLoAssignBadge>(_onAssignBadge);
    on<NodalLoDeleteAssignment>(_onDeleteAssignment);
  }

  final NodalLoRepository _repository;

  Future<void> _onLoad(
    NodalLoLoadRequested event,
    Emitter<NodalLoState> emit,
  ) async {
    emit(state.copyWith(status: NodalLoStatus.loading, clearError: true));
    try {
      final orgTypes = await _repository.listOrgTypes();
      final orgs = await _repository.listOrganisations();
      final emails = await _repository.listEmailTemplates();
      final activities = await _repository.listActivities();
      final los = await _repository.listLiaisonOfficers();
      final assignments = await _repository.listAssignments();
      final tasks = await _repository.listTasks();
      final doLetters = await _repository.listDoLetterTemplates();
      final quota = await _repository.getBadgeQuota();
      final delegates = await _repository.listAssignableDelegates();
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
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateOrgType(
    NodalLoCreateOrgType event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await _repository.createOrgType(event.body);
      emit(state.copyWith(orgTypes: [...state.orgTypes, item]));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateOrg(
    NodalLoCreateOrganisation event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await _repository.createOrganisation(event.body);
      emit(state.copyWith(organisations: [...state.organisations, item]));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateActivity(
    NodalLoCreateActivity event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await _repository.createActivity(event.body);
      emit(state.copyWith(activities: [...state.activities, item]));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateEmail(
    NodalLoCreateEmailTemplate event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await _repository.createEmailTemplate(event.body);
      emit(state.copyWith(emailTemplates: [...state.emailTemplates, item]));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateAssignment(
    NodalLoCreateAssignment event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await _repository.createAssignment(event.body);
      emit(state.copyWith(assignments: [...state.assignments, item]));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateTask(
    NodalLoCreateTask event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      final item = await _repository.createTask(event.body);
      emit(state.copyWith(tasks: [...state.tasks, item]));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssignBadge(
    NodalLoAssignBadge event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await _repository.assignBadge(event.body);
      final quota = await _repository.getBadgeQuota();
      emit(state.copyWith(badgeQuota: quota));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteAssignment(
    NodalLoDeleteAssignment event,
    Emitter<NodalLoState> emit,
  ) async {
    try {
      await _repository.deleteAssignment(event.id);
      emit(state.copyWith(
        assignments:
            state.assignments.where((a) => a.id != event.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NodalLoStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
