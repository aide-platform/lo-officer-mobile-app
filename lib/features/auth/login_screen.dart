import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/routing/role_home_router.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:liaison_officer/widgets/components/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _captchaController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  late AnimationController _enter;
  late Animation<double> _enterFade;
  late Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _enterFade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthCaptchaRequested());
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _emailController.dispose();
    _captchaController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  void _sendOtp(AuthBlocState authState) {
    if (!_formKey.currentState!.validate()) return;
    final captchaId = authState.captchaId;
    if (captchaId == null || captchaId.isEmpty) {
      _showSnack('CAPTCHA not ready. Refresh and try again.');
      context.read<AuthBloc>().add(AuthCaptchaRequested());
      return;
    }
    context.read<AuthBloc>().add(
          AuthOtpRequested(
            email: _emailController.text.trim(),
            captchaId: captchaId,
            captchaAnswer: _captchaController.text.trim(),
          ),
        );
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthOtpVerified(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (ctx, authState) {
        if (authState.status == AuthStatus.otpSent) {
          setState(() => _otpSent = true);
          _showSnack(authState.errorMessage ?? 'OTP sent successfully.');
        } else if (authState.status == AuthStatus.authenticated) {
          navigateToRoleHome(context, authState);
        } else if (authState.status == AuthStatus.failure) {
          _showSnack(authState.errorMessage ?? 'Login failed');
        }
      },
      builder: (context, authState) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF070814), Color(0xFF1A1040)]
                    : const [Color(0xFFF4F0FF), Color(0xFFE8F1FF)],
              ),
            ),
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
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                onPressed: () =>
                                    context.read<ThemeCubit>().toggle(),
                                icon: Icon(
                                  isDark
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                ),
                              ),
                            ),
                            SafeAssetImage(
                              assetPath: AppAssetManager.logo,
                              width: 64,
                              height: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Committee Automation',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Liaison Officer Module',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            DecoratedBox(
                              decoration: AppTheme.glassCardDecoration(
                                radius: 24,
                                isDark: isDark,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
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
                                        prefixIcon:
                                            const Icon(Icons.email_outlined),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (v) =>
                                            v == null || v.isEmpty
                                                ? 'Email required'
                                                : null,
                                      ),
                                      const SizedBox(height: 12),
                                      if (!_otpSent) ...[
                                        _CaptchaBlock(
                                          imageBase64:
                                              authState.captchaImageBase64,
                                          controller: _captchaController,
                                          onRefresh: () => context
                                              .read<AuthBloc>()
                                              .add(AuthCaptchaRequested()),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        child: _otpSent
                                            ? CustomTextField(
                                                key: const ValueKey('otp'),
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
                                                maxLength: 10,
                                                validator: (v) => v == null ||
                                                        v.isEmpty
                                                    ? 'OTP required'
                                                    : null,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      if (_otpSent)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => context
                                                .read<AuthBloc>()
                                                .add(AuthOtpResendRequested(
                                                  email: _emailController.text
                                                      .trim(),
                                                )),
                                            child: const Text('Resend OTP'),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      GradientButton(
                                        label: _otpSent
                                            ? 'Verify & Sign In'
                                            : 'Send OTP',
                                        loading: authState.isLoading,
                                        onPressed: () => _otpSent
                                            ? _verifyOtp()
                                            : _sendOtp(authState),
                                      ),
                                      if (kDebugMode || ApiConfig.useMockApi) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          ApiConfig.useMockApi
                                              ? 'Mock: liaison@test.com / org@test.com / admin@aeroindia.gov.in · OTP 123456'
                                              : 'CAP: ${ApiConfig.baseUrl}',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
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
          ),
        );
      },
    );
  }
}

class _CaptchaBlock extends StatelessWidget {
  const _CaptchaBlock({
    required this.imageBase64,
    required this.controller,
    required this.onRefresh,
    required this.isDark,
  });

  final String? imageBase64;
  final TextEditingController controller;
  final VoidCallback onRefresh;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageBase64 == null || imageBase64!.isEmpty) {
      image = const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      try {
        final raw = imageBase64!.contains(',')
            ? imageBase64!.split(',').last
            : imageBase64!;
        final bytes = base64Decode(raw);
        image = Image.memory(bytes, height: 56, fit: BoxFit.contain);
      } catch (_) {
        image = const Text('CAPTCHA unavailable');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.borderStrokeColor
                        : AppTheme.lightBorder,
                  ),
                ),
                child: image,
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          labelText: 'CAPTCHA answer',
          textColor:
              isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          hintColor: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
          borderColor:
              isDark ? AppTheme.borderStrokeColor : AppTheme.lightBorder,
          backgroundColor:
              isDark ? AppTheme.cardBgColor : AppTheme.lightInputBg,
          prefixIcon: const Icon(Icons.security_outlined),
          validator: (v) =>
              v == null || v.isEmpty ? 'CAPTCHA required' : null,
        ),
      ],
    );
  }
}
