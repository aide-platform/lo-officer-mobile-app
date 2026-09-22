import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/org_rep_repository.dart';

part 'org_rep_event.dart';
part 'org_rep_state.dart';

class OrgRepBloc extends Bloc<OrgRepEvent, OrgRepState> {
  OrgRepBloc({required OrgRepRepository repository})
      : _repository = repository,
        super(const OrgRepState()) {
    on<OrgRepLoadRequested>(_onLoad);
    on<OrgRepNominateRequested>(_onNominate);
    on<OrgRepReminderRequested>(_onReminder);
    on<OrgRepBulkReminderRequested>(_onBulkReminder);
    on<OrgRepImportTemplateRequested>(_onImportTemplate);
    on<OrgRepBulkImportRequested>(_onBulkImport);
  }

  final OrgRepRepository _repository;

  Future<void> _onLoad(
    OrgRepLoadRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    emit(state.copyWith(status: OrgRepStatus.loading, clearError: true));
    try {
      final org = await _repository.getMyOrganisation();
      final los = await _repository.listLos();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        organisation: org,
        los: los,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onNominate(
    OrgRepNominateRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      final lo = await _repository.nominateLo(event.body);
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        los: [...state.los, lo],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReminder(
    OrgRepReminderRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      await _repository.sendReminder(event.loId);
      emit(state.copyWith(status: OrgRepStatus.ready));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onBulkReminder(
    OrgRepBulkReminderRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      await _repository.sendPendingReminders();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        infoMessage: 'Reminders sent to incomplete profiles.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onImportTemplate(
    OrgRepImportTemplateRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      final bytes = await _repository.downloadImportTemplate();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        infoMessage:
            'Import template ready (${bytes.length} bytes). Save/share from device in production.',
        lastTemplateBytes: bytes,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onBulkImport(
    OrgRepBulkImportRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      await _repository.bulkImport(event.bytes, event.filename);
      final los = await _repository.listLos();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        los: los,
        infoMessage: 'Bulk import completed.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
