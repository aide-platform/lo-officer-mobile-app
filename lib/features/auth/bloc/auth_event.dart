part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthCaptchaRequested extends AuthEvent {}

class AuthOtpRequested extends AuthEvent {
  final String email;
  final String captchaId;
  final String captchaAnswer;

  AuthOtpRequested({
    required this.email,
    required this.captchaId,
    required this.captchaAnswer,
  });
}

class AuthOtpResendRequested extends AuthEvent {
  final String email;

  AuthOtpResendRequested({required this.email});
}

class AuthOtpVerified extends AuthEvent {
  final String email;
  final String otp;

  AuthOtpVerified({
    required this.email,
    required this.otp,
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

/// Kept for offline mock password demos.
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
