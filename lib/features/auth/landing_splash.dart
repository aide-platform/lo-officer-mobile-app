import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Splash / landing — Aero India logo on black.
class LandingSplash extends StatelessWidget {
  const LandingSplash({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
              const SizedBox(height: 28),
              const Text(
                'Aero India 2027',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Liaison Officer Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 3),
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
    );
  }
}
