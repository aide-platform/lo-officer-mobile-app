part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String captcha;
  final String generatedCaptcha;
  final DateTime captchaGeneratedAt;

  AuthLoginRequested({
    required this.email,
    required this.password,
    required this.captcha,
    required this.generatedCaptcha,
    required this.captchaGeneratedAt,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSessionRestored extends AuthEvent {
  final String email;
  final String role;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  AuthSessionRestored({
    required this.email,
    required this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });
}
