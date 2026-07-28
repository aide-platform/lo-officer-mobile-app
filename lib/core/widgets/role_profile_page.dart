import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../session/auth_logout.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'app_stat_card.dart';
import 'gradient_app_bar.dart';
import 'role_profile_drawer_header.dart' show ProfileInfoRow;

class RoleProfileStat {
  const RoleProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class RoleProfilePage extends StatelessWidget {
  const RoleProfilePage({
    super.key,
    required this.email,
    required this.roleLabel,
    this.subtitle,
    this.accentColor,
    this.stats = const [],
    this.infoRows = const [],
    this.extraSections = const [],
    this.onLogout,
  });

  final String email;
  final String roleLabel;
  final String? subtitle;
  final Color? accentColor;
  final List<RoleProfileStat> stats;
  final List<ProfileInfoRow> infoRows;
  final List<Widget> extraSections;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.roleLO;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.surfaceCard(isDark);
    final borderColor = isDark ? AppColors.divider : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GradientAppBar(
        titleText: 'Profile',
        accent: accent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: RoleScaffoldBackground(
        accent: accent,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                email,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Center(
                child: Chip(
                  backgroundColor: cardColor,
                  label: Text(subtitle!, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: Chip(
                backgroundColor: accent.withValues(alpha: 0.15),
                label: Text(
                  roleLabel,
                  style: TextStyle(fontSize: 12, color: accent),
                ),
              ),
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: AppStatCard(
                        label: stats[i].label,
                        value: stats[i].value,
                        icon: stats[i].icon,
                        color: stats[i].color,
                        animate: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (infoRows.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: Column(
                  children: infoRows
                      .map(
                        (row) => ListTile(
                          leading: Icon(row.icon, color: accent),
                          title: Text(row.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text(row.value),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            ...extraSections,
            const SizedBox(height: 24),
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: onLogout ?? () => performLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
