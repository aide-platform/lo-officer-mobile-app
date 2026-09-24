import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/org_rep_repository.dart';

class DioOrgRepRepository implements OrgRepRepository {
  DioOrgRepRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  @override
  Future<Map<String, dynamic>?> getMyOrganisation() async {
    final res = await _dio.get(ApiConfig.myOrganisationPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => AideResponse.asMap(raw),
    );
    return aide.data;
  }

  @override
  Future<List<LiaisonOfficerDto>> listLos() async {
    final res = await _dio.get(ApiConfig.myOrganisationLosPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => AideResponse.asMapList(raw)
          .map(LiaisonOfficerDto.fromJson)
          .toList(),
    );
    return aide.data ?? const [];
  }

  @override
  Future<LiaisonOfficerDto?> getLo(String loId) async {
    final los = await listLos();
    for (final lo in los) {
      if (lo.id == loId) return lo;
    }
    return null;
  }

  @override
  Future<LiaisonOfficerDto> nominateLo(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.myOrganisationLosPath, data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty LO response.');
    return data;
  }

  @override
  Future<LiaisonOfficerDto> reNominateLo(
    String rejectedLoId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post(
      ApiConfig.myOrganisationLoReNominatePath(rejectedLoId),
      data: body,
    );
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty re-nominate response.');
    return data;
  }

  @override
  Future<void> sendReminder(String loId) async {
    await _dio.post(ApiConfig.myOrganisationLoReminderPath(loId));
  }

  @override
  Future<void> sendPendingReminders() async {
    await _dio.post(ApiConfig.myOrganisationPendingRemindersPath);
  }

  @override
  Future<List<int>> downloadImportTemplate() async {
    final res = await _dio.get<List<int>>(
      ApiConfig.myOrganisationImportTemplatePath,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  @override
  Future<Map<String, dynamic>> bulkImport(List<int> bytes, String filename) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res =
        await _dio.post(ApiConfig.myOrganisationBulkImportPath, data: form);
    final data = res.data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(data);
    }
    return {'message': 'Bulk import completed.', 'raw': data?.toString()};
  }

  @override
  Future<List<OrgSubNodalOfficerDto>> listSubNodals() async {
    try {
      final res = await _dio.get(ApiConfig.orgSubNodalOfficersMinePath);
      final aide = AideResponse.unwrap(
        res.data,
        parseData: (raw) => AideResponse.asMapList(raw)
            .map(OrgSubNodalOfficerDto.fromJson)
            .toList(),
      );
      return aide.data ?? const [];
    } on DioException {
      final res = await _dio.get(ApiConfig.orgSubNodalOfficersPath);
      final aide = AideResponse.unwrap(
        res.data,
        parseData: (raw) => AideResponse.asMapList(raw)
            .map(OrgSubNodalOfficerDto.fromJson)
            .toList(),
      );
      return aide.data ?? const [];
    }
  }

  @override
  Future<OrgSubNodalOfficerDto> createSubNodal(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.orgSubNodalOfficersPath, data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          OrgSubNodalOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty sub-nodal response.');
    return data;
  }

  @override
  Future<OrgSubNodalOfficerDto> updateSubNodal(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res =
        await _dio.put('${ApiConfig.orgSubNodalOfficersPath}/$id', data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          OrgSubNodalOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty sub-nodal response.');
    return data;
  }

  @override
  Future<void> deleteSubNodal(String id) async {
    await _dio.delete('${ApiConfig.orgSubNodalOfficersPath}/$id');
  }

  @override
  Future<List<int>> downloadBadge(String passId) async {
    final res = await _dio.get<List<int>>(
      ApiConfig.bvQuotaBadgeDownloadPath(passId),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }
}
