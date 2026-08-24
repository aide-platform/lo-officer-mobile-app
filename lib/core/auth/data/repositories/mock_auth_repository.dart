import '../../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const String loEmail = 'liaison@test.com';
  static const String loPassword = 'liaison123';
  static const String loOtp = '123456';
  static const String loRole = 'Liaison Officer';
  static final Map<String, String> _otpStore = <String, String>{};

  @override
  Future<AuthCredentialsResult> validateCredentials({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == loEmail && password == loPassword) {
      return AuthCredentialsResult.success(
        email: loEmail,
        role: loRole,
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    }

    return const AuthCredentialsResult.failure(
      'Invalid email or password.',
    );
  }

  @override
  Future<AuthOtpResult> sendOtp({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@')) {
      return const AuthOtpResult.failure('Please enter a valid email address.');
    }

    if (normalizedEmail != loEmail) {
      return const AuthOtpResult.failure(
        'No matching LO account was found for this email.',
      );
    }

    _otpStore[normalizedEmail] = loOtp;

    return AuthOtpResult.success(
      email: normalizedEmail,
      message: 'OTP sent to $normalizedEmail. Demo OTP: $loOtp',
    );
  }

  @override
  Future<AuthOtpResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final normalizedEmail = email.trim().toLowerCase();
    final expectedOtp = _otpStore[normalizedEmail] ?? loOtp;
    if (otp.trim() == expectedOtp) {
      _otpStore.remove(normalizedEmail);
      return AuthOtpResult.success(
        email: normalizedEmail,
        message: 'OTP verified successfully.',
      );
    }

    return const AuthOtpResult.failure('Invalid OTP. Please try again.');
  }
}
