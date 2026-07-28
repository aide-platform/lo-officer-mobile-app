part of 'lo_bloc.dart';

abstract class LoEvent {}

class LoLoadRequested extends LoEvent {
  final String email;
  LoLoadRequested(this.email);
}

class LoDutyStatusToggled extends LoEvent {}

class LoVipAdded extends LoEvent {
  final VIP vip;
  LoVipAdded(this.vip);
}

class LoVipUpdated extends LoEvent {
  final VIP vip;
  LoVipUpdated(this.vip);
}

class LoVipDeleted extends LoEvent {
  final String vipName;
  LoVipDeleted(this.vipName);
}

class LoTaskStatusChanged extends LoEvent {
  final String vipName;
  final int taskIndex;
  final TaskStatus newStatus;
  LoTaskStatusChanged(this.vipName, this.taskIndex, this.newStatus);
}

class LoSearchQueryChanged extends LoEvent {
  final String query;
  LoSearchQueryChanged(this.query);
}

class LoFilterChanged extends LoEvent {
  final String filter;
  LoFilterChanged(this.filter);
}

// ✅ Persistence events
class LoVIPListSaveRequested extends LoEvent {}

class LoVIPListLoadRequested extends LoEvent {}
