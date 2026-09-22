import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/vip.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_repository.dart';

/// Tries Dio `/api/lo/vips`. Falls back to mock only when [ApiConfig.useMockApi].
class DioLoRepository implements LoRepository {
  DioLoRepository({Dio? dio, LoRepository? fallback})
      : _dio = dio ??
            createDio(accessToken: SessionStore.current?.accessToken),
        _fallback = fallback ?? MockLoRepository();

  final Dio _dio;
  final LoRepository _fallback;

  @override
  Future<List<VIP>> fetchVips({String? email}) async {
    try {
      final response = await _dio.get(
        ApiConfig.myLoDelegatesPath,
        queryParameters: {
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final data = response.data;
      if (data is Map && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .map((e) => VIP.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data is List) {
        return data
            .map((e) => VIP.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      if (ApiConfig.useMockApi) {
        return _fallback.fetchVips(email: email);
      }
      throw StateError('Unexpected VIP list response');
    } catch (_) {
      if (ApiConfig.useMockApi) {
        return _fallback.fetchVips(email: email);
      }
      rethrow;
    }
  }
}
