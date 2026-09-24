import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/domain/notifications_repository.dart';

class DioNotificationsRepository implements NotificationsRepository {
  DioNotificationsRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  @override
  Future<List<Map<String, dynamic>>> listMine() async {
    final res = await _dio.get(ApiConfig.notificationsMinePath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  @override
  Future<void> markRead(String id) async {
    await _dio.post(ApiConfig.notificationReadPath(id));
  }

  @override
  Future<void> markAllRead() async {
    await _dio.post(ApiConfig.notificationsReadAllPath);
  }

  @override
  Future<int> unreadCount() async {
    final res = await _dio.get(ApiConfig.notificationsUnreadCountPath);
    final aide = AideResponse.unwrap(res.data, parseData: _parseCount);
    return aide.data ?? 0;
  }

  static int _parseCount(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['count', 'unreadCount', 'unread', 'value']) {
        final v = map[key];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v != null) {
          final parsed = int.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
