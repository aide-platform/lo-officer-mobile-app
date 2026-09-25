/// App role for the LO-only client.
///
/// CAP may still return other role strings; this app always uses the LO shell.
enum AppRole {
  liaisonOfficer,
}

extension AppRoleX on AppRole {
  String get label {
    switch (this) {
      case AppRole.liaisonOfficer:
        return 'Liaison Officer';
    }
  }
}

AppRole resolveAppRole(String? role) {
  // LO-only app: every authenticated user lands on the LO portal.
  return AppRole.liaisonOfficer;
}
