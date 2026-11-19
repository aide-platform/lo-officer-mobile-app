import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';

/// What aide-service says about the LO and the help desk.
class HelpdeskContext {
  const HelpdeskContext({
    required this.registered,
    required this.eventId,
    this.ticketId,
  });

  /// Whether the LO's badge is registered in eventservices. Informational
  /// only: every LO can use the help desk (tickets are owned by login email).
  final bool registered;

  /// eventservices ticket of the LO's registration (menu ticket rule).
  final String? ticketId;

  /// Event the tickets, form and menu settings belong to.
  final String eventId;

  factory HelpdeskContext.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId']?.toString() ?? '';
    final ticketId = json['ticketId']?.toString();
    return HelpdeskContext(
      registered: json['registered'] == true,
      ticketId: ticketId == null || ticketId.isEmpty ? null : ticketId,
      eventId: eventId.isEmpty ? ApiConfig.eventId : eventId,
    );
  }
}

/// Help desk data access.
///
/// * Tickets (list, raise, detail, comment) go to aide-service with the LO's
///   own token. aide-service forwards them to the eventservices help desk as
///   the LO's EventUser, so they are the same tickets the dashboard sees.
/// * The "Ask for Help" form, its choice lists and attachment upload call
///   the same services as the attendees app directly; they do not depend on
///   who the user is.
class HelpdeskRepository {
  HelpdeskRepository({Dio? aideDio, Dio? publicDio})
    : _aide = aideDio ?? createDio(),
      _publicDio = publicDio ?? createDio(attachSession: false);

  /// aide-service, with the LO token.
  final Dio _aide;

  /// Public form lists (query types, countries, CDN files); no token.
  final Dio _publicDio;

  static const int pageSize = 10;

  /// Last context loaded; supplies the event id to the form and uploads.
  static HelpdeskContext? current;

  static String get eventId => current?.eventId ?? ApiConfig.eventId;

  // ── Context ────────────────────────────────────────────────────────────

  Future<HelpdeskContext> fetchContext() async {
    final res = await _aide.get<dynamic>(ApiConfig.myLoHelpdeskContextPath);
    final aide = AideResponse.unwrap(
      res.data,
      parseData: (raw) => HelpdeskContext.fromJson(AideResponse.asMap(raw)),
    );
    final context = aide.data;
    if (context == null) throw ApiException('Help desk is not available.');
    return current = context;
  }

  // ── Tickets (via aide-service) ─────────────────────────────────────────

  /// One page (0-based) of the LO's tickets, newest change first.
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
    final list = data is Map ? data['dataList'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => HelpdeskQuery.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<HelpdeskComment>> fetchConversation(String queryId) async {
    final res = await _aide.get<dynamic>(
      ApiConfig.myLoHelpdeskQueryPath(queryId),
    );
    final data = AideResponse.unwrap(res.data).data;
    final list = data is Map ? data['conversation'] : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => HelpdeskComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addComment({
    required String queryId,
    required HelpdeskUser user,
    required String text,
    required List<String> attachments,
  }) async {
    final res = await _aide.post<dynamic>(
      ApiConfig.myLoHelpdeskCommentsPath(queryId),
      data: {
        'description': text,
        if (attachments.isNotEmpty) 'attachment': attachments,
        'replyInfo': user.toInfo(),
      },
    );
    AideResponse.unwrap(res.data);
  }

  /// Raises a new ticket from the filled-in "Ask for Help" form. Same fields
  /// as the attendees app; aide-service adds the user and event.
  Future<void> submitQuery({
    required HelpdeskForm form,
    required HelpdeskUser user,
    required List<Map<String, dynamic>> answers,
    required Map<String, dynamic> info,
    Object? queryType,
    Object? title,
  }) async {
    final res = await _aide.post<dynamic>(
      ApiConfig.myLoHelpdeskQueriesPath,
      data: {
        'answer': answers,
        'surveyId': ?form.id,
        'subFormType': ApiConfig.helpdeskSubFormType,
        'info': info,
        'moreInfo': answers,
        'queryType': ?queryType,
        'title': ?title,
        'userInfo': user.toInfo(),
      },
    );
    AideResponse.unwrap(res.data);
  }

  // ── Form (survey-services, via aide-service) ───────────────────────────

  /// The dashboard's help desk form. survey-services needs an eventservices
  /// login, so aide-service fetches it (same request as the attendees app).
  Future<HelpdeskForm> fetchForm() async {
    final res = await _aide.get<dynamic>(ApiConfig.myLoHelpdeskFormPath);
    final data = AideResponse.unwrap(res.data).data;
    if (data is! Map) {
      throw ApiException('The help form is not set up for this event yet.');
    }
    return HelpdeskForm.fromJson(Map<String, dynamic>.from(data));
  }

  /// Options for a `choicesByUrl` field. [url] must already have its
  /// placeholders filled in.
  Future<List<HelpdeskChoice>> fetchChoices(
    String url,
    HelpdeskChoicesByUrl config,
  ) async {
    final absolute = url.startsWith('http')
        ? url
        : '${ApiConfig.apiGatewayUrl}${url.startsWith('/') ? '' : '/'}$url';
    // The form's lists are public "guest" routes (query types, countries) or
    // CDN files. The LO token belongs to aide-service only, so it is never
    // sent here.
    final res = config.methodType == 'POST'
        ? await _publicDio.post<dynamic>(absolute, data: const {})
        : await _publicDio.get<dynamic>(absolute);
    var body = res.data;
    if (body is String && body.trim().startsWith('{')) body = jsonDecode(body);
    final raw = body is Map ? body[config.path] : null;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      final text = (map[config.textName] ?? map['text'] ?? '').toString();
      final valueKey = map['valueName']?.toString();
      final value =
          (valueKey != null ? map[valueKey] : null) ??
          map['value'] ??
          map['id'] ??
          text;
      return HelpdeskChoice(text: text, value: value, raw: map);
    }).toList();
  }

  /// Uploads one attachment and returns its public CDN URL. media-services
  /// needs an eventservices login, so aide-service stores it there (same
  /// upload as the attendees app).
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
}
