import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/routing/role_home_router.dart';
import 'package:liaison_officer/core/services/push_notification_service.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/core/themes/data/local/theme_settings_local_data_source.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/auth/landing_splash.dart';
import 'package:liaison_officer/features/auth/login_screen.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LoOfflineStore.init();
  } catch (e) {
    debugPrint('LoOfflineStore init skipped: $e');
  }
  await PushNotificationService.instance.initialize();
  AppDependencies.create();
  final themeCubit = await ThemeCubit.create();
  final session = await SessionStore.load();
  SystemChrome.setSystemUIOverlayStyle(
    themeCubit.state.mode == ThemeMode.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light,
  );
  runApp(LiaisonOfficerApp(
    themeCubit: themeCubit,
    initialSession: session,
  ));
}

class LiaisonOfficerApp extends StatelessWidget {
  const LiaisonOfficerApp({
    super.key,
    required this.themeCubit,
    this.initialSession,
  });

  final ThemeCubit themeCubit;
  final AuthSession? initialSession;

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
          SystemChrome.setSystemUIOverlayStyle(
            settings.mode == ThemeMode.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
          );
          return MaterialApp(
            title: 'Aero India LO',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(settings.palette, dark: false),
            darkTheme: AppTheme.themeFor(settings.palette, dark: true),
            themeMode: settings.mode,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(settings.font.scale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: SplashGate(initialSession: initialSession),
            routes: {
              '/login': (_) => const LoginScreen(),
            },
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
