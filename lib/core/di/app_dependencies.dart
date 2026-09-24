import 'package:dio/dio.dart';
import 'package:liaison_officer/core/auth/data/repositories/dio_auth_repository.dart';
import 'package:liaison_officer/core/auth/data/repositories/mock_auth_repository.dart';
import 'package:liaison_officer/core/auth/domain/auth_repository.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/dio_provider.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_catering_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_nodal_lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_notifications_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/dio_org_rep_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_catering_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_nodal_lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_notifications_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_org_rep_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/catering_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/notifications_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/org_rep_repository.dart';

/// Simple app-wide dependency holder (constructor injection root).
class AppDependencies {
  AppDependencies._({
    required this.dio,
    required this.authRepository,
    required this.loPortalRepository,
    required this.orgRepRepository,
    required this.nodalLoRepository,
    required this.notificationsRepository,
    required this.cateringRepository,
  });

  final Dio dio;
  final AuthRepository authRepository;
  final LoPortalRepository loPortalRepository;
  final OrgRepRepository orgRepRepository;
  final NodalLoRepository nodalLoRepository;
  final NotificationsRepository notificationsRepository;
  final CateringRepository cateringRepository;

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
        orgRepRepository: MockOrgRepRepository(),
        nodalLoRepository: MockNodalLoRepository(),
        notificationsRepository: MockNotificationsRepository(),
        cateringRepository: MockCateringRepository(),
      );
    } else {
      deps = AppDependencies._(
        dio: client,
        authRepository: DioAuthRepository(dio: client),
        loPortalRepository: DioLoPortalRepository(dio: client),
        orgRepRepository: DioOrgRepRepository(dio: client),
        nodalLoRepository: DioNodalLoRepository(dio: client),
        notificationsRepository: DioNotificationsRepository(dio: client),
        cateringRepository: DioCateringRepository(dio: client),
      );
    }
    _instance = deps;
    return deps;
  }

  static void resetForTest([AppDependencies? deps]) {
    _instance = deps ?? create(forceMock: true);
  }
}
