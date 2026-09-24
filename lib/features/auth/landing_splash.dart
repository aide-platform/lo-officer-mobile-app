import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/aero_brand_widgets.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Full-bleed Aero India landing (matches portal starting screen).
class LandingSplash extends StatelessWidget {
  const LandingSplash({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeAssetImage(
            assetPath: AppAssetManager.landingHero,
            fit: BoxFit.cover,
            fallback: const ColoredBox(color: AeroColors.navy),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AeroColors.navy.withValues(alpha: 0.55),
                  AeroColors.navy.withValues(alpha: 0.35),
                  AeroColors.navy.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  SafeAssetImage(
                    assetPath: AppAssetManager.modLogoWhite,
                    height: 52,
                    fit: BoxFit.contain,
                    fallback: Text(
                      'MINISTRY OF DEFENCE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SafeAssetImage(
                    assetPath: AppAssetManager.aeroIndiaLogo,
                    width: 108,
                    height: 108,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aero India 2027',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Asia's premier aerospace and defence exhibition — the official event management portal for organising committees.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _LandingPill(
                        icon: Icons.calendar_today_outlined,
                        label: '8 – 17 February 2027',
                      ),
                      _LandingPill(
                        icon: Icons.location_on_outlined,
                        label: 'Air Force Station Yelahanka, Bengaluru',
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (onContinue != null)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.royalBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
        ],
      ),
    );
  }
}

class _LandingPill extends StatelessWidget {
  const _LandingPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
