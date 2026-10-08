import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/fcm_device_registrar.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_portal_cache.dart';

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
