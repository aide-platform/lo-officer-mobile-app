import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/auth/login_screen.dart';
import 'package:liaison_officer/features/liaison_officer/bloc/lo_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/liaisonOfficerMain.dart';
import 'package:liaison_officer/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeCubit = await ThemeCubit.create();
  final session = await SessionStore.load();
  SystemChrome.setSystemUIOverlayStyle(
    themeCubit.state == ThemeMode.light
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
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          SystemChrome.setSystemUIOverlayStyle(
            themeMode == ThemeMode.light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
          );
          return MaterialApp(
            title: 'Liaison Officer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
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

/// Brief branded splash, then login or LO shell based on restored session.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, this.initialSession});

  final AuthSession? initialSession;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundColor : AppTheme.lightBackground;

    if (!_ready) {
      return Scaffold(
        backgroundColor: bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssetManager.splash,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: bg,
                child: Center(
                  child: Icon(
                    Icons.badge_outlined,
                    size: 72,
                    color: AppTheme.activeAccent,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withValues(alpha: 0.35),
                    bg.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Text(
                  'Liaison Officer',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final session = widget.initialSession;
    if (session != null && session.isValid) {
      return BlocProvider(
        create: (_) => LoBloc()..add(LoLoadRequested(session.email)),
        child: LiaisonOfficerScreen(email: session.email),
      );
    }

    return const LoginScreen();
  }
}
