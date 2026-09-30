import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';

class DioLoPortalRepository implements LoPortalRepository {
  DioLoPortalRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  Future<void> _upload(String path, Uint8List bytes, String filename) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    await _dio.post(path, data: form);
  }

  @override
  Future<LiaisonOfficerDto?> getMyProfile() async {
    final res = await _dio.get(ApiConfig.myLoMePath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
    );
    return aide.data;
  }

  @override
  Future<LiaisonOfficerDto> updateMyProfile(Map<String, dynamic> body) async {
    final res = await _dio.put(ApiConfig.myLoMePath, data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => LiaisonOfficerDto.fromJson(AideResponse.asMap(raw)),
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
      parseData: (raw) =>
          AideResponse.asMapList(raw).map(MyLoAssignmentDto.fromJson).toList(),
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
    final travelBody = Map<String, dynamic>.from(body)
      ..remove('arrivalConnectingFlights')
      ..remove('departureConnectingFlights');
    final res = await _dio.put(
      ApiConfig.myLoTravelPath(assignmentId),
      data: travelBody,
    );
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => MyLoAssignmentDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty travel response.');
    return data;
  }

  @override
  Future<MyLoAssignmentDto> updateArrivalFlight({
    required String assignmentId,
    required Map<String, dynamic> body,
  }) async {
    final arrivalBody = <String, dynamic>{
      if (body['arrivalFlight'] != null) 'arrivalFlight': body['arrivalFlight'],
      if (body['arrivalTerminal'] != null)
        'arrivalTerminal': body['arrivalTerminal'],
      if (body['arrivalDate'] != null) 'arrivalDate': body['arrivalDate'],
      if (body['arrivalTime'] != null) 'arrivalTime': body['arrivalTime'],
    };
    final res = await _dio.put(
      ApiConfig.myLoArrivalFlightPath(assignmentId),
      data: arrivalBody,
    );
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => MyLoAssignmentDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty arrival-flight response.');
    return data;
  }

  @override
  Future<void> uploadPhoto(Uint8List bytes, String filename) =>
      _upload(ApiConfig.myLoPhotoPath, bytes, filename);

  @override
  Future<void> uploadSignature(Uint8List bytes, String filename) =>
      _upload(ApiConfig.myLoSignaturePath, bytes, filename);

  @override
  Future<void> uploadOrgBadgeFront(Uint8List bytes, String filename) =>
      _upload(ApiConfig.myLoOrgBadgeFrontPath, bytes, filename);

  @override
  Future<void> uploadOrgBadgeBack(Uint8List bytes, String filename) =>
      _upload(ApiConfig.myLoOrgBadgeBackPath, bytes, filename);

  @override
  Future<void> uploadAadhaarFront(Uint8List bytes, String filename) =>
      _upload(ApiConfig.myLoAadhaarFrontPath, bytes, filename);

  @override
  Future<void> uploadAadhaarBack(Uint8List bytes, String filename) =>
      _upload(ApiConfig.myLoAadhaarBackPath, bytes, filename);

  @override
  Future<List<LoExperienceDto>> listExperiences() async {
    final res = await _dio.get(ApiConfig.myLoExperiencesPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          AideResponse.asMapList(raw).map(LoExperienceDto.fromJson).toList(),
    );
    return aide.data ?? const [];
  }

  @override
  Future<LoExperienceDto> addExperience(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.myLoExperiencesPath, data: body);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => LoExperienceDto.fromJson(AideResponse.asMap(raw)),
    );
    return aide.data ?? LoExperienceDto.fromJson(body);
  }

  @override
  Future<void> deleteExperience(String id) async {
    await _dio.delete(ApiConfig.myLoExperiencePath(id));
  }

  @override
  Future<List<String>> listLanguages() async {
    final res = await _dio.get(ApiConfig.myLoLanguagesPath);
    final aide = AideResponse.unwrap(res.data);
    final raw = aide.data;
    if (raw is List) {
      return raw
          .map((e) {
            if (e is String) return e;
            if (e is Map) {
              return e['languageName']?.toString() ??
                  e['name']?.toString() ??
                  e['language']?.toString() ??
                  '';
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Future<void> setLanguages(List<String> languages) async {
    final desired = languages
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final res = await _dio.get(ApiConfig.myLoLanguagesPath);
    final aide = AideResponse.unwrap(res.data);
    final existingRows = <Map<String, String>>[];
    final raw = aide.data;
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        final id = e['id']?.toString();
        final name =
            e['languageName']?.toString() ??
            e['name']?.toString() ??
            e['language']?.toString() ??
            '';
        if (id == null || id.isEmpty || name.isEmpty) continue;
        existingRows.add({'id': id, 'name': name});
      }
    }

    final existingNames = existingRows.map((e) => e['name']!).toSet();

    for (final row in existingRows) {
      if (!desired.contains(row['name'])) {
        await _dio.delete(ApiConfig.myLoLanguagePath(row['id']!));
      }
    }

    for (final lang in desired) {
      if (existingNames.contains(lang)) continue;
      await _dio.post(
        ApiConfig.myLoLanguagesPath,
        data: {'languageName': lang},
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVehicles(String assignmentId) async {
    final res = await _dio.get(ApiConfig.myLoVehiclesPath(assignmentId));
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getNominations(String assignmentId) async {
    final res = await _dio.get(ApiConfig.myLoNominationsPath(assignmentId));
    final aide = AideResponse.unwrap(
      res.data,
      parseData: AideResponse.asMapList,
    );
    return aide.data ?? const [];
  }

  @override
  Future<MyLoAssignmentDto> updateMovement({
    required String assignmentId,
    required LoMovementUpdate movement,
  }) async {
    final body = movement.toTravelBody();
    var updated = await updateTravel(assignmentId: assignmentId, body: body);
    if (movement.usesArrivalFlightEndpoint) {
      updated = await updateArrivalFlight(
        assignmentId: assignmentId,
        body: body,
      );
    }
    return updated;
  }

  @override
  Future<List<LoItineraryItem>> getItinerary(String assignmentId) async {
    final delegates = await getMyDelegates();
    MyLoAssignmentDto? assignment;
    for (final d in delegates) {
      if (d.assignmentId == assignmentId) {
        assignment = d;
        break;
      }
    }
    assignment ??= MyLoAssignmentDto(assignmentId: assignmentId);
    final vehicles = await getVehicles(assignmentId);
    final nominations = await getNominations(assignmentId);
    return LoItineraryItem.compose(
      assignment: assignment,
      nominations: nominations,
      vehicles: vehicles,
    );
  }

  @override
  Future<LoIssueReport> reportIssue(LoIssueReport issue) async {
    // CAP create with durable Hive offline queue on failure.
    try {
      final res = await _dio.post(
        ApiConfig.myLoIssuesPath,
        data: issue.toApiBody(),
      );
      final aide = AideResponse.unwrap(res.data);
      if (aide.success == false) {
        throw StateError(aide.message ?? 'Issue create rejected');
      }
      String? remoteId;
      try {
        if (aide.data != null) {
          remoteId = AideResponse.asMap(aide.data)['id']?.toString();
        }
      } catch (_) {}
      final submitted = issue.copyWith(
        id: (remoteId != null && remoteId.isNotEmpty) ? remoteId : issue.id,
        synced: true,
        status: 'submitted',
      );
      return LoOfflineStore.saveIssue(submitted);
    } on DioException catch (_) {
      final local = issue.copyWith(synced: false, status: 'on_device');
      return LoOfflineStore.saveIssue(local);
    } catch (_) {
      final local = issue.copyWith(synced: false, status: 'failed');
      return LoOfflineStore.saveIssue(local);
    }
  }

  @override
  Future<List<LoIssueReport>> listReportedIssues() async {
    return LoOfflineStore.listIssues();
  }

  @override
  Future<List<LoHelplineDto>> getHelplines() async {
    try {
      final res = await _dio.get(ApiConfig.loHelpLinesActivePath);
      final aide = AideResponse.unwrap(
        res.data,
        parseData: (raw) =>
            AideResponse.asMapList(raw).map(LoHelplineDto.fromJson).toList(),
      );
      return LoHelplineDto.visible(aide.data ?? const []);
    } on DioException catch (e) {
      final wrapped = e.error;
      final code = wrapped is ApiException
          ? wrapped.statusCode
          : e.response?.statusCode;
      if (code == 404 || e.response?.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadBadge(String passId) async {
    try {
      final res = await _dio.get<List<int>>(
        ApiConfig.bvQuotaBadgeDownloadPath(passId),
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'Accept': 'application/pdf'},
        ),
      );
      return _pdfBytes(res.data ?? const []);
    } on DioException catch (e) {
      final message = _jsonMessage(e.response?.data);
      if (message != null) {
        throw ApiException(message, statusCode: e.response?.statusCode);
      }
      rethrow;
    }
  }

  List<int> _pdfBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      throw ApiException('Badge file was empty.');
    }
    final message = _jsonMessage(bytes);
    if (message != null) throw ApiException(message);
    if (!_isPdf(bytes)) {
      throw ApiException('Badge download did not return a PDF.');
    }
    return bytes;
  }

  bool _isPdf(List<int> bytes) {
    var i = 0;
    while (i < bytes.length &&
        (bytes[i] == 0x20 ||
            bytes[i] == 0x09 ||
            bytes[i] == 0x0A ||
            bytes[i] == 0x0D)) {
      i++;
    }
    if (i + 4 > bytes.length) return false;
    return bytes[i] == 0x25 &&
        bytes[i + 1] == 0x50 &&
        bytes[i + 2] == 0x44 &&
        bytes[i + 3] == 0x46;
  }

  String? _jsonMessage(Object? data) {
    List<int>? bytes;
    if (data is List<int>) bytes = data;
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final text = utf8.decode(bytes);
      final trimmed = text.trimLeft();
      if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return null;
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }
      return 'Badge download did not return a PDF.';
    } catch (_) {
      return null;
    }
  }
}
