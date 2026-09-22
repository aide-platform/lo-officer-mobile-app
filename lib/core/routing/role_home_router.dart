import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/shells/lo_portal_shell.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/shells/nodal_officer_shell.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/shells/org_rep_shell.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/nodal_lo_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/org_rep_bloc.dart';

/// Routes authenticated users to the correct role shell.
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
    final appRole = resolveAppRole(role);
    final deps = AppDependencies.instance;

    switch (appRole) {
      case AppRole.organisationRepresentative:
        return BlocProvider(
          create: (_) => OrgRepBloc(repository: deps.orgRepRepository)
            ..add(OrgRepLoadRequested()),
          child: OrgRepShell(email: email, roleLabel: appRole.label),
        );
      case AppRole.nodalOfficer:
        return BlocProvider(
          create: (_) => NodalLoBloc(repository: deps.nodalLoRepository)
            ..add(NodalLoLoadRequested()),
          child: NodalOfficerShell(email: email, roleLabel: appRole.label),
        );
      case AppRole.liaisonOfficer:
      case AppRole.unknown:
        return BlocProvider(
          create: (_) => LoPortalBloc(repository: deps.loPortalRepository)
            ..add(LoPortalLoadRequested()),
          child: LoPortalShell(email: email, roleLabel: AppRole.liaisonOfficer.label),
        );
    }
  }
}

void navigateToRoleHome(BuildContext context, AuthBlocState authState) {
  final email = authState.email ?? '';
  final role = authState.role ?? 'Liaison Officer';
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: RoleHomeRouter(email: email, role: role),
      ),
    ),
  );
}
