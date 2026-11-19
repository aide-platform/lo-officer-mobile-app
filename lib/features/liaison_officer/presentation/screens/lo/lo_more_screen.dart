import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/widgets/liaison_brand_header.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Account page opened from the header avatar. Same layout as the
/// reference More screen: profile card, support rows, then logout.
class LoMoreBody extends StatelessWidget {
  const LoMoreBody({
    super.key,
    required this.email,
    required this.roleLabel,
    required this.profile,
    required this.onBack,
    required this.onOpenProfile,
    required this.onSettings,
    required this.onHelp,
    required this.onFaq,
    required this.onLogout,
  });

  final String email;
  final String roleLabel;
  final LiaisonOfficerDto? profile;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final VoidCallback onSettings;
  final VoidCallback onHelp;
  final VoidCallback onFaq;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final name = _name;
    final initials = liaisonInitials(name, email);
    final subtitle = _subtitle;
    final code = _code;
    final percent = _percent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: Icon(
                Icons.chevron_left_rounded,
                color: colors.textSecondary,
              ),
            ),
            Text(
              'More',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: colors.surface,
          elevation: 0,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: onOpenProfile,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _PercentAvatar(initials: initials, percent: percent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (code != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            code,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'SETTINGS & SUPPORT',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Column(
            children: [
              _MoreRow(
                icon: Icons.settings_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'Settings',
                subtitle: 'Appearance, notifications and your account',
                onTap: onSettings,
              ),
              Divider(height: 1, indent: 72, color: colors.border),
              _MoreRow(
                icon: Icons.support_agent_rounded,
                iconColor: AppTheme.indiaGreen,
                title: 'Help & Support',
                subtitle: 'Guides, helplines and the user manual',
                onTap: onHelp,
              ),
              Divider(height: 1, indent: 72, color: colors.border),
              _MoreRow(
                icon: Icons.quiz_outlined,
                iconColor: const Color(0xFFE07A3D),
                title: 'FAQs',
                subtitle: 'Answers grouped the same way as the website',
                onTap: onFaq,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: TextButton.icon(
            onPressed: onLogout,
            icon: Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Log Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _name {
    final fromProfile = profile?.displayName.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    final local = email.split('@').first.trim();
    return local.isEmpty ? 'Officer' : local;
  }

  String get _subtitle {
    final designation = profile?.designation?.trim() ?? '';
    if (designation.isNotEmpty) return designation;
    final rank = profile?.rank?.trim() ?? '';
    if (rank.isNotEmpty) return rank;
    return roleLabel;
  }

  String? get _code {
    final pass = profile?.currentPassNumber?.trim() ?? '';
    if (pass.isNotEmpty) return pass;
    final org = profile?.orgIdNumber?.trim() ?? '';
    if (org.isNotEmpty) return org;
    return null;
  }

  int get _percent {
    final officer = profile;
    if (officer == null) return 0;
    if (officer.profileComplete == true) return 100;
    final filled = <bool>[
      officer.displayName.trim().isNotEmpty,
      (officer.officialEmail ?? '').trim().isNotEmpty,
      (officer.officialContact ?? '').trim().isNotEmpty,
      (officer.designation ?? officer.rank ?? '').trim().isNotEmpty,
      (officer.photoFileId ?? '').isNotEmpty,
      officer.languages.isNotEmpty,
      (officer.genderName ?? '').trim().isNotEmpty,
      (officer.orgName ?? '').trim().isNotEmpty,
    ];
    final done = filled.where((item) => item).length;
    return ((done / filled.length) * 100).round();
  }
}

class _PercentAvatar extends StatelessWidget {
  const _PercentAvatar({required this.initials, required this.percent});

  final String initials;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 64,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent, width: 2),
            ),
            child: Text(
              initials,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
