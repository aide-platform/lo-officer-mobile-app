import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/widgets/aero_india_logo.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Aero India 2027 splash — glowing logo on navy, then either the
/// sign-in CTA ([onContinue]) or a tricolour loading bar.
class LandingSplash extends StatelessWidget {
  const LandingSplash({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0C1A3A), Color(0xFF071D49)],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 0.85,
                colors: [Color(0x402F6BD8), Color(0x00071D49)],
              ),
            ),
          ),
          const CustomPaint(painter: _StarFieldPainter()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // The logo artwork has dark lettering, so it sits on a
                  // light badge to stay readable on navy.
                  Container(
                    width: 210,
                    height: 210,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.94),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6FA8FF,
                          ).withValues(alpha: 0.35),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const AeroIndiaLogo(size: 150),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Column(
                    children: [
                      const Text(
                        'Aero India 2027',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Liaison Officer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 16,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(
                    delay: 160.ms,
                    duration: AppMotion.page,
                    curve: Curves.easeOutCubic,
                  ),
                  const Spacer(flex: 4),
                  if (onContinue != null)
                    AppPressScale(
                      child: SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                            ),
                          ),
                          child: const Text(
                            'Continue to Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(
                      delay: 420.ms,
                      duration: AppMotion.medium,
                      curve: Curves.easeOutCubic,
                    )
                  else
                    Column(
                      children: [
                        const _TricolorLoadingBar(),
                        const SizedBox(height: 10),
                        Text(
                          'Loading…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Saffron | white | green in three equal solid segments, with a moving
/// white shimmer.
class _TricolorLoadingBar extends StatefulWidget {
  const _TricolorLoadingBar();

  @override
  State<_TricolorLoadingBar> createState() => _TricolorLoadingBarState();
}

class _TricolorLoadingBarState extends State<_TricolorLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ColoredBox(color: AppTheme.saffron)),
                Expanded(child: ColoredBox(color: Colors.white)),
                Expanded(child: ColoredBox(color: AppTheme.indiaGreen)),
              ],
            ),
            AnimatedBuilder(
              animation: _shimmer,
              builder: (context, child) => Align(
                alignment: Alignment(-1.6 + 3.2 * _shimmer.value, 0),
                child: child,
              ),
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint fixed star dots behind the splash content.
class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(27);
    final paint = Paint();
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      paint.color = Colors.white.withValues(
        alpha: 0.12 + rnd.nextDouble() * 0.28,
      );
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}
