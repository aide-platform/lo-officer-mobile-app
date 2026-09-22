import '../../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const String loEmail = 'liaison@test.com';
  static const String orgEmail = 'org@test.com';
  static const String adminEmail = 'admin@aeroindia.gov.in';
  static const String loPassword = 'liaison123';
  static const String loOtp = '123456';
  static const String loRole = 'Liaison Officer';
  static const String orgRole = 'Organisation Representative';
  static const String nodalRole = 'LO Committee Nodal Officer';

  String? _captchaId = 'mock-captcha-id';

  @override
  Future<void> checkEmail({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<CaptchaResult> fetchCaptcha() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _captchaId = 'mock-captcha-${DateTime.now().millisecondsSinceEpoch}';
    // 1x1 transparent PNG
    const png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    return CaptchaResult.success(
      captchaId: _captchaId!,
      imageBase64: png,
    );
  }

  @override
  Future<AuthOtpResult> requestOtp({
    required String email,
    required String captchaId,
    required String captchaAnswer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@')) {
      return const AuthOtpResult.failure('Please enter a valid email address.');
    }
    if (captchaAnswer.trim().isEmpty) {
      return const AuthOtpResult.failure('CAPTCHA answer is required.');
    }
    return AuthOtpResult.success(
      email: normalized,
      message: 'OTP sent. Demo OTP: $loOtp',
    );
  }

  @override
  Future<AuthOtpResult> resendOtp({required String email}) async {
    return AuthOtpResult.success(
      email: email.trim().toLowerCase(),
      message: 'OTP resent. Demo OTP: $loOtp',
    );
  }

  @override
  Future<AuthOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final normalized = email.trim().toLowerCase();
    if (otp.trim() != loOtp) {
      return const AuthOtpResult.failure('Invalid OTP. Please try again.');
    }
    final role = _roleFor(normalized);
    return AuthOtpResult.success(
      email: normalized,
      message: 'OTP verified successfully.',
      role: role,
      accessToken: 'mock_jwt_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      userId: 'mock-user',
    );
  }

  @override
  Future<AuthCredentialsResult> validateCredentials({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final normalized = email.trim().toLowerCase();
    if (normalized == loEmail && password == loPassword) {
      return AuthCredentialsResult.success(
        email: loEmail,
        role: loRole,
        accessToken: 'mock_access_token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }
    return const AuthCredentialsResult.failure('Invalid email or password.');
  }

  String _roleFor(String email) {
    if (email == adminEmail) return nodalRole;
    if (email == orgEmail) return orgRole;
    return loRole;
  }
}
