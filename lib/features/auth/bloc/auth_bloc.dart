import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/session/session_store.dart';

import '../../../core/auth/domain/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc({
    AuthRepository? repository,
    AuthSession? restoredSession,
  })  : _repository = repository ?? AppDependencies.instance.authRepository,
        super(_initialState(restoredSession)) {
    on<AuthCaptchaRequested>(_onCaptchaRequested);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpResendRequested>(_onOtpResend);
    on<AuthOtpVerified>(_onOtpVerified);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionRestored>(_onSessionRestored);
    on<AuthLoginRequested>(_onLoginRequested);
  }

  final AuthRepository _repository;

  static AuthBlocState _initialState(AuthSession? session) {
    if (session == null || !session.isValid) {
      return const AuthBlocState();
    }
    return AuthBlocState(
      status: AuthStatus.authenticated,
      email: session.email,
      role: session.role,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
  }

  Future<void> _onCaptchaRequested(
    AuthCaptchaRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _repository.fetchCaptcha();
    if (!result.success) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: result.message ?? 'Unable to load CAPTCHA.',
      ));
      return;
    }
    emit(state.copyWith(
      status: AuthStatus.captchaReady,
      captchaId: result.captchaId,
      captchaImageBase64: result.imageBase64,
      clearError: true,
    ));
  }

  Future<void> _onOtpRequested(
    AuthOtpRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty || !email.contains('@')) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Please enter a valid email address.',
      ));
      return;
    }
    if (event.captchaId.isEmpty || event.captchaAnswer.trim().isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Please complete the CAPTCHA.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      email: email,
      clearError: true,
    ));

    await _repository.checkEmail(email: email);
    final result = await _repository.requestOtp(
      email: email,
      captchaId: event.captchaId,
      captchaAnswer: event.captchaAnswer,
    );

    if (!result.success) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        email: email,
        errorMessage: result.message ?? 'Unable to send OTP.',
      ));
      add(AuthCaptchaRequested());
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.otpSent,
      email: result.email ?? email,
      errorMessage: result.message ?? 'OTP sent successfully.',
    ));
  }

  Future<void> _onOtpResend(
    AuthOtpResendRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _repository.resendOtp(email: event.email);
    emit(state.copyWith(
      status: result.success ? AuthStatus.otpSent : AuthStatus.failure,
      email: event.email,
      errorMessage: result.message,
    ));
  }

  Future<void> _onOtpVerified(
    AuthOtpVerified event,
    Emitter<AuthBlocState> emit,
  ) async {
    final email = event.email.trim();
    final otp = event.otp.trim();

    if (email.isEmpty || otp.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Please enter the OTP sent to your email.',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.loading,
      email: email,
      clearError: true,
    ));

    final otpResult = await _repository.verifyOtp(email: email, otp: otp);
    if (!otpResult.success ||
        otpResult.accessToken == null ||
        otpResult.accessToken!.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        email: email,
        errorMessage: otpResult.message ?? 'Invalid OTP.',
      ));
      return;
    }

    final session = AuthSession(
      email: otpResult.email ?? email,
      role: otpResult.role ?? 'Liaison Officer',
      accessToken: otpResult.accessToken,
      expiresAt: otpResult.expiresAt ??
          DateTime.now().add(const Duration(hours: 8)),
    );
    await SessionStore.save(session);

    emit(state.copyWith(
      status: AuthStatus.authenticated,
      email: session.email,
      role: session.role,
      accessToken: session.accessToken,
      expiresAt: session.expiresAt,
      userId: otpResult.userId,
      clearError: true,
      clearCaptcha: true,
    ));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _repository.validateCredentials(
      email: event.email,
      password: event.password,
    );
    if (!result.success) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: result.errorMessage ?? 'Login failed.',
      ));
      return;
    }
    final session = AuthSession(
      email: result.email!,
      role: result.role ?? 'Liaison Officer',
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresAt:
          result.expiresAt ?? DateTime.now().add(const Duration(days: 30)),
    );
    await SessionStore.save(session);
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      email: session.email,
      role: session.role,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
      clearError: true,
    ));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    await SessionStore.clear();
    emit(const AuthBlocState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onSessionRestored(
    AuthSessionRestored event,
    Emitter<AuthBlocState> emit,
  ) async {
    final session = AuthSession(
      email: event.email,
      role: event.role,
      accessToken: event.accessToken,
      refreshToken: event.refreshToken,
      expiresAt: event.expiresAt,
    );
    if (!session.isValid) {
      await SessionStore.clear();
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
      return;
    }
    await SessionStore.save(session);
    emit(AuthBlocState(
      status: AuthStatus.authenticated,
      email: session.email,
      role: session.role,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    ));
  }
}
