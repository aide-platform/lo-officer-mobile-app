import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/routing/role_home_router.dart';
import 'package:liaison_officer/core/security/device_integrity.dart';
import 'package:liaison_officer/core/services/fcm_device_registrar.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/push_notification_service.dart';
import 'package:liaison_officer/firebase_options.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/core/themes/data/local/theme_settings_local_data_source.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/auth/landing_splash.dart';
import 'package:liaison_officer/features/auth/login_screen.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await LoFirebaseMonitor.instance.start();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  try {
    await LoOfflineStore.init();
  } catch (e) {
    debugPrint('LoOfflineStore init skipped: $e');
  }
  PushNotificationService.instance.onToken = (_) {
    FcmDeviceRegistrar.registerIfSignedIn();
  };
  try {
    await PushNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Push init skipped: $e');
  }
  AppDependencies.create();
  final themeCubit = await ThemeCubit.create();
  AuthSession? session;
  try {
    session = await SessionStore.load();
  } catch (e) {
    // Corrupt stored session: start signed out instead of a blank screen.
    debugPrint('Session restore failed: $e');
  }
  try {
    await FcmDeviceRegistrar.registerIfSignedIn();
  } catch (e) {
    debugPrint('FCM register skipped: $e');
  }
  final integrity = await DeviceIntegrity.check();
  runApp(
    LiaisonOfficerApp(
      themeCubit: themeCubit,
      initialSession: session,
      integrity: integrity,
    ),
  );
}

class LiaisonOfficerApp extends StatelessWidget {
  const LiaisonOfficerApp({
    super.key,
    required this.themeCubit,
    this.initialSession,
    this.integrity = const DeviceIntegrityResult(),
  });

  final ThemeCubit themeCubit;
  final AuthSession? initialSession;
  final DeviceIntegrityResult integrity;

  @override
  Widget build(BuildContext context) {
    final authBloc = AuthBloc(restoredSession: initialSession);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Aero India LO',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: LoContactActions.messengerKey,
            theme: AppTheme.themeFor(settings.palette, dark: false),
            darkTheme: AppTheme.themeFor(settings.palette, dark: true),
            themeMode: settings.mode,
            builder: (context, child) {
              SystemChrome.setSystemUIOverlayStyle(
                Theme.of(context).brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
              );
              // Android 15+ draws apps edge-to-edge, so screens, sheets and
              // bottom buttons ended up under the system navigation buttons.
              // Keep the whole app above them; the strip below is painted in
              // the page colour so it does not look like a gap.
              return DeviceIntegrityGate(
                result: integrity,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    // Builder: read the MediaQuery SafeArea already trimmed,
                    // or the bottom inset would be added back.
                    child: Builder(
                      builder: (inner) => MediaQuery(
                        data: MediaQuery.of(inner).copyWith(
                          textScaler: TextScaler.linear(settings.font.scale),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              );
            },
            home: SplashGate(initialSession: initialSession),
            routes: {'/login': (_) => const LoginScreen()},
          );
        },
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, this.initialSession});

  final AuthSession? initialSession;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _continueToLogin = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.initialSession;
    if (session != null && session.isValid) {
      return RoleHomeRouter(email: session.email, role: session.role);
    }

    if (_continueToLogin) {
      return const LoginScreen();
    }

    return LandingSplash(
      onContinue: () => setState(() => _continueToLogin = true),
    );
  }
}
