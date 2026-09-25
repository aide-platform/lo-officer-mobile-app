import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/routing/role_home_router.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// OTP email login — Aero India portal style (no biometric / SSO).
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
  final _otpDigits = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  late AnimationController _enter;
  late Animation<double> _enterFade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _enterFade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _enter.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthCaptchaRequested());
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _enter.dispose();
    _emailController.dispose();
    _captchaController.dispose();
    for (final c in _otpDigits) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _otpDigits.map((c) => c.text).join();

  String _maskedEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at);
    final keep = local.length <= 2 ? 1 : 2;
    return '${local.substring(0, keep)}${'*' * (local.length - keep)}$domain';
  }

  void _startResendCountdown([int seconds = 45]) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  void _goBackToEmail() {
    setState(() {
      _otpSent = false;
      for (final c in _otpDigits) {
        c.clear();
      }
    });
    _resendTimer?.cancel();
    _resendSeconds = 0;
    _captchaController.clear();
    context.read<AuthBloc>().add(AuthCaptchaRequested());
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
    final otp = _otpValue;
    if (otp.length != 6) {
      _showSnack('Enter the 6-digit OTP.');
      return;
    }
    context.read<AuthBloc>().add(
          AuthOtpVerified(
            email: _emailController.text.trim(),
            otp: otp,
          ),
        );
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < 6; i++) {
        _otpDigits[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, 5);
      _otpFocus[next].requestFocus();
      setState(() {});
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _otpFocus[index + 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (ctx, authState) {
        if (authState.status == AuthStatus.otpSent) {
          setState(() => _otpSent = true);
          _startResendCountdown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _otpFocus.first.requestFocus();
          });
          _showSnack(authState.errorMessage ?? 'OTP sent successfully.');
        } else if (authState.status == AuthStatus.authenticated) {
          navigateToRoleHome(context, authState);
        } else if (authState.status == AuthStatus.failure) {
          _showSnack(authState.errorMessage ?? 'Login failed');
        }
      },
      builder: (context, authState) {
        return Scaffold(
          body: FadeTransition(
            opacity: _enterFade,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeAssetImage(
                  assetPath: AppAssetManager.mainBg3,
                  fit: BoxFit.cover,
                  fallback: const ColoredBox(color: AppTheme.navy),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          children: [
                            SafeAssetImage(
                              assetPath: AppAssetManager.aeroIndiaLogo,
                              width: 112,
                              height: 112,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.xl),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.navy
                                        .withValues(alpha: 0.12),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                AppSpacing.xl,
                                AppSpacing.xl,
                                AppSpacing.xl,
                              ),
                              child: Form(
                                key: _formKey,
                                child: AnimatedSwitcher(
                                  duration: AppMotion.tab,
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _otpSent
                                      ? _OtpStep(
                                          key: const ValueKey('otp'),
                                          email: _maskedEmail(
                                            _emailController.text.trim(),
                                          ),
                                          digitControllers: _otpDigits,
                                          focusNodes: _otpFocus,
                                          loading: authState.isLoading,
                                          resendSeconds: _resendSeconds,
                                          onOtpChanged: _onOtpChanged,
                                          onBack: _goBackToEmail,
                                          onVerify: _verifyOtp,
                                          onResend: () {
                                            context.read<AuthBloc>().add(
                                                  AuthOtpResendRequested(
                                                    email: _emailController
                                                        .text
                                                        .trim(),
                                                  ),
                                                );
                                            _startResendCountdown();
                                          },
                                        )
                                      : _EmailStep(
                                          key: const ValueKey('email'),
                                          emailController: _emailController,
                                          captchaController:
                                              _captchaController,
                                          captchaImageBase64:
                                              authState.captchaImageBase64,
                                          loading: authState.isLoading,
                                          failureMessage:
                                              authState.status ==
                                                      AuthStatus.failure
                                                  ? authState.errorMessage
                                                  : null,
                                          onRefreshCaptcha: () => context
                                              .read<AuthBloc>()
                                              .add(AuthCaptchaRequested()),
                                          onSend: () => _sendOtp(authState),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextButton.icon(
                              onPressed: () {
                                _showSnack(
                                  'Contact Liaison Officer support for login help.',
                                );
                              },
                              icon: Icon(
                                Icons.headset_mic_outlined,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              label: Text(
                                'Need Help? Contact Support',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (kDebugMode || ApiConfig.useMockApi) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                ApiConfig.useMockApi
                                    ? 'Mock: liaison@test.com · OTP 123456'
                                    : 'CAP: ${ApiConfig.baseUrl}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.emailController,
    required this.captchaController,
    required this.captchaImageBase64,
    required this.loading,
    required this.onRefreshCaptcha,
    required this.onSend,
    this.failureMessage,
  });

  final TextEditingController emailController;
  final TextEditingController captchaController;
  final String? captchaImageBase64;
  final bool loading;
  final VoidCallback onRefreshCaptcha;
  final VoidCallback onSend;
  final String? failureMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WELCOME BACK',
          style: textTheme.labelSmall?.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppTheme.royalBlue,
              ) ??
              const TextStyle(
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppTheme.royalBlue,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Verify your identity',
          style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ) ??
              const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
        ),
        if (failureMessage != null && failureMessage!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.pinkAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: AppTheme.pinkAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: AppTheme.pinkAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    failureMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.navy,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRefreshCaptcha,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _FieldLabel('EMAIL ID / MOBILE NUMBER'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.navy),
          decoration: _inputDecoration(
            hint: 'you@example.com',
            prefix: Icons.mail_outline_rounded,
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Email required' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _FieldLabel('CAPTCHA'),
        const SizedBox(height: AppSpacing.xs),
        _CaptchaBlock(
          imageBase64: captchaImageBase64,
          controller: captchaController,
          onRefresh: onRefreshCaptcha,
          loading: loading && captchaImageBase64 == null,
        ),
        const SizedBox(height: AppSpacing.xl),
        _PrimaryButton(
          label: 'Send OTP',
          loading: loading,
          enabled: !loading,
          onPressed: onSend,
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.email,
    required this.digitControllers,
    required this.focusNodes,
    required this.loading,
    required this.resendSeconds,
    required this.onOtpChanged,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  final String email;
  final List<TextEditingController> digitControllers;
  final List<FocusNode> focusNodes;
  final bool loading;
  final int resendSeconds;
  final void Function(int index, String value) onOtpChanged;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WELCOME BACK',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: AppTheme.royalBlue,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A 6-digit code has been sent to $email.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppTheme.navy,
                ),
              ),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.royalBlue,
                ),
                child: const Text('← Wrong email? Go back'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel('ONE-TIME PASSWORD'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: digitControllers[i],
                focusNode: focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.royalBlue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppTheme.royalBlue.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppTheme.royalBlue, width: 2),
                  ),
                ),
                onChanged: (v) {
                  if (v.isEmpty && i > 0) {
                    focusNodes[i - 1].requestFocus();
                  }
                  onOtpChanged(i, v);
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'Verify & Sign In',
          loading: loading,
          enabled: !loading,
          onPressed: onVerify,
        ),
        const SizedBox(height: 14),
        Center(
          child: resendSeconds > 0
              ? Text(
                  "Resend OTP in ${resendSeconds}s",
                  style: TextStyle(fontSize: 13, color: AppTheme.lightTextMuted),
                )
              : TextButton(
                  onPressed: loading ? null : onResend,
                  child: const Text('Resend OTP'),
                ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTextMuted,
          ) ??
          const TextStyle(
            fontSize: 11,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTextMuted,
          ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData prefix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: AppTheme.lightTextMuted.withValues(alpha: 0.7),
    ),
    prefixIcon: Icon(prefix, color: AppTheme.lightTextMuted, size: 20),
    filled: true,
    fillColor: AppTheme.lightInputBg,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: AppTheme.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: AppTheme.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: AppTheme.royalBlue, width: 1.5),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      enabled: enabled && !loading,
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.royalBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.lightBorder,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CaptchaBlock extends StatelessWidget {
  const _CaptchaBlock({
    required this.imageBase64,
    required this.controller,
    required this.onRefresh,
    this.loading = false,
  });

  final String? imageBase64;
  final TextEditingController controller;
  final VoidCallback onRefresh;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (loading || imageBase64 == null || imageBase64!.isEmpty) {
      image = const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.royalBlue,
          ),
        ),
      );
    } else {
      try {
        final raw = imageBase64!.contains(',')
            ? imageBase64!.split(',').last
            : imageBase64!;
        final bytes = base64Decode(raw);
        image = Image.memory(bytes, height: 52, fit: BoxFit.contain);
      } catch (_) {
        image = const Text(
          'CAPTCHA unavailable — tap refresh',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.lightTextMuted),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 72,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFF3),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppTheme.lightBorder),
                ),
                child: image,
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh CAPTCHA',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.royalBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: AppTheme.navy),
          decoration: _inputDecoration(
            hint: 'ENTER CAPTCHA',
            prefix: Icons.security_outlined,
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'CAPTCHA required' : null,
        ),
      ],
    );
  }
}
