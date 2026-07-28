import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/session/session_store.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';

/// Clears persisted session via [AuthBloc] then navigates to login.
Future<void> performLogout(BuildContext context) async {
  context.read<AuthBloc>().add(AuthLogoutRequested());
  // Wait until prefs clear completes (bloc handler awaits SessionStore.clear).
  await SessionStore.clear();
  if (!context.mounted) return;
  Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
}
