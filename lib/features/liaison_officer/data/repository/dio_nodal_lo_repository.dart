import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';

class DioNodalLoRepository implements NodalLoRepository {
  DioNodalLoRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final res = await _dio.get(path);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => AideResponse.asMapList(raw).map(parse).toList(),
    );
    return aide.data ?? const [];
  }

  Future<T> _one<T>(
    Future<Response> future,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final res = await future;
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => parse(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty response.');
    return data;
  }

  @override
  Future<List<LoOrgTypeDto>> listOrgTypes() =>
      _list(ApiConfig.loOrgTypesPath, LoOrgTypeDto.fromJson);

  @override
  Future<LoOrgTypeDto> createOrgType(Map<String, dynamic> body) =>
      _one(_dio.post(ApiConfig.loOrgTypesPath, data: body), LoOrgTypeDto.fromJson);

  @override
  Future<LoOrgTypeDto> updateOrgType(String id, Map<String, dynamic> body) =>
      _one(
        _dio.put('${ApiConfig.loOrgTypesPath}/$id', data: body),
        LoOrgTypeDto.fromJson,
      );

  @override
  Future<void> setOrgTypeActive(String id, bool active) async {
    await _dio.put(
      '${ApiConfig.loOrgTypesPath}/$id/active',
      queryParameters: {'active': active},
    );
  }

  @override
  Future<List<LoOrganisationDto>> listOrganisations() =>
      _list(ApiConfig.loOrganisationsPath, LoOrganisationDto.fromJson);

  @override
  Future<LoOrganisationDto> createOrganisation(Map<String, dynamic> body) =>
      _one(
        _dio.post(ApiConfig.loOrganisationsPath, data: body),
        LoOrganisationDto.fromJson,
      );

  @override
  Future<LoOrganisationDto> updateOrganisation(
    String id,
    Map<String, dynamic> body,
  ) =>
      _one(
        _dio.put('${ApiConfig.loOrganisationsPath}/$id', data: body),
        LoOrganisationDto.fromJson,
      );

  @override
  Future<List<EmailTemplateDto>> listEmailTemplates() =>
      _list(ApiConfig.emailTemplatesPath, EmailTemplateDto.fromJson);

  @override
  Future<EmailTemplateDto> createEmailTemplate(Map<String, dynamic> body) =>
      _one(
        _dio.post(ApiConfig.emailTemplatesPath, data: body),
        EmailTemplateDto.fromJson,
      );

  @override
  Future<EmailTemplateDto> updateEmailTemplate(
    String id,
    Map<String, dynamic> body,
  ) =>
      _one(
        _dio.put('${ApiConfig.emailTemplatesPath}/$id', data: body),
        EmailTemplateDto.fromJson,
      );

  @override
  Future<List<LoActivityDto>> listActivities() =>
      _list(ApiConfig.loActivitiesPath, LoActivityDto.fromJson);

  @override
  Future<LoActivityDto> createActivity(Map<String, dynamic> body) => _one(
        _dio.post(ApiConfig.loActivitiesPath, data: body),
        LoActivityDto.fromJson,
      );

  @override
  Future<LoActivityDto> updateActivity(String id, Map<String, dynamic> body) =>
      _one(
        _dio.put('${ApiConfig.loActivitiesPath}/$id', data: body),
        LoActivityDto.fromJson,
      );

  @override
  Future<void> setActivityActive(String id, bool active) async {
    await _dio.put(
      '${ApiConfig.loActivitiesPath}/$id/active',
      queryParameters: {'active': active},
    );
  }

  @override
  Future<List<LiaisonOfficerDto>> listLiaisonOfficers() =>
      _list(ApiConfig.liaisonOfficersPath, LiaisonOfficerDto.fromJson);

  @override
  Future<LiaisonOfficerDto?> getLiaisonOfficer(String id) async {
    final res = await _dio.get('${ApiConfig.liaisonOfficersPath}/$id');
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    return aide.data;
  }

  @override
  Future<List<LoAssignmentDto>> listAssignments() =>
      _list(ApiConfig.loAssignmentsPath, LoAssignmentDto.fromJson);

  @override
  Future<LoAssignmentDto> createAssignment(Map<String, dynamic> body) => _one(
        _dio.post(ApiConfig.loAssignmentsPath, data: body),
        LoAssignmentDto.fromJson,
      );

  @override
  Future<void> deleteAssignment(String id) async {
    await _dio.delete('${ApiConfig.loAssignmentsPath}/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> listAssignableDelegates() async {
    final res = await _dio.get(ApiConfig.loAssignmentDelegatesPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  @override
  Future<List<LoTaskDto>> listTasks() =>
      _list(ApiConfig.loTasksPath, LoTaskDto.fromJson);

  @override
  Future<LoTaskDto> createTask(Map<String, dynamic> body) => _one(
        _dio.post(ApiConfig.loTasksPath, data: body),
        LoTaskDto.fromJson,
      );

  @override
  Future<LoTaskDto> updateTask(String id, Map<String, dynamic> body) => _one(
        _dio.put('${ApiConfig.loTasksPath}/$id', data: body),
        LoTaskDto.fromJson,
      );

  @override
  Future<LoTaskDto> updateTaskStatus({
    required String id,
    required String statusCode,
    String? remarks,
  }) =>
      _one(
        _dio.put(
          '${ApiConfig.loTasksPath}/$id/status',
          queryParameters: {
            'statusCode': statusCode,
            if (remarks != null) 'remarks': remarks,
          },
        ),
        LoTaskDto.fromJson,
      );

  @override
  Future<List<Map<String, dynamic>>> listDoLetterTemplates() async {
    final res = await _dio.get(ApiConfig.doLetterTemplatesPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  @override
  Future<Map<String, dynamic>?> getBadgeQuota() async {
    final res = await _dio.get(ApiConfig.bvQuotaMinePath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => AideResponse.asMap(raw),
    );
    return aide.data;
  }

  @override
  Future<void> assignBadge(Map<String, dynamic> body) async {
    await _dio.post(ApiConfig.bvQuotaAssignBadgePath, data: body);
  }
}
