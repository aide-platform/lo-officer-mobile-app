import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/session/session_store.dart';

import '../../../core/auth/data/repositories/mock_auth_repository.dart';
import '../../../core/auth/domain/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc({
    AuthRepository? repository,
    AuthSession? restoredSession,
  })  : _repository = repository ?? MockAuthRepository(),
        super(_initialState(restoredSession)) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionRestored>(_onSessionRestored);
  }

  final AuthRepository _repository;
  static const int _captchaExpirySeconds = 120;

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

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    if (DateTime.now().difference(event.captchaGeneratedAt).inSeconds >
        _captchaExpirySeconds) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Captcha expired. Please refresh.',
      ));
      return;
    }

    if (event.captcha.trim().toUpperCase() != event.generatedCaptcha) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Invalid captcha.',
      ));
      return;
    }

    final email = event.email.trim();
    final password = event.password;

    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Email and password are required.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    final result = await _repository.validateCredentials(
      email: email,
      password: password,
    );

    if (!result.success) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: result.errorMessage ?? 'Login failed.',
      ));
      return;
    }

    final expiresAt =
        result.expiresAt ?? DateTime.now().add(const Duration(days: 30));

    final session = AuthSession(
      email: result.email!,
      role: result.role ?? 'Liaison Officer',
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresAt: expiresAt,
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
