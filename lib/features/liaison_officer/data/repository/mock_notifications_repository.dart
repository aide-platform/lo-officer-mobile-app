import 'package:liaison_officer/features/liaison_officer/domain/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  final List<Map<String, dynamic>> _items = [
    {
      'id': 'n-1',
      'title': 'Task assigned',
      'message': 'Airport pickup assigned for Amb. Singh — check Tasks.',
      'kind': 'TASK',
      'link': '/tasks',
      'isRead': false,
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 12))
          .toIso8601String(),
      'readAt': null,
    },
    {
      'id': 'n-2',
      'title': 'Schedule update',
      'message': 'Delegate itinerary changed for VIP Lounge briefing.',
      'kind': 'SCHEDULE',
      'link': '/delegates',
      'isRead': false,
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'readAt': null,
    },
    {
      'id': 'n-3',
      'title': 'B2B meeting request',
      'message': 'A B2B meeting was requested for your assigned delegate.',
      'kind': 'B2B',
      'link': '/delegates',
      'isRead': true,
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 5))
          .toIso8601String(),
      'readAt': DateTime.now()
          .subtract(const Duration(hours: 4))
          .toIso8601String(),
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> listMine() async =>
      List<Map<String, dynamic>>.from(
        _items.map((e) => Map<String, dynamic>.from(e)),
      );

  @override
  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((e) => e['id']?.toString() == id);
    if (idx < 0) return;
    _items[idx] = {
      ..._items[idx],
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> markAllRead() async {
    final now = DateTime.now().toIso8601String();
    for (var i = 0; i < _items.length; i++) {
      if (_items[i]['isRead'] == true) continue;
      _items[i] = {..._items[i], 'isRead': true, 'readAt': now};
    }
  }

  @override
  Future<int> unreadCount() async =>
      _items.where((e) => e['isRead'] != true).length;
}
