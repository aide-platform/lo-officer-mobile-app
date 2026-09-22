part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  captchaReady,
  otpSent,
  authenticated,
  unauthenticated,
  failure,
}

class AuthBlocState {
  final AuthStatus status;
  final String? email;
  final String? role;
  final String? errorMessage;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? captchaId;
  final String? captchaImageBase64;
  final String? userId;

  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.email,
    this.role,
    this.errorMessage,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.captchaId,
    this.captchaImageBase64,
    this.userId,
  });

  AuthBlocState copyWith({
    AuthStatus? status,
    String? email,
    String? role,
    String? errorMessage,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? captchaId,
    String? captchaImageBase64,
    String? userId,
    bool clearError = false,
    bool clearCaptcha = false,
  }) =>
      AuthBlocState(
        status: status ?? this.status,
        email: email ?? this.email,
        role: role ?? this.role,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        expiresAt: expiresAt ?? this.expiresAt,
        captchaId: clearCaptcha ? null : (captchaId ?? this.captchaId),
        captchaImageBase64: clearCaptcha
            ? null
            : (captchaImageBase64 ?? this.captchaImageBase64),
        userId: userId ?? this.userId,
      );

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}
