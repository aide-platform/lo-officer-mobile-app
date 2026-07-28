// ═══════════════════════════════════════════════════════════════
// ROLE PROFILE DRAWER HEADER — Rail-One polished version
// Animated avatar • stat pills • profile bottom-sheet
// Works perfectly in light & dark theme
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/contrast.dart';

class DrawerStatPill {
  final String label;
  final String value;
  final Color color;
  const DrawerStatPill(
      {required this.label, required this.value, required this.color});
}

class ProfileInfoRow {
  final IconData icon;
  final String label;
  final String value;
  const ProfileInfoRow(
      {required this.icon, required this.label, required this.value});
}

class RoleProfileDrawerHeader extends StatelessWidget {
  final String name;
  final String role;
  final String? subtitle;
  final Color accentColor;
  final List<DrawerStatPill> pills;
  final List<ProfileInfoRow> profileRows;
  final Widget? badge; // e.g. active/duty chip
  final VoidCallback? onAvatarTap;

  const RoleProfileDrawerHeader({
    super.key,
    required this.name,
    required this.role,
    this.subtitle,
    this.accentColor = AppColors.themePrimary,
    this.pills = const [],
    this.profileRows = const [],
    this.badge,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradientFor(accentColor),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 60,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar row
                Row(
                  children: [
                    // Animated avatar
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: GestureDetector(
                          onTap: onAvatarTap ??
                              () => _showProfileSheet(context, isDark),
                          child: _Avatar(name: name, accentColor: accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            role,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (badge != null) ...[
                            const SizedBox(height: 6),
                            badge!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (pills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // Stat pills row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: pills.map(_buildPill).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(DrawerStatPill p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.value,
            style: TextStyle(
              color: p.color == AppColors.gold
                  ? AppColors.goldLight
                  : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            p.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        name: name,
        role: role,
        subtitle: subtitle,
        accentColor: accentColor,
        profileRows: profileRows,
        isDark: isDark,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color accentColor;
  const _Avatar({required this.name, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.08)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  final String name;
  final String role;
  final String? subtitle;
  final Color accentColor;
  final List<ProfileInfoRow> profileRows;
  final bool isDark;

  const _ProfileSheet({
    required this.name,
    required this.role,
    required this.accentColor,
    required this.profileRows,
    required this.isDark,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar + name
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: accentColor.withValues(alpha: 0.3), blurRadius: 10),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : context.semantic.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (profileRows.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            ...profileRows.map((r) =>
                _InfoRow(row: r, accentColor: accentColor, isDark: isDark)),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ProfileInfoRow row;
  final Color accentColor;
  final bool isDark;
  const _InfoRow(
      {required this.row, required this.accentColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(row.icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : context.semantic.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  row.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
