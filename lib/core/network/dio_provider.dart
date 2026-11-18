import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/session/session_store.dart';

/// Shared Dio client for CAP.
///
/// Corporate proxy tip: set `NO_PROXY=35.244.48.209` (or `*`) when calling
/// the CAP host so the WSA does not require proxy auth for this IP.
Dio createDio({
  String? accessToken,
  String? baseUrl,
  bool attachSession = true,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(LoHttpPerformanceInterceptor());
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (attachSession) {
          final token = accessToken ?? SessionStore.current?.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
        if (kDebugMode) {
          debugPrint(
            'HTTP ${error.requestOptions.method} ${error.requestOptions.uri} '
            'failed: ${status ?? error.type.name}',
          );
        }
        String message = error.message ?? 'Request failed';
        final data = error.response?.data;
        final parsed = _messageFromBody(data);
        if (parsed != null && parsed.isNotEmpty) message = parsed;
        // A gateway / proxy error page (HTML) or any non-JSON body is not
        // something to show the user; describe the failure instead.
        if (status != null && !_isUserReadable(message)) {
          message = _messageForStatus(status);
        }
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(message, statusCode: status),
            message: message,
          ),
        );
      },
    ),
  );

  return dio;
}

/// False for HTML pages and long raw bodies, which are never a real message.
bool _isUserReadable(String message) {
  final m = message.trim();
  if (m.isEmpty || m.length > 300) return false;
  return !looksLikeHtml(m);
}

/// True when [text] is (part of) an HTML document.
bool looksLikeHtml(String text) {
  final t = text.trimLeft().toLowerCase();
  return t.startsWith('<!doctype') ||
      t.startsWith('<html') ||
      t.contains('<html') ||
      t.contains('</head>') ||
      t.contains('<body');
}

String _messageForStatus(int status) {
  if (status == 502 || status == 503 || status == 504) {
    return 'The server is temporarily unavailable. Please try again in a minute.';
  }
  if (status == 401 || status == 403) {
    return 'Your session has expired or you do not have access. Please sign in again.';
  }
  if (status == 404) {
    return 'This service is not available right now. Please try again later.';
  }
  if (status >= 500) {
    return 'The server ran into a problem ($status). Please try again.';
  }
  return 'Request failed ($status). Please try again.';
}

String? _messageFromBody(Object? data) {
  if (data is Map) {
    final message = data['message']?.toString().trim() ?? '';
    return message.isEmpty ? null : message;
  }
  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.startsWith('{')) {
      try {
        return _messageFromBody(jsonDecode(trimmed));
      } catch (_) {
        return trimmed.isEmpty ? null : trimmed;
      }
    }
    return trimmed.isEmpty ? null : trimmed;
  }
  if (data is List<int> && data.isNotEmpty) {
    try {
      return _messageFromBody(utf8.decode(data));
    } catch (_) {
      return null;
    }
  }
  return null;
}
