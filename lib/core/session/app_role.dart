/// Maps CAP JWT / CurrentUser role strings to app shells.
enum AppRole {
  liaisonOfficer,
  organisationRepresentative,
  nodalOfficer,
  subNodalOfficer,
  unknown,
}

extension AppRoleX on AppRole {
  String get label {
    switch (this) {
      case AppRole.liaisonOfficer:
        return 'Liaison Officer';
      case AppRole.organisationRepresentative:
        return 'Organisation Representative';
      case AppRole.nodalOfficer:
        return 'LO Committee Nodal Officer';
      case AppRole.subNodalOfficer:
        return 'LO Committee Sub Nodal Officer';
      case AppRole.unknown:
        return 'User';
    }
  }

  bool get isNodalFamily =>
      this == AppRole.nodalOfficer || this == AppRole.subNodalOfficer;
}

AppRole resolveAppRole(String? role) {
  final r = (role ?? '').trim().toLowerCase();
  if (r.isEmpty) return AppRole.unknown;

  if (r.contains('liaison') ||
      r == 'lo' ||
      r.contains('my-lo') ||
      r.contains('liaison_officer') ||
      r.contains('liaison-officer')) {
    return AppRole.liaisonOfficer;
  }

  // Sub Nodal of LO Committee — before generic org / nodal matches.
  if (r.contains('sub nodal') ||
      r.contains('sub-nodal') ||
      r.contains('subnodal')) {
    return AppRole.subNodalOfficer;
  }

  if (r.contains('organisation') ||
      r.contains('organization') ||
      r.contains('org_rep') ||
      r.contains('org-rep') ||
      r.contains('orgrep')) {
    return AppRole.organisationRepresentative;
  }

  if (r.contains('nodal') ||
      r.contains('committee') ||
      r.contains('admin') ||
      r.contains('organizer') ||
      r.contains('organiser')) {
    return AppRole.nodalOfficer;
  }

  return AppRole.unknown;
}
