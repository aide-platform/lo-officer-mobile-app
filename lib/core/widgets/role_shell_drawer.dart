import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/widgets/app_settings_sheet.dart';
import 'package:liaison_officer/core/widgets/role_profile_drawer_header.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Side navigation with saffron→green profile header (Aero India brand).
class RoleShellDrawer extends StatelessWidget {
  const RoleShellDrawer({
    super.key,
    required this.email,
    required this.roleLabel,
    this.displayName,
    this.navItems = const [],
  });

  final String email;
  final String roleLabel;
  final String? displayName;
  final List<RoleDrawerNavItem> navItems;

  String get _name {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    final local = email.split('@').first;
    if (local.isEmpty) return 'Officer';
    return local
        .split(RegExp(r'[._-]'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            RoleProfileDrawerHeader(
              name: _name,
              role: roleLabel,
              subtitle: email,
              accentColor: AppTheme.royalBlue,
              profileRows: [
                ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                ),
                ProfileInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: roleLabel,
                ),
              ],
            ),
            // Tricolor accent strip under header
            Container(
              height: 4,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.saffronGreenGradient,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        SafeAssetImage(
                          assetPath: AppAssetManager.aeroIndiaLogo,
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Aero India 2027',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ...navItems.map(
                    (item) => ListTile(
                      leading: Icon(item.icon, color: AppTheme.royalBlue),
                      title: Text(item.label),
                      onTap: () {
                        Navigator.pop(context);
                        item.onTap();
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: AppTheme.royalBlue),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: AppTheme.royalBlue,
                    ),
                    title: const Text('Settings'),
                    subtitle: const Text('Color theme · Font size'),
                    onTap: () {
                      Navigator.pop(context);
                      showAppSettingsSheet(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                performLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RoleDrawerNavItem {
  const RoleDrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
