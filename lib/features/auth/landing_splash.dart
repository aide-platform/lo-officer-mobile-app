import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Splash / landing — Aero India logo as the hero brand signal.
class LandingSplash extends StatelessWidget {
  const LandingSplash({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SafeAssetImage(
                assetPath: AppAssetManager.splash,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                fallback: const Icon(
                  Icons.flight,
                  color: Colors.white70,
                  size: 96,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Aero India 2027',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Liaison Officer Portal',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ) ??
                    TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(flex: 3),
              if (onContinue != null)
                AppPressScale(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                      ),
                      child: Text(
                        'Continue to Sign In',
                        style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
