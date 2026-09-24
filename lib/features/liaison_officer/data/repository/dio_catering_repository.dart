import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/domain/catering_repository.dart';

class DioCateringRepository implements CateringRepository {
  DioCateringRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final res = await _dio.get(path);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  Future<Map<String, dynamic>> _one(Future<Response> future) async {
    final res = await future;
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMap,
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty response.');
    return data;
  }

  Future<List<int>> _bytes(String path) async {
    final res = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> listMine() =>
      _list(ApiConfig.cateringReqsMinePath);

  @override
  Future<List<Map<String, dynamic>>> listAll() =>
      _list(ApiConfig.cateringReqsPath);

  @override
  Future<List<Map<String, dynamic>>> listPending() =>
      _list(ApiConfig.cateringReqsPendingPath);

  @override
  Future<Map<String, dynamic>> getById(String id) =>
      _one(_dio.get(ApiConfig.cateringReqPath(id)));

  @override
  Future<Map<String, dynamic>> createRequirement(
    Map<String, dynamic> body,
  ) =>
      _one(_dio.post(ApiConfig.cateringReqsPath, data: body));

  @override
  Future<void> deleteRequirement(String id) async {
    await _dio.delete(ApiConfig.cateringReqPath(id));
  }

  @override
  Future<Map<String, dynamic>> approve(
    String id, {
    int? qtyApproved,
    String? remarks,
  }) =>
      _one(
        _dio.post(
          ApiConfig.cateringReqApprovePath(id),
          queryParameters: {
            if (qtyApproved != null) 'qtyApproved': qtyApproved,
            if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
          },
        ),
      );

  @override
  Future<Map<String, dynamic>> reject(
    String id, {
    required String remarks,
  }) =>
      _one(
        _dio.post(
          ApiConfig.cateringReqRejectPath(id),
          queryParameters: {'remarks': remarks},
        ),
      );

  @override
  Future<List<Map<String, dynamic>>> listCommitteeRecipients() =>
      _list(ApiConfig.cateringReqsCommitteeRecipientsPath);

  @override
  Future<List<Map<String, dynamic>>> listCommitteeCoupons() =>
      _list(ApiConfig.ecouponsForMyCommitteePath);

  @override
  Future<List<Map<String, dynamic>>> listMyCoupons() =>
      _list(ApiConfig.ecouponsMinePath);

  @override
  Future<void> distribute({
    required String cateringReqId,
    required String subNodalId,
    int? quantity,
  }) async {
    await _dio.post(
      ApiConfig.ecouponsDistributeByReqPath(cateringReqId),
      data: {
        'holderPersonId': subNodalId,
        if (quantity != null) 'count': quantity,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> distributeFromPool(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post(ApiConfig.ecouponsDistributePath, data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  @override
  Future<List<int>> downloadCouponPdf(String couponId) =>
      _bytes(ApiConfig.ecouponPdfPath(couponId));

  @override
  Future<List<int>> downloadAllCommitteeCouponsPdf() =>
      _bytes(ApiConfig.ecouponsForMyCommitteePdfPath);

  @override
  Future<List<int>> downloadMyCouponsPdf() =>
      _bytes(ApiConfig.ecouponsMyPdfPath);
}
