part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthBlocState {
  final AuthStatus status;
  final String? email;
  final String? role;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.email,
    this.role,
    this.errorMessage,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  AuthBlocState copyWith({
    AuthStatus? status,
    String? email,
    String? role,
    String? errorMessage,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool clearError = false,
  }) =>
      AuthBlocState(
        status: status ?? this.status,
        email: email ?? this.email,
        role: role ?? this.role,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}
