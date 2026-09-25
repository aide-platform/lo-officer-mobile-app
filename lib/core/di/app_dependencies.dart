import 'package:dio/dio.dart';
import 'package:liaison_officer/core/auth/data/repositories/dio_auth_repository.dart';
import 'package:liaison_officer/core/auth/data/repositories/mock_auth_repository.dart';
import 'package:liaison_officer/core/auth/domain/auth_repository.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_notifications_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_notifications_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/notifications_repository.dart';

/// Simple app-wide dependency holder (constructor injection root).
class AppDependencies {
  AppDependencies._({
    required this.dio,
    required this.authRepository,
    required this.loPortalRepository,
    required this.notificationsRepository,
  });

  final Dio dio;
  final AuthRepository authRepository;
  final LoPortalRepository loPortalRepository;
  final NotificationsRepository notificationsRepository;

  static AppDependencies? _instance;

  static AppDependencies get instance {
    final existing = _instance;
    if (existing != null) return existing;
    return _instance = create();
  }

  static AppDependencies create({Dio? dio, bool? forceMock}) {
    final client = dio ?? createDio();
    final useMock = forceMock ?? ApiConfig.useMockApi;
    late final AppDependencies deps;
    if (useMock) {
      deps = AppDependencies._(
        dio: client,
        authRepository: MockAuthRepository(),
        loPortalRepository: MockLoPortalRepository(),
        notificationsRepository: MockNotificationsRepository(),
      );
    } else {
      deps = AppDependencies._(
        dio: client,
        authRepository: DioAuthRepository(dio: client),
        loPortalRepository: DioLoPortalRepository(dio: client),
        notificationsRepository: DioNotificationsRepository(dio: client),
      );
    }
    _instance = deps;
    return deps;
  }

  static void resetForTest([AppDependencies? deps]) {
    _instance = deps ?? create(forceMock: true);
  }
}
