import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';

class DioLoPortalRepository implements LoPortalRepository {
  DioLoPortalRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  @override
  Future<LiaisonOfficerDto?> getMyProfile() async {
    final res = await _dio.get(ApiConfig.myLoMePath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    return aide.data;
  }

  @override
  Future<LiaisonOfficerDto> updateMyProfile(Map<String, dynamic> body) async {
    final res = await _dio.put(ApiConfig.myLoMePath, data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty profile response.');
    return data;
  }

  @override
  Future<List<MyLoAssignmentDto>> getMyDelegates() async {
    final res = await _dio.get(ApiConfig.myLoDelegatesPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => AideResponse.asMapList(raw)
          .map(MyLoAssignmentDto.fromJson)
          .toList(),
    );
    return aide.data ?? const [];
  }

  @override
  Future<List<LoTaskDto>> getMyTasks() async {
    final res = await _dio.get(ApiConfig.myLoTasksPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          AideResponse.asMapList(raw).map(LoTaskDto.fromJson).toList(),
    );
    return aide.data ?? const [];
  }

  @override
  Future<LoTaskDto> updateTaskStatus({
    required String taskId,
    required String statusCode,
    String? remarks,
  }) async {
    final res = await _dio.put(
      ApiConfig.myLoTaskStatusPath(taskId),
      queryParameters: {
        'statusCode': statusCode,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
    );
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => LoTaskDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty task response.');
    return data;
  }

  @override
  Future<MyLoAssignmentDto> updateTravel({
    required String assignmentId,
    required Map<String, dynamic> body,
  }) async {
    final res = await _dio.put(
      ApiConfig.myLoTravelPath(assignmentId),
      data: body,
    );
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          MyLoAssignmentDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty travel response.');
    return data;
  }
}
