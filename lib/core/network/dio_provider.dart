import 'package:dio/dio.dart';
import 'package:liaison_officer/core/auth/data/repositories/mock_auth_repository.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/session/session_store.dart';

/// Shared Dio instance. When [ApiConfig.useMockApi] is true, LO/auth
/// requests are short-circuited by [MockApiInterceptor] (no network).
///
/// Bearer token defaults to [SessionStore.current] when [accessToken] is omitted.
Dio createDio({String? accessToken}) {
  final token = accessToken ?? SessionStore.current?.accessToken;
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    ),
  );

  if (ApiConfig.useMockApi) {
    dio.interceptors.add(MockApiInterceptor());
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        final status = error.response?.statusCode;
        final message = error.response?.data is Map
            ? (error.response!.data['message']?.toString() ??
                error.message ??
                'Request failed')
            : (error.message ?? 'Request failed');
        return handler.reject(
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

/// Offline mock interceptor — keeps login + VIP list working without a backend.
class MockApiInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final path = options.path;

    if (path.contains(ApiConfig.loginPath) || path.contains('/auth/signin')) {
      final body = options.data;
      final email = body is Map ? body['email']?.toString() ?? '' : '';
      final password = body is Map ? body['password']?.toString() ?? '' : '';

      final ok = email.trim().toLowerCase() == MockAuthRepository.loEmail &&
          password == MockAuthRepository.loPassword;

      if (!ok) {
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 401,
            data: {
              'success': false,
              'message': 'Invalid email or password.',
            },
          ),
        );
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'OK',
            'data': {
              'email': MockAuthRepository.loEmail,
              'role': MockAuthRepository.loRole,
              'accessToken': 'mock_access_token',
              'refreshToken': 'mock_refresh_token',
              'expiresAt': DateTime.now()
                  .add(const Duration(days: 30))
                  .toIso8601String(),
            },
          },
        ),
      );
    }

    if (path.contains(ApiConfig.loVipsPath) || path.contains('/lo/vips')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'OK',
            'data': {'source': 'mock_api'},
          },
        ),
      );
    }

    // Unmocked paths continue (will fail offline unless a real server exists).
    handler.next(options);
  }
}
