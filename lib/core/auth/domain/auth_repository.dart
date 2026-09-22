/// Auth result for CAP JWT sessions.
class AuthCredentialsResult {
  final bool success;
  final String? email;
  final String? role;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? userId;

  const AuthCredentialsResult.success({
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.userId,
  })  : success = true,
        errorMessage = null;

  const AuthCredentialsResult.failure(this.errorMessage)
      : success = false,
        email = null,
        role = null,
        accessToken = null,
        refreshToken = null,
        expiresAt = null,
        userId = null;
}

class AuthOtpResult {
  final bool success;
  final String? email;
  final String? message;
  final String? role;
  final String? accessToken;
  final DateTime? expiresAt;
  final String? userId;

  const AuthOtpResult.success({
    required this.email,
    this.message = 'OTP sent successfully.',
    this.role,
    this.accessToken,
    this.expiresAt,
    this.userId,
  }) : success = true;

  const AuthOtpResult.failure(String message)
      : success = false,
        email = null,
        message = message,
        role = null,
        accessToken = null,
        expiresAt = null,
        userId = null;
}

class CaptchaResult {
  final bool success;
  final String? captchaId;
  final String? imageBase64;
  final String? message;

  const CaptchaResult.success({
    required this.captchaId,
    required this.imageBase64,
  })  : success = true,
        message = null;

  const CaptchaResult.failure(this.message)
      : success = false,
        captchaId = null,
        imageBase64 = null;
}

abstract class AuthRepository {
  Future<void> checkEmail({required String email});

  Future<CaptchaResult> fetchCaptcha();

  Future<AuthOtpResult> requestOtp({
    required String email,
    required String captchaId,
    required String captchaAnswer,
  });

  Future<AuthOtpResult> resendOtp({required String email});

  Future<AuthOtpResult> verifyOtp({
    required String email,
    required String otp,
  });

  /// Legacy password path kept for mock offline demos only.
  Future<AuthCredentialsResult> validateCredentials({
    required String email,
    required String password,
  });
}
