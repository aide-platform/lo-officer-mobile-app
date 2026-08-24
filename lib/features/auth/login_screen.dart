import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/app_colors.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/bloc/lo_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/liaisonOfficerMain.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:liaison_officer/utils/captcha_painter.dart';
import 'package:liaison_officer/widgets/components/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _otpController = TextEditingController();

  late String _generatedCaptcha;
  late DateTime _captchaGeneratedAt;
  static const int _captchaExpirySeconds = 120;
  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;

  int _failedAttempts = 0;
  int _lockMultiplier = 1;
  DateTime? _lockoutUntil;
  Timer? _captchaTimer;
  Timer? _lockoutTicker;
  late FocusNode _captchaFocusNode;
  bool _otpSent = false;

  late AnimationController _bgDrift;
  late AnimationController _enter;
  late Animation<double> _enterFade;
  late Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    _generatedCaptcha = _generateCaptcha();
    _captchaGeneratedAt = DateTime.now();

    _captchaFocusNode = FocusNode();

    _bgDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _enterFade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();
    _startCaptchaTimer();
  }

  @override
  void dispose() {
    _bgDrift.dispose();
    _enter.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _otpController.dispose();
    _captchaTimer?.cancel();
    _lockoutTicker?.cancel();
    _captchaFocusNode.dispose();
    super.dispose();
  }

  String _generateCaptcha() {
    const chars = 'A0B1C2D3E4F5G6H7I8J9K0L1M2N3O4P5Q6R7S8T9U9V8W7X6Y5Z4';
    final rand = Random();
    return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _refreshCaptcha() {
    setState(() {
      _generatedCaptcha = _generateCaptcha();
      _captchaGeneratedAt = DateTime.now();
    });
    _captchaController.clear();
  }

  void _startCaptchaTimer() {
    _captchaTimer?.cancel();
    _captchaTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      if (mounted && !_isLocked) _refreshCaptcha();
    });
  }

  void _startLockoutTicker() {
    _lockoutTicker?.cancel();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isLocked) {
        _lockoutTicker?.cancel();
        _lockoutTicker = null;
        setState(() => _lockoutUntil = null);
        return;
      }
      setState(() {});
    });
  }


  bool get _isLocked =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  int get _lockRemainingSeconds => _lockoutUntil == null
      ? 0
      : _lockoutUntil!.difference(DateTime.now()).inSeconds.clamp(0, 9999);

  double get _difficultyFactor {
    if (_failedAttempts <= 2) return 1.0;
    if (_failedAttempts <= 5) return 1.5;
    return 2.0;
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts % _maxAttempts == 0) {
      final seconds = _lockoutSeconds * _lockMultiplier;
      _lockMultiplier *= 2;
      _lockoutUntil = DateTime.now().add(Duration(seconds: seconds));
      _startLockoutTicker();
      _showSnack('Too many failed attempts. Try again in $seconds seconds.');
    }
    _refreshCaptcha();
  }

  void _resetAttempts() {
    _failedAttempts = 0;
    _lockMultiplier = 1;
    _lockoutUntil = null;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  Future<void> _login() async {
    if (_isLocked) {
      _showSnack(
          'Account locked. Try again in $_lockRemainingSeconds seconds.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (DateTime.now().difference(_captchaGeneratedAt).inSeconds >
        _captchaExpirySeconds) {
      _showSnack('Captcha expired. Please refresh.');
      _refreshCaptcha();
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            captcha: _captchaController.text.trim().toUpperCase(),
            generatedCaptcha: _generatedCaptcha,
            captchaGeneratedAt: _captchaGeneratedAt,
          ),
        );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthOtpRequested(email: _emailController.text.trim()),
    );
  }

  Future<void> _verifyOtpAndLogin() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthOtpVerified(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      ),
    );
  }

  void _navigateToLo(AuthBlocState authState) {
    if (!mounted) return;
    final email = authState.email ?? '';
    _resetAttempts();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => LoBloc()..add(LoLoadRequested(email)),
          child: LiaisonOfficerScreen(email: email),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (ctx, authState) {
        if (authState.status == AuthStatus.otpSent) {
          setState(() => _otpSent = true);
          _showSnack(authState.errorMessage ?? 'OTP sent successfully.');
        } else if (authState.status == AuthStatus.authenticated) {
          _navigateToLo(authState);
        } else if (authState.status == AuthStatus.failure) {
          _showSnack(authState.errorMessage ?? 'Login failed');
          _handleFailedAttempt();
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bgDrift,
          // Form (incl. captcha) is a stable child — not rebuilt every bg frame.
          child: SafeArea(
            child: FadeTransition(
              opacity: _enterFade,
              child: SlideTransition(
                position: _enterSlide,
                child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SafeAssetImage(
                                  assetPath: AppAssetManager.logo,
                                  width: 64,
                                  height: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Liaison Officer',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: 56,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: isDark
                                        ? AppTheme.purpleGradient
                                        : AppTheme.lightPurpleGradient,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                DecoratedBox(
                                  decoration: AppTheme.glassCardDecoration(
                                    radius: 24,
                                    isDark: isDark,
                                  ).copyWith(
                                    boxShadow: AppTheme.glowShadow(
                                      AppTheme.activeAccent,
                                      opacity: isDark ? 0.18 : 0.1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 24, 24, 24),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          CustomTextField(
                                            controller: _emailController,
                                            labelText: 'Email',
                                            textColor: isDark
                                                ? AppTheme.textPrimary
                                                : AppTheme.lightTextPrimary,
                                            hintColor: isDark
                                                ? AppTheme.textMuted
                                                : AppTheme.lightTextMuted,
                                            borderColor: isDark
                                                ? AppTheme.borderStrokeColor
                                                : AppTheme.lightBorder,
                                            backgroundColor: isDark
                                                ? AppTheme.cardBgColor
                                                : AppTheme.lightInputBg,
                                            prefixIcon: const Icon(
                                                Icons.email_outlined),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (v) =>
                                                v == null || v.isEmpty
                                                    ? 'Email required'
                                                    : null,
                                          ),
                                          const SizedBox(height: 12),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: _otpSent
                                                ? SizedBox(
                                                    key: const ValueKey(
                                                        'otp-field'),
                                                    child: CustomTextField(
                                                      controller: _otpController,
                                                      labelText: 'OTP',
                                                      textColor: isDark
                                                          ? AppTheme.textPrimary
                                                          : AppTheme.lightTextPrimary,
                                                      hintColor: isDark
                                                          ? AppTheme.textMuted
                                                          : AppTheme.lightTextMuted,
                                                      borderColor: isDark
                                                          ? AppTheme.borderStrokeColor
                                                          : AppTheme.lightBorder,
                                                      backgroundColor: isDark
                                                          ? AppTheme.cardBgColor
                                                          : AppTheme.lightInputBg,
                                                      prefixIcon: const Icon(
                                                          Icons.verified_user_outlined),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      maxLength: 6,
                                                      validator: (v) =>
                                                          v == null || v.isEmpty
                                                              ? 'OTP required'
                                                              : null,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(
                                                    key: ValueKey('otp-empty')),
                                          ),
                                          const SizedBox(height: 20),
                                          BlocBuilder<AuthBloc, AuthBlocState>(
                                            builder: (ctx, authState) {
                                              final loading =
                                                  authState.isLoading;
                                              final buttonLabel = _otpSent
                                                  ? 'Verify & Sign In'
                                                  : 'Send OTP';
                                              return SizedBox(
                                                height: 52,
                                                width: double.infinity,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    gradient: isDark
                                                        ? AppTheme
                                                            .purpleGradient
                                                        : AppTheme
                                                            .lightPurpleGradient,
                                                    boxShadow:
                                                        AppTheme.glowShadow(
                                                      AppTheme.activeAccent,
                                                      opacity: 0.35,
                                                    ),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      onTap: loading || _isLocked
                                                          ? null
                                                          : (_otpSent
                                                              ? _verifyOtpAndLogin
                                                              : _sendOtp),
                                                      child: Center(
                                                        child: loading
                                                            ? const SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              )
                                                            : Text(
                                                                buttonLabel,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          if (_otpSent)
                                            TextButton(
                                              onPressed: () {
                                                setState(() => _otpSent = false);
                                                _otpController.clear();
                                                _sendOtp();
                                              },
                                              child: const Text('Resend OTP'),
                                            ),
                                          if (kDebugMode)
                                            Text(
                                              'Demo LO: liaison@test.com / liaison123\n'
                                              'Demo OTP: 123456',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: (isDark
                                                        ? AppTheme.textMuted
                                                        : AppTheme
                                                            .lightTextMuted)
                                                    .withValues(alpha: 0.9),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          builder: (context, formChild) {
            final t = _bgDrift.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssetManager.mainBg3,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + t * 0.4, -1),
                        end: Alignment(1.0 - t * 0.3, 1),
                        colors: isDark
                            ? const [
                                AppTheme.backgroundColor,
                                Color(0xFF1A0B2E),
                                AppTheme.purpleAccent,
                              ]
                            : const [
                                AppTheme.lightBackground,
                                Color(0xFFE8D9FF),
                                AppTheme.purpleAccent,
                              ],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              AppTheme.backgroundColor.withValues(alpha: 0.72),
                              AppTheme.backgroundColor.withValues(alpha: 0.88),
                              AppTheme.backgroundColor.withValues(alpha: 0.95),
                            ]
                          : [
                              AppTheme.lightBackground.withValues(alpha: 0.55),
                              AppTheme.lightBackground.withValues(alpha: 0.82),
                              AppTheme.lightBackground.withValues(alpha: 0.94),
                            ],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 4,
                  right: 8,
                  child: BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, mode) {
                      final dark = mode == ThemeMode.dark;
                      return IconButton(
                        tooltip: dark ? 'Light mode' : 'Dark mode',
                        onPressed: () => context.read<ThemeCubit>().toggle(),
                        icon: Icon(
                          dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: dark
                              ? AppTheme.activeAccent
                              : AppTheme.purpleAccent,
                        ),
                      );
                    },
                  ),
                ),
                IgnorePointer(
                  child: Stack(
                    children: [
                      Positioned(
                        left: -80 + t * 40,
                        top: -40 + t * 60,
                        child: _LoginOrb(
                          size: 280,
                          color: AppTheme.activeAccent.withValues(alpha: 0.28),
                        ),
                      ),
                      Positioned(
                        right: -60 - t * 30,
                        bottom: 80 + t * 40,
                        child: _LoginOrb(
                          size: 220,
                          color: AppTheme.blueAccent.withValues(alpha: 0.22),
                        ),
                      ),
                    ],
                  ),
                ),
                formChild!,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _LoginOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
