import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/services/fcm_device_registrar.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_portal_cache.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Yes / No prompt shown before [performLogout]. Returns true on Yes.
Future<bool> confirmLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final colors = ctx.semantic;
      const warning = AppTheme.saffron;
      final buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      );
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.error.withValues(alpha: 0.10),
                    border: Border.all(
                      color: scheme.error.withValues(alpha: 0.18),
                      width: 4,
                    ),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 28,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: warning.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data saved on this device will be cleared. You '
                          'will need to sign in again with OTP.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: buttonShape,
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'No',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: buttonShape,
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        iconAlignment: IconAlignment.end,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Yes, Log out',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

/// Detaches this device from the current officer, wipes that officer's
/// local portal data, then clears the session and opens login.
Future<void> performLogout(BuildContext context) async {
  try {
    // Unregister while the Bearer token is still in SessionStore.
    await FcmDeviceRegistrar.unregisterIfSignedIn();
    await LoPortalCache.clearOfficerData();
    await LoOfflineStore.clearOfficerData();
    if (context.mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
    // Wait until prefs clear completes (bloc handler awaits SessionStore.clear).
    await SessionStore.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  } finally {
    FcmDeviceRegistrar.resumeRegister();
  }
}
