class AuthSession {
  final String email;
  final String role;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthSession({
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  bool get isValid {
    if (email.trim().isEmpty) return false;
    if (accessToken == null || accessToken!.trim().isEmpty) return false;
    if (expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  AuthSession copyWith({
    String? email,
    String? role,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      email: email ?? this.email,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
