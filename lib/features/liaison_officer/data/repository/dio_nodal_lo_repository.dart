import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import 'package:liaison_officer/features/liaison_officer/data/local/do_letter_local_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/pdf/do_letter_pdf_builder.dart';
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
  Future<void> deleteEmailTemplate(String id) async {
    await _dio.delete('${ApiConfig.emailTemplatesPath}/$id');
  }

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
  Future<List<LoExperienceDto>> getLoExperiences(String loId) async {
    final res =
        await _dio.get('${ApiConfig.liaisonOfficersPath}/$loId/experiences');
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          AideResponse.asMapList(raw).map(LoExperienceDto.fromJson).toList(),
    );
    return aide.data ?? const [];
  }

  @override
  Future<List<String>> getLoLanguages(String loId) async {
    final res =
        await _dio.get('${ApiConfig.liaisonOfficersPath}/$loId/languages');
    final aide = AideResponse.unwrap(res.data);
    final raw = aide.data;
    if (raw is List) {
      return raw.map((e) {
        if (e is String) return e;
        if (e is Map) {
          return e['languageName']?.toString() ?? e['name']?.toString() ?? '';
        }
        return '';
      }).where((e) => e.isNotEmpty).toList();
    }
    return const [];
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
  Future<Map<String, dynamic>?> getDelegateProfile({
    required String attendeeType,
    required String attendeeId,
  }) async {
    final res = await _dio.get(
      ApiConfig.loAssignmentDelegateProfilePath(attendeeType, attendeeId),
    );
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => AideResponse.asMap(raw),
    );
    return aide.data;
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
  Future<List<DoLetterTemplateDto>> listDoLetterTemplates() =>
      _list(ApiConfig.doLetterTemplatesPath, DoLetterTemplateDto.fromJson);

  Future<DoLetterTemplateDto> _upsertDoTemplate({
    required String method,
    String? id,
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  }) async {
    final form = FormData.fromMap({
      'payload': jsonEncode(payload),
      if (fileBytes != null)
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename ?? 'template.pdf',
        ),
    });
    final Response res;
    if (method == 'post') {
      res = await _dio.post(ApiConfig.doLetterTemplatesPath, data: form);
    } else {
      res = await _dio.put('${ApiConfig.doLetterTemplatesPath}/$id', data: form);
    }
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          DoLetterTemplateDto.fromJson(AideResponse.asMap(raw)),
    );
    final data = aide.data;
    if (data == null) throw ApiException('Empty DO template response.');
    return data;
  }

  @override
  Future<DoLetterTemplateDto> createDoLetterTemplate({
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  }) =>
      _upsertDoTemplate(
        method: 'post',
        payload: payload,
        fileBytes: fileBytes,
        filename: filename,
      );

  @override
  Future<DoLetterTemplateDto> updateDoLetterTemplate(
    String id, {
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filename,
  }) =>
      _upsertDoTemplate(
        method: 'put',
        id: id,
        payload: payload,
        fileBytes: fileBytes,
        filename: filename,
      );

  @override
  Future<void> deleteDoLetterTemplate(String id) async {
    await _dio.delete('${ApiConfig.doLetterTemplatesPath}/$id');
  }

  @override
  Future<List<int>> downloadDoLetterTemplateFile(String id) async {
    final res = await _dio.get<List<int>>(
      ApiConfig.doLetterTemplateFilePath(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  @override
  Future<List<int>> downloadOrgDoLetter(String orgId) async {
    try {
      final res = await _dio.get<List<int>>(
        ApiConfig.loOrgDoLetterPreviewPath(orgId),
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data ?? const [];
      if (data.isNotEmpty) return data;
    } on DioException {
      // Fall through to client PDF builder.
    }
    final orgs = await listOrganisations();
    LoOrganisationDto? org;
    for (final o in orgs) {
      if (o.id == orgId) {
        org = o;
        break;
      }
    }
    if (org == null) return const [];
    final templates = await listDoLetterTemplates();
    DoLetterTemplateDto? t;
    for (final tpl in templates) {
      if (org.orgTypeId != null &&
          (tpl.applicableOrgTypeIds.contains(org.orgTypeId) ||
              tpl.recipientType == org.orgTypeId)) {
        t = tpl;
        break;
      }
    }
    t ??= templates.isEmpty ? null : templates.first;
    return DoLetterPdfBuilder.build(org: org, template: t);
  }

  @override
  Future<void> uploadSignedDoLetter({
    required String orgId,
    required Uint8List bytes,
    required String filename,
    required String signingAuthority,
    required Map<String, bool> checklist,
  }) async {
    if (checklist.values.any((v) => v != true)) {
      throw ApiException('All checklist items must be confirmed.');
    }
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'signingAuthority': signingAuthority,
      });
      await _dio.post(ApiConfig.loOrgDoLetterSignedPath(orgId), data: form);
    } on DioException {
      // Persist locally when CAP endpoint is absent.
    }
    await DoLetterLocalStore.markSigned(
      orgId: orgId,
      signingAuthority: signingAuthority,
      pdfBytes: bytes,
    );
  }

  @override
  Future<void> sendNominationEmail({
    required String orgId,
    required String emailTemplateId,
    List<PickedAttachment> attachments = const [],
  }) async {
    final merged = List<PickedAttachment>.from(attachments);
    try {
      final templates = await listEmailTemplates();
      EmailTemplateDto? tpl;
      for (final e in templates) {
        if (e.id == emailTemplateId) {
          tpl = e;
          break;
        }
      }
      final tag = (tpl?.purposeTag ?? '').toLowerCase();
      if (tag.contains('do letter') || tag.contains('do_letter')) {
        final signed = await DoLetterLocalStore.signedPdfBytes(orgId);
        if (signed != null && signed.isNotEmpty) {
          merged.insert(
            0,
            PickedAttachment(
              bytes: signed,
              filename: 'signed-do-$orgId.pdf',
            ),
          );
        }
      }
    } catch (_) {}

    try {
      final form = FormData.fromMap({
        'emailTemplateId': emailTemplateId,
        for (var i = 0; i < merged.length; i++)
          'file$i': MultipartFile.fromBytes(
            merged[i].bytes,
            filename: merged[i].filename,
          ),
      });
      await _dio.post(ApiConfig.loOrgSendNominationPath(orgId), data: form);
    } on DioException {
      await MockEmailNotifier.send(
        to: orgId,
        subject: 'Nomination request',
        body:
            'Template $emailTemplateId\nAttachments: ${merged.map((e) => e.filename).join(', ')}',
      );
    }
    await DoLetterLocalStore.markNominationSent(orgId);
  }

  @override
  Future<void> sendNominationEmailBulk({
    required List<String> orgIds,
    required String emailTemplateId,
  }) async {
    for (final id in orgIds) {
      await sendNominationEmail(orgId: id, emailTemplateId: emailTemplateId);
    }
  }

  @override
  Future<Map<String, dynamic>> orgDoLetterStatus(String orgId) =>
      DoLetterLocalStore.statusFor(orgId);

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

  @override
  Future<List<int>> downloadBadge(String passId) async {
    final res = await _dio.get<List<int>>(
      ApiConfig.bvQuotaBadgeDownloadPath(passId),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  @override
  Future<List<OrgSubNodalOfficerDto>> listSubNodals() async {
    try {
      final res = await _dio.get(ApiConfig.orgSubNodalOfficersPath);
      return AideResponse.unwrap(
            res.data,
            parseData: (raw) => AideResponse.asMapList(raw)
                .map(OrgSubNodalOfficerDto.fromJson)
                .toList(),
          ).data ??
          const [];
    } on DioException {
      return const [];
    }
  }

  @override
  Future<OrgSubNodalOfficerDto> createSubNodal(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.orgSubNodalOfficersPath, data: body);
    return AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          OrgSubNodalOfficerDto.fromJson(AideResponse.asMap(raw)),
    ).data!;
  }

  @override
  Future<OrgSubNodalOfficerDto> updateSubNodal(
    String id,
    Map<String, dynamic> body,
  ) async {
    final res =
        await _dio.put('${ApiConfig.orgSubNodalOfficersPath}/$id', data: body);
    return AideResponse.unwrap(
      res.data,
      parseData: (raw) =>
          OrgSubNodalOfficerDto.fromJson(AideResponse.asMap(raw)),
    ).data!;
  }

  @override
  Future<void> deleteSubNodal(String id) async {
    await _dio.delete('${ApiConfig.orgSubNodalOfficersPath}/$id');
  }
}
