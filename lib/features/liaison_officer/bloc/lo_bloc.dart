import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

import '../data/enum/taskStatus.dart';
import '../data/models/vip.dart';
import '../data/models/hotel.dart';
import '../data/models/transport.dart';
import '../data/models/engagement.dart';
import '../data/datasources/dummyData.dart';
import '../data/repository/lo_repository.dart';
import '../data/repository/mock_lo_repository.dart';
import '../../../core/storage/sqlite/app_sqlite_db.dart';

part 'lo_event.dart';
part 'lo_state.dart';

class LoBloc extends Bloc<LoEvent, LoBlocState> {
  LoBloc({LoRepository? repository})
      : _repository = repository ?? MockLoRepository(),
        super(const LoBlocState()) {
    on<LoLoadRequested>(_onLoad);
    on<LoDutyStatusToggled>(_onDutyToggled);
    on<LoVipAdded>(_onVipAdded);
    on<LoVipUpdated>(_onVipUpdated);
    on<LoVipDeleted>(_onVipDeleted);
    on<LoTaskStatusChanged>(_onTaskStatusChanged);
    on<LoSearchQueryChanged>(_onSearchChanged);
    on<LoFilterChanged>(_onFilterChanged);
    // ✅ Persistence handlers
    on<LoVIPListSaveRequested>(_onSaveVIPList);
    on<LoVIPListLoadRequested>(_onLoadVIPList);
  }

  final LoRepository _repository;

  Future<void> _onLoad(
      LoLoadRequested event, Emitter<LoBlocState> emit) async {
    emit(state.copyWith(status: LoStatus.loading, email: event.email));
    try {
      // Prefer locally persisted VIP list when present.
      final cached = await _readCachedVipList();
      if (cached != null && cached.isNotEmpty) {
        emit(state.copyWith(status: LoStatus.loaded, vipList: cached));
        return;
      }
      final vips = await _repository.fetchVips(email: event.email);
      emit(state.copyWith(status: LoStatus.loaded, vipList: vips));
      add(LoVIPListSaveRequested());
    } catch (e) {
      try {
        final vips = DummyData.vipList();
        emit(state.copyWith(status: LoStatus.loaded, vipList: vips));
      } catch (e2) {
        emit(state.copyWith(status: LoStatus.error, errorMessage: e2.toString()));
      }
    }
  }

  void _onDutyToggled(LoDutyStatusToggled event, Emitter<LoBlocState> emit) {
    emit(state.copyWith(onDuty: !state.onDuty));
  }

  void _onVipAdded(LoVipAdded event, Emitter<LoBlocState> emit) {
    final updatedList = [...state.vipList, event.vip];
    emit(state.copyWith(vipList: updatedList));
    // Auto-save after modification
    add(LoVIPListSaveRequested());
  }

  void _onVipUpdated(LoVipUpdated event, Emitter<LoBlocState> emit) {
    final updated = state.vipList.map((v) =>
        v.name == event.vip.name ? event.vip : v).toList();
    emit(state.copyWith(vipList: updated));
    // Auto-save after modification
    add(LoVIPListSaveRequested());
  }

  void _onVipDeleted(LoVipDeleted event, Emitter<LoBlocState> emit) {
    final updated = state.vipList.where((v) => v.name != event.vipName).toList();
    emit(state.copyWith(vipList: updated));
    // Auto-save after modification
    add(LoVIPListSaveRequested());
  }

  void _onSearchChanged(LoSearchQueryChanged event, Emitter<LoBlocState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onFilterChanged(LoFilterChanged event, Emitter<LoBlocState> emit) {
    emit(state.copyWith(filterCategory: event.filter));
  }

  // ✅ Persistence Methods
  Future<List<VIP>?> _readCachedVipList() async {
    try {
      final vipsJson = await AppSqliteDb.getSetting('lo_vip_list');
      if (vipsJson == null || vipsJson.isEmpty) return null;
      final decoded = jsonDecode(vipsJson);
      if (decoded is! List) return null;
      return decoded
          .map((e) => VIP.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _onSaveVIPList(
      LoVIPListSaveRequested event, Emitter<LoBlocState> emit) async {
    try {
      final vipsJson = jsonEncode(
        state.vipList.map((v) => v.toMap()).toList(),
      );
      await AppSqliteDb.upsertSetting('lo_vip_list', vipsJson);
      emit(state.copyWith(status: LoStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: LoStatus.error,
        errorMessage: 'Failed to save VIP list: $e',
      ));
    }
  }

  Future<void> _onLoadVIPList(
      LoVIPListLoadRequested event, Emitter<LoBlocState> emit) async {
    try {
      emit(state.copyWith(status: LoStatus.loading));
      final cached = await _readCachedVipList();
      if (cached != null && cached.isNotEmpty) {
        emit(state.copyWith(status: LoStatus.loaded, vipList: cached));
        return;
      }
      final vips = DummyData.vipList();
      emit(state.copyWith(status: LoStatus.loaded, vipList: vips));
    } catch (e) {
      emit(state.copyWith(
        status: LoStatus.error,
        errorMessage: 'Failed to load VIP list: $e',
      ));
    }
  }

  void _onTaskStatusChanged(LoTaskStatusChanged event, Emitter<LoBlocState> emit) {
    final updatedVips = state.vipList.map((v) {
      if (v.name == event.vipName) {
        if (event.taskIndex == 0) {
          final newTransport = Transport(
            carType: v.transport.carType,
            driverName: v.transport.driverName,
            driverContact: v.transport.driverContact,
            status: event.newStatus == TaskStatus.completed ? 'Completed' : (event.newStatus == TaskStatus.inProgress ? 'In Progress' : 'Pending'),
            flightNumber: v.transport.flightNumber,
            arrivalTime: v.transport.arrivalTime,
            arrivalTerminal: v.transport.arrivalTerminal,
            arrivalLocation: v.transport.arrivalLocation,
          );
          return v.copyWith(transport: newTransport);
        } else if (event.taskIndex == 1) {
          final newHotel = Hotel(
            name: v.hotel.name,
            roomNumber: event.newStatus == TaskStatus.pending
                ? ''
                : (v.hotel.roomNumber.isEmpty
                    ? '101'
                    : v.hotel.roomNumber),
            stayDuration: v.hotel.stayDuration,
          );
          return v.copyWith(hotel: newHotel);
        } else {
          final engIndex = event.taskIndex - 2;
          final updatedEngagements = List<Engagement>.from(v.engagements);
          if (engIndex >= 0 && engIndex < updatedEngagements.length) {
            final oldEng = updatedEngagements[engIndex];
            updatedEngagements[engIndex] = Engagement(
              eventName: oldEng.eventName,
              dateTime: oldEng.dateTime,
              rsvpStatus: event.newStatus == TaskStatus.completed ? 'Confirmed' : (event.newStatus == TaskStatus.inProgress ? 'In Progress' : 'Pending'),
              comments: oldEng.comments,
            );
          }
          return v.copyWith(engagements: updatedEngagements);
        }
      }
      return v;
    }).toList();

    emit(state.copyWith(vipList: updatedVips));
    // Auto-save after status modification
    add(LoVIPListSaveRequested());
  }
}
