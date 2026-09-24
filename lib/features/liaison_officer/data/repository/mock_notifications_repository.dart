import 'package:liaison_officer/features/liaison_officer/domain/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  final List<Map<String, dynamic>> _items = [
    {
      'id': 'n-1',
      'title': 'Catering request approved',
      'message': 'Your catering request for VIP Lounge (Lunch) was approved.',
      'kind': 'CATERING',
      'link': '/catering',
      'isRead': false,
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 12))
          .toIso8601String(),
      'readAt': null,
    },
    {
      'id': 'n-2',
      'title': 'E-coupons distributed',
      'message': '5 e-coupons were assigned from your committee pool.',
      'kind': 'ECOUPON',
      'link': '/ecoupons',
      'isRead': false,
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'readAt': null,
    },
    {
      'id': 'n-3',
      'title': 'LO profile submitted',
      'message': 'Demo Liaison submitted a profile for review.',
      'kind': 'LO_PROFILE',
      'link': '/los',
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
