import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/org_rep_repository.dart';

part 'org_rep_event.dart';
part 'org_rep_state.dart';

class OrgRepBloc extends Bloc<OrgRepEvent, OrgRepState> {
  OrgRepBloc({required this.repository}) : super(const OrgRepState()) {
    on<OrgRepLoadRequested>(_onLoad);
    on<OrgRepNominateRequested>(_onNominate);
    on<OrgRepReminderRequested>(_onReminder);
    on<OrgRepBulkReminderRequested>(_onBulkReminder);
    on<OrgRepImportTemplateRequested>(_onImportTemplate);
    on<OrgRepBulkImportRequested>(_onBulkImport);
    on<OrgRepSubNodalCreateRequested>(_onCreateSub);
    on<OrgRepSubNodalUpdateRequested>(_onUpdateSub);
    on<OrgRepSubNodalDeleteRequested>(_onDeleteSub);
    on<OrgRepLoadLoDetail>(_onLoadLoDetail);
    on<OrgRepBadgeDownloadRequested>(_onBadgeDownload);
    on<OrgRepClearMessages>(_onClearMessages);
  }

  final OrgRepRepository repository;

  Future<void> _onLoad(
    OrgRepLoadRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    emit(state.copyWith(status: OrgRepStatus.loading, clearError: true));
    try {
      final org = await repository.getMyOrganisation();
      final los = await repository.listLos();
      final subs = await repository.listSubNodals();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        organisation: org,
        los: los,
        subNodals: subs,
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
      final lo = await repository.nominateLo(event.body);
      final email = event.body['primaryEmail']?.toString().trim();
      if (email != null && email.isNotEmpty) {
        await MockEmailNotifier.send(
          to: email,
          subject: 'Complete your Liaison Officer profile',
          body:
              'You have been nominated as a Liaison Officer. '
              'Please sign in and complete your profile.',
        );
      }
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        los: [...state.los, lo],
        infoMessage: 'LO nominated. Profile completion email sent.',
        clearError: true,
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
      await repository.sendReminder(event.loId);
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        infoMessage: 'Reminder sent.',
        clearError: true,
      ));
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
      await repository.sendPendingReminders();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        infoMessage: 'Reminders sent to incomplete profiles.',
        clearError: true,
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
      final bytes = await repository.downloadImportTemplate();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        lastTemplateBytes: bytes,
        infoMessage: 'Import template ready (${bytes.length} bytes).',
        clearError: true,
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
      await repository.bulkImport(event.bytes, event.filename);
      final los = await repository.listLos();
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        los: los,
        infoMessage: 'Bulk import completed.',
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateSub(
    OrgRepSubNodalCreateRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      final item = await repository.createSubNodal(event.body);
      emit(state.copyWith(
        subNodals: [...state.subNodals, item],
        infoMessage: 'Sub nodal officer added.',
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSub(
    OrgRepSubNodalUpdateRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      final item = await repository.updateSubNodal(event.id, event.body);
      emit(state.copyWith(
        subNodals: state.subNodals
            .map((e) => e.id == item.id ? item : e)
            .toList(),
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteSub(
    OrgRepSubNodalDeleteRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      await repository.deleteSubNodal(event.id);
      emit(state.copyWith(
        subNodals: state.subNodals.where((e) => e.id != event.id).toList(),
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadLoDetail(
    OrgRepLoadLoDetail event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      final detail = await repository.getLo(event.loId);
      emit(state.copyWith(
        selectedLoDetail: detail,
        status: OrgRepStatus.ready,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onBadgeDownload(
    OrgRepBadgeDownloadRequested event,
    Emitter<OrgRepState> emit,
  ) async {
    try {
      final bytes = await repository.downloadBadge(event.passId);
      emit(state.copyWith(
        status: OrgRepStatus.ready,
        lastDownloadBytes: bytes,
        lastDownloadFilename:
            event.filename ?? 'badge-${event.passId}.pdf',
        infoMessage: 'Badge ready to share.',
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OrgRepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearMessages(
    OrgRepClearMessages event,
    Emitter<OrgRepState> emit,
  ) {
    emit(state.copyWith(
      clearInfo: true,
      clearError: true,
      clearDownload: true,
    ));
  }
}
