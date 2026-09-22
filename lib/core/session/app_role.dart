/// Maps CAP JWT / CurrentUser role strings to app shells.
enum AppRole {
  liaisonOfficer,
  organisationRepresentative,
  nodalOfficer,
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
      case AppRole.unknown:
        return 'User';
    }
  }
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

  if (r.contains('organisation') ||
      r.contains('organization') ||
      r.contains('org_rep') ||
      r.contains('org-rep') ||
      r.contains('orgrep') ||
      r.contains('sub nodal') ||
      r.contains('sub-nodal')) {
    return AppRole.organisationRepresentative;
  }

  if (r.contains('nodal') ||
      r.contains('committee') ||
      r.contains('admin') ||
      r.contains('organizer') ||
      r.contains('organiser') ||
      r.contains('hospitality') ||
      r.contains('protocol')) {
    return AppRole.nodalOfficer;
  }

  return AppRole.unknown;
}
