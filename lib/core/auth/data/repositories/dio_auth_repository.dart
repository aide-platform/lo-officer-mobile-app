import 'package:dio/dio.dart';
import 'package:liaison_officer/core/auth/data/repositories/mock_auth_repository.dart';
import 'package:liaison_officer/core/auth/domain/auth_repository.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';

/// Dio-backed auth. Mock fallback only when [ApiConfig.useMockApi] is true.
class DioAuthRepository implements AuthRepository {
  DioAuthRepository({Dio? dio, AuthRepository? fallback})
      : _dio = dio ?? createDio(),
        _fallback = fallback ?? MockAuthRepository();

  final Dio _dio;
  final AuthRepository _fallback;

  @override
  Future<AuthCredentialsResult> validateCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.loginPath,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (data is! Map) {
        return _failOrFallback(
          email: email,
          password: password,
          message: 'Unexpected login response.',
        );
      }

      final success = data['success'] == true;
      if (!success || response.statusCode == 401) {
        return AuthCredentialsResult.failure(
          data['message']?.toString() ?? 'Invalid email or password.',
        );
      }

      final payload = data['data'];
      if (payload is Map) {
        final expiresRaw = payload['expiresAt']?.toString();
        final accessToken = payload['accessToken']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          return AuthCredentialsResult.failure('Login response missing token.');
        }
        return AuthCredentialsResult.success(
          email: payload['email']?.toString() ?? email,
          role: payload['role']?.toString() ?? MockAuthRepository.loRole,
          accessToken: accessToken,
          refreshToken: payload['refreshToken']?.toString(),
          expiresAt: expiresRaw != null
              ? DateTime.tryParse(expiresRaw)
              : DateTime.now().add(const Duration(days: 30)),
        );
      }

      return AuthCredentialsResult.failure('Login response missing payload.');
    } on DioException catch (e) {
      final api = e.error;
      if (api is ApiException && api.statusCode == 401) {
        return AuthCredentialsResult.failure(api.message);
      }
      return _failOrFallback(
        email: email,
        password: password,
        message: api is ApiException ? api.message : 'Network error.',
      );
    } catch (e) {
      return _failOrFallback(
        email: email,
        password: password,
        message: e.toString(),
      );
    }
  }

  @override
  Future<AuthOtpResult> sendOtp({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConfig.sendOtpPath,
        data: {'email': email.trim()},
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return AuthOtpResult.success(
          email: email.trim().toLowerCase(),
          message: data['message']?.toString() ?? 'OTP sent successfully.',
        );
      }

      return AuthOtpResult.failure(
        data is Map ? data['message']?.toString() ?? 'Unable to send OTP.' : 'Unable to send OTP.',
      );
    } on DioException catch (e) {
      final api = e.error;
      if (api is ApiException) {
        return AuthOtpResult.failure(api.message);
      }
      return _fallback.sendOtp(email: email);
    } catch (e) {
      return _fallback.sendOtp(email: email);
    }
  }

  @override
  Future<AuthOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.verifyOtpPath,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return AuthOtpResult.success(
          email: email.trim().toLowerCase(),
          message: data['message']?.toString() ?? 'OTP verified successfully.',
        );
      }

      return AuthOtpResult.failure(
        data is Map ? data['message']?.toString() ?? 'Invalid OTP.' : 'Invalid OTP.',
      );
    } on DioException catch (e) {
      final api = e.error;
      if (api is ApiException) {
        return AuthOtpResult.failure(api.message);
      }
      return _fallback.verifyOtp(email: email, otp: otp);
    } catch (e) {
      return _fallback.verifyOtp(email: email, otp: otp);
    }
  }

  Future<AuthCredentialsResult> _failOrFallback({
    required String email,
    required String password,
    required String message,
  }) {
    if (ApiConfig.useMockApi) {
      return _fallback.validateCredentials(email: email, password: password);
    }
    return Future.value(AuthCredentialsResult.failure(message));
  }
}
