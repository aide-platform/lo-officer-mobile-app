import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/widgets/app_settings_sheet.dart';
import 'package:liaison_officer/core/widgets/role_profile_drawer_header.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:flutter/material.dart';

/// Side navigation with a palette-tinted profile header.
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
    final colors = context.semantic;
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            RoleProfileDrawerHeader(
              name: _name,
              role: roleLabel,
              subtitle: email,
              accentColor: scheme.primary,
              onClose: () => Navigator.pop(context),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 40,
                    child: SafeAssetImage(
                      assetPath: AppAssetManager.aeroIndiaLogo,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 28, color: colors.border),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aero India 2027',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, indent: 20, endIndent: 20, color: colors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                children: [
                  for (final item in navItems)
                    _DrawerTile(
                      icon: item.icon,
                      label: item.label,
                      selected: item.selected,
                      onTap: () {
                        Navigator.pop(context);
                        item.onTap();
                      },
                    ),
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {
                      final bloc = context.read<LoPortalBloc>();
                      Navigator.pop(context);
                      openHelpSupport(context, bloc: bloc);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    subtitle: 'Appearance · Color theme · Font size',
                    onTap: () {
                      Navigator.pop(context);
                      showAppSettingsSheet(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: colors.border),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: scheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          if (!await confirmLogout(context)) return;
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          performLogout(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, color: scheme.error),
                              const SizedBox(width: 14),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: scheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            hoverColor: accent.withValues(alpha: 0.06),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: selected ? 0.18 : 0.10),
                    ),
                    child: Icon(icon, size: 22, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            color: selected ? accent : colors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: selected ? accent : colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.85);
    Widget info(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 96,
            minWidth: double.infinity,
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              const Positioned.fill(
                child: SafeAssetImage(
                  assetPath: AppAssetManager.aeroIndiaJet,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.navy.withValues(alpha: 0.92),
                        AppTheme.navy.withValues(alpha: 0.55),
                        AppTheme.navy.withValues(alpha: 0.05),
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 90, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aero India 2027',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    info(Icons.calendar_today_outlined, '8 – 17 February 2027'),
                    const SizedBox(height: 2),
                    info(Icons.place_outlined, 'Yelahanka, Bengaluru'),
                  ],
                ),
              ),
            ],
          ),
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
    this.asset,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? asset;
  final bool selected;
}
