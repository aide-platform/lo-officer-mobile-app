import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/shells/lo_portal_shell.dart';

/// Routes authenticated users to the LO portal (LO-only app).
class RoleHomeRouter extends StatelessWidget {
  const RoleHomeRouter({
    super.key,
    required this.email,
    required this.role,
  });

  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.instance;
    return BlocProvider(
      create: (_) => LoPortalBloc(repository: deps.loPortalRepository)
        ..add(LoPortalLoadRequested()),
      child: LoPortalShell(
        email: email,
        roleLabel: AppRole.liaisonOfficer.label,
      ),
    );
  }
}

void navigateToRoleHome(BuildContext context, AuthBlocState authState) {
  final email = authState.email ?? '';
  final role = authState.role ?? 'Liaison Officer';
  Navigator.pushReplacement(
    context,
    AppPageFadeRoute(
      page: RoleHomeRouter(email: email, role: role),
    ),
  );
}
