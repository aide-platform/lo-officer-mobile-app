import '../../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const String loEmail = 'liaison@test.com';
  static const String loPassword = 'liaison123';
  static const String loRole = 'Liaison Officer';

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
}
