import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';

/// Help desk data access. Everything is on aide-service
/// (`/app/my-lo/me/helpdesk/*`) with the LO's own login; queries belong to
/// that login. Attachments are uploaded through aide-service to
/// media-services.
class HelpdeskRepository {
  HelpdeskRepository({Dio? dio}) : _aide = dio ?? createDio();

  final Dio _aide;

  static const int pageSize = 10;

  /// Ask for Help limits.
  static const int maxAttachments = 5;
  static const double maxAttachmentMb = 5;
  static const List<String> acceptedTypes = ['jpeg', 'jpg', 'png', 'pdf'];

  /// Active query types for "Select your Query".
  Future<List<HelpdeskQueryType>> fetchQueryTypes() async {
    final res = await _aide.get<dynamic>(ApiConfig.myLoHelpdeskQueryTypesPath);
    final data = AideResponse.unwrap(res.data).data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => HelpdeskQueryType.fromJson(Map<String, dynamic>.from(e)))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  /// One page (0-based) of the LO's queries, latest activity first.
  Future<List<HelpdeskQuery>> fetchQueries({
    int page = 0,
    String? search,
  }) async {
    final res = await _aide.get<dynamic>(
      ApiConfig.myLoHelpdeskQueriesPath,
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = AideResponse.unwrap(res.data).data;
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => HelpdeskQuery.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// A query with its conversation.
  Future<HelpdeskQueryDetail> fetchQuery(String id) async {
    final res = await _aide.get<dynamic>(ApiConfig.myLoHelpdeskQueryPath(id));
    return _detail(res);
  }

  /// Raises a query from the Ask for Help form.
  Future<HelpdeskQueryDetail> raiseQuery({
    required String queryTypeId,
    required String title,
    required String description,
    required List<String> attachments,
  }) async {
    final res = await _aide.post<dynamic>(
      ApiConfig.myLoHelpdeskQueriesPath,
      data: {
        'queryTypeId': queryTypeId,
        'title': title,
        'description': description,
        'attachments': attachments,
        'source': _source(),
      },
    );
    return _detail(res);
  }

  /// Adds the LO's comment; returns the updated conversation.
  Future<HelpdeskQueryDetail> addComment({
    required String queryId,
    required String text,
    required List<String> attachments,
  }) async {
    final res = await _aide.post<dynamic>(
      ApiConfig.myLoHelpdeskCommentsPath(queryId),
      data: {'body': text, 'attachments': attachments},
    );
    return _detail(res);
  }

  /// Uploads one attachment (JPG/JPEG/PNG/PDF, max 5 MB); returns its URL.
  Future<String> uploadAttachment({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
  }) async {
    final res = await _aide.post<dynamic>(
      ApiConfig.myLoHelpdeskAttachmentsPath,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    final data = AideResponse.unwrap(res.data).data;
    final url = data is Map ? data['url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw ApiException('Upload failed.', statusCode: res.statusCode);
    }
    return url;
  }

  HelpdeskQueryDetail _detail(Response<dynamic> res) {
    final data = AideResponse.unwrap(res.data).data;
    if (data is! Map) throw ApiException('Unexpected response.');
    return HelpdeskQueryDetail.fromJson(Map<String, dynamic>.from(data));
  }

  /// Where the query was raised: ANDROID, IOS or WEB.
  static String _source() {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.android:
        return 'ANDROID';
      default:
        return 'WEB';
    }
  }
}
