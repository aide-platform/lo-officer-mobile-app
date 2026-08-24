/// Auth result for mock / remote credential checks.
class AuthCredentialsResult {
  final bool success;
  final String? email;
  final String? role;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthCredentialsResult.success({
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  }) : success = true, errorMessage = null;

  const AuthCredentialsResult.failure(this.errorMessage)
      : success = false,
        email = null,
        role = null,
        accessToken = null,
        refreshToken = null,
        expiresAt = null;
}

class AuthOtpResult {
  final bool success;
  final String? email;
  final String? message;

  const AuthOtpResult.success({
    required this.email,
    this.message = 'OTP sent successfully.',
  }) : success = true;

  const AuthOtpResult.failure(String message)
      : success = false,
        email = null,
        message = message;
}

abstract class AuthRepository {
  Future<AuthCredentialsResult> validateCredentials({
    required String email,
    required String password,
  });

  Future<AuthOtpResult> sendOtp({
    required String email,
  });

  Future<AuthOtpResult> verifyOtp({
    required String email,
    required String otp,
  });
}
