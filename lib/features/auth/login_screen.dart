import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/design/aero_brand_widgets.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/routing/role_home_router.dart';
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE8F2FC),
                        Color(0xFFF7FAFD),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppTheme.saffron.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.4),
                          AppTheme.indiaGreen.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          children: [
                            SafeAssetImage(
                              assetPath: AppAssetManager.aeroIndiaLogo,
                              width: 96,
                              height: 96,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AeroColors.navy
                                        .withValues(alpha: 0.10),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                              child: Form(
                                key: _formKey,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
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
                                          onRefreshCaptcha: () => context
                                              .read<AuthBloc>()
                                              .add(AuthCaptchaRequested()),
                                          onSend: () => _sendOtp(authState),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton.icon(
                              onPressed: () {
                                // Support contact — keep lightweight.
                                _showSnack(
                                  'Contact LO Committee support via your nodal officer.',
                                );
                              },
                              icon: Icon(
                                Icons.headset_mic_outlined,
                                size: 18,
                                color: AppTheme.royalBlue,
                              ),
                              label: Text(
                                'Need Help? Contact Support',
                                style: TextStyle(
                                  color: AppTheme.royalBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (kDebugMode || ApiConfig.useMockApi) ...[
                              const SizedBox(height: 8),
                              Text(
                                ApiConfig.useMockApi
                                    ? 'Mock: liaison@test.com / org@test.com / admin@aeroindia.gov.in · OTP 123456'
                                    : 'CAP: ${ApiConfig.baseUrl}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AeroColors.textMuted
                                      .withValues(alpha: 0.9),
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
  });

  final TextEditingController emailController;
  final TextEditingController captchaController;
  final String? captchaImageBase64;
  final bool loading;
  final VoidCallback onRefreshCaptcha;
  final VoidCallback onSend;

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
          'Verify your identity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AeroColors.navy,
          ),
        ),
        const SizedBox(height: 22),
        _FieldLabel('EMAIL ID / MOBILE NUMBER'),
        const SizedBox(height: 6),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AeroColors.navy),
          decoration: _inputDecoration(
            hint: 'you@example.com',
            prefix: Icons.mail_outline_rounded,
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Email required' : null,
        ),
        const SizedBox(height: 16),
        _FieldLabel('CAPTCHA'),
        const SizedBox(height: 6),
        _CaptchaBlock(
          imageBase64: captchaImageBase64,
          controller: captchaController,
          onRefresh: onRefreshCaptcha,
        ),
        const SizedBox(height: 22),
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
            color: AeroColors.navy,
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
                  color: AeroColors.navy,
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
                  color: AeroColors.navy,
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
                  style: TextStyle(fontSize: 13, color: AeroColors.textMuted),
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
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: AeroColors.textMuted,
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
    hintStyle: TextStyle(color: AeroColors.textMuted.withValues(alpha: 0.7)),
    prefixIcon: Icon(prefix, color: AeroColors.textMuted, size: 20),
    filled: true,
    fillColor: const Color(0xFFF5F8FC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AeroColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AeroColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
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
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.royalBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AeroColors.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
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
  });

  final String? imageBase64;
  final TextEditingController controller;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageBase64 == null || imageBase64!.isEmpty) {
      image = const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      try {
        final raw = imageBase64!.contains(',')
            ? imageBase64!.split(',').last
            : imageBase64!;
        final bytes = base64Decode(raw);
        image = Image.memory(bytes, height: 52, fit: BoxFit.contain);
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
              flex: 5,
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFF3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AeroColors.divider),
                ),
                child: image,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: TextFormField(
                controller: controller,
                style: const TextStyle(color: AeroColors.navy),
                decoration: _inputDecoration(
                  hint: 'ENTER CAPTCHA',
                  prefix: Icons.security_outlined,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'CAPTCHA required' : null,
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Refresh CAPTCHA',
              icon: Icon(Icons.refresh_rounded, color: AppTheme.royalBlue),
            ),
          ],
        ),
      ],
    );
  }
}
