// Profile Page (LO Profile + Theme Toggle)

import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/session/auth_logout.dart';
import '../../../../core/widgets/role_profile_drawer_header.dart';
import '../../../../core/widgets/role_profile_page.dart';
import '../../data/models/vip.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final List<VIP> assignedVIPs;

  const ProfilePage({
    super.key,
    required this.email,
    required this.assignedVIPs,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final totalVIPs = widget.assignedVIPs.length;
    final completedVIPs =
        widget.assignedVIPs.where((v) => v.progressPercent == 1).length;
    final activeVIPs = totalVIPs - completedVIPs;

    return RoleProfilePage(
      email: widget.email,
      roleLabel: 'Liaison Officer',
      subtitle: 'On duty portal',
      accentColor: AppColors.roleLO,
      stats: [
        RoleProfileStat(
          label: 'Assigned VIPs',
          value: '$totalVIPs',
          icon: Icons.people,
          color: AppColors.themeSecondary,
        ),
        RoleProfileStat(
          label: 'Active',
          value: '$activeVIPs',
          icon: Icons.timelapse,
          color: AppColors.success,
        ),
        RoleProfileStat(
          label: 'Completed',
          value: '$completedVIPs',
          icon: Icons.check_circle,
          color: AppColors.gold,
        ),
      ],
      infoRows: [
        ProfileInfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: widget.email,
        ),
        ProfileInfoRow(
          icon: Icons.badge_outlined,
          label: 'Role',
          value: 'Liaison Officer',
        ),
        ProfileInfoRow(
          icon: Icons.event_outlined,
          label: 'Event',
          value: 'Liaison Officer Portal',
        ),
        ProfileInfoRow(
          icon: Icons.people_outline,
          label: 'VIPs Assigned',
          value: '$totalVIPs',
        ),
      ],
      onLogout: () => performLogout(context),
    );
  }
}
