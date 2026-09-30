import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/session/session_store.dart';

/// Shared Dio client for CAP.
///
/// Corporate proxy tip: set `NO_PROXY=35.244.48.209` (or `*`) when calling
/// the CAP host so the WSA does not require proxy auth for this IP.
Dio createDio({String? accessToken}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = accessToken ?? SessionStore.current?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
        String message = error.message ?? 'Request failed';
        final data = error.response?.data;
        final parsed = _messageFromBody(data);
        if (parsed != null && parsed.isNotEmpty) message = parsed;
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
