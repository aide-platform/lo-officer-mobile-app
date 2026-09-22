import 'package:dio/dio.dart';
import 'package:liaison_officer/core/auth/domain/auth_repository.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

class DioAuthRepository implements AuthRepository {
  DioAuthRepository({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  @override
  Future<void> checkEmail({required String email}) async {
    await _dio.post(
      ApiConfig.checkEmailPath,
      data: {'email': email.trim()},
    );
  }

  @override
  Future<CaptchaResult> fetchCaptcha() async {
    try {
      final res = await _dio.get(ApiConfig.captchaPath);
      final aide = AideResponse.unwrap(
        res.data,
        parseData: (raw) => CaptchaChallenge.fromJson(AideResponse.asMap(raw)),
      );
      final data = aide.data;
      if (data == null || data.captchaId.isEmpty) {
        return const CaptchaResult.failure('Unable to load CAPTCHA.');
      }
      return CaptchaResult.success(
        captchaId: data.captchaId,
        imageBase64: data.imageBase64,
      );
    } on DioException catch (e) {
      final api = e.error;
      return CaptchaResult.failure(
        api is ApiException ? api.message : 'Unable to load CAPTCHA.',
      );
    }
  }

  @override
  Future<AuthOtpResult> requestOtp({
    required String email,
    required String captchaId,
    required String captchaAnswer,
  }) async {
    try {
      final res = await _dio.post(
        ApiConfig.requestOtpPath,
        data: {
          'email': email.trim(),
          'captchaId': captchaId,
          'captchaAnswer': captchaAnswer.trim(),
        },
      );
      final aide = AideResponse.unwrap(res.data);
      return AuthOtpResult.success(
        email: email.trim().toLowerCase(),
        message: aide.message ?? 'OTP sent successfully.',
      );
    } on DioException catch (e) {
      final api = e.error;
      return AuthOtpResult.failure(
        api is ApiException ? api.message : 'Unable to send OTP.',
      );
    } catch (e) {
      return AuthOtpResult.failure(e.toString());
    }
  }

  @override
  Future<AuthOtpResult> resendOtp({required String email}) async {
    try {
      final res = await _dio.post(
        ApiConfig.resendOtpPath,
        data: {'email': email.trim()},
      );
      final aide = AideResponse.unwrap(res.data);
      return AuthOtpResult.success(
        email: email.trim().toLowerCase(),
        message: aide.message ?? 'OTP resent successfully.',
      );
    } on DioException catch (e) {
      final api = e.error;
      return AuthOtpResult.failure(
        api is ApiException ? api.message : 'Unable to resend OTP.',
      );
    }
  }

  @override
  Future<AuthOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final res = await _dio.post(
        ApiConfig.verifyOtpPath,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );
      final aide = AideResponse.unwrap(
        res.data,
        parseData: (raw) => JwtSession.fromJson(AideResponse.asMap(raw)),
      );
      final jwt = aide.data;
      if (jwt == null || jwt.accessToken.isEmpty) {
        return const AuthOtpResult.failure('Login response missing token.');
      }
      return AuthOtpResult.success(
        email: jwt.email.isNotEmpty ? jwt.email : email.trim().toLowerCase(),
        message: aide.message ?? 'OTP verified successfully.',
        role: jwt.role,
        accessToken: jwt.accessToken,
        expiresAt: jwt.expiresAt,
        userId: jwt.userId,
      );
    } on DioException catch (e) {
      final api = e.error;
      return AuthOtpResult.failure(
        api is ApiException ? api.message : 'Invalid OTP.',
      );
    }
  }

  @override
  Future<AuthCredentialsResult> validateCredentials({
    required String email,
    required String password,
  }) async {
    return const AuthCredentialsResult.failure(
      'Password login is not supported. Use Email OTP.',
    );
  }
}
