import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Aero India 2027 landing — logos, event copy, and a rising runway jet.
class LandingSplash extends StatelessWidget {
  const LandingSplash({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071433),
              Color(0xFF0E2A66),
              Color(0xFF1E4E96),
              Color(0xFF4C93C9),
            ],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    SafeAssetImage(
                      assetPath: AppAssetManager.modLogoWhite,
                      height: 72,
                      fit: BoxFit.contain,
                      fallback: Text(
                        'MINISTRY OF DEFENCE',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate().fadeIn(
                      duration: AppMotion.page,
                      curve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SafeAssetImage(
                      assetPath: AppAssetManager.aeroIndiaLogo,
                      height: 88,
                      fit: BoxFit.contain,
                      fallback: Icon(
                        Icons.flight,
                        color: Colors.white70,
                        size: 64,
                      ),
                    ).animate().fadeIn(
                      delay: 80.ms,
                      duration: AppMotion.page,
                      curve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      children: [
                        Text(
                          'Aero India 2027',
                          textAlign: TextAlign.center,
                          style:
                              textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "Asia's premier aerospace and defence exhibition — the official event management portal for organising committees.",
                          textAlign: TextAlign.center,
                          style:
                              textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.35,
                              ) ??
                              TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 14,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ).animate().fadeIn(
                      delay: 160.ms,
                      duration: AppMotion.page,
                      curve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: '8 – 17 February 2027',
                        ),
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: 'Air Force Station\nYelahanka, Bengaluru',
                        ),
                      ],
                    ).animate().fadeIn(
                      delay: 240.ms,
                      duration: AppMotion.page,
                      curve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _RisingJet(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xCC0E2A66),
                          Color(0x000E2A66),
                          Color(0x66000000),
                        ],
                        stops: [0, 0.28, 1],
                      ),
                    ),
                  ),
                  if (onContinue != null)
                    Positioned(
                      left: AppSpacing.xl,
                      right: AppSpacing.xl,
                      bottom: AppSpacing.xl,
                      child:
                          SafeArea(
                            top: false,
                            child: AppPressScale(
                              child: SizedBox(
                                height: 52,
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: onContinue,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.royalBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.lg,
                                      ),
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
                            ),
                          ).animate().fadeIn(
                            delay: 420.ms,
                            duration: AppMotion.medium,
                            curve: Curves.easeOutCubic,
                          ),
                    )
                  else
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 36),
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RisingJet extends StatelessWidget {
  const _RisingJet();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
          AppAssetManager.aeroIndiaJet,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF1E4E96)),
        )
        .animate()
        .fadeIn(delay: 180.ms, duration: 700.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.22,
          end: 0,
          delay: 180.ms,
          duration: 900.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
