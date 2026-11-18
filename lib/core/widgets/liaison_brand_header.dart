import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Top bar: event mark on the left, alerts and the account avatar on the right.
class LiaisonBrandHeader extends StatelessWidget {
  const LiaisonBrandHeader({
    super.key,
    required this.initials,
    required this.alertCount,
    required this.onAlerts,
    required this.onAccountTap,
  });

  final String initials;
  final int alertCount;
  final VoidCallback onAlerts;
  final VoidCallback onAccountTap;

  static const _badge = Color(0xFFE11D2E);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final header = theme.appBarTheme.backgroundColor ?? AppTheme.navy;
    const ink = Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient(header, dark: isDark),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              const _BrandLockup(),
              const Spacer(),
              _AlertButton(
                color: ink,
                count: alertCount,
                onPressed: onAlerts,
              ),
              const SizedBox(width: 4),
              _AccountButton(
                initials: initials,
                ink: ink,
                onTap: onAccountTap,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return const SafeAssetImage(
      assetPath: AppAssetManager.aeroIndiaLogo,
      height: 40,
      width: 40,
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton({
    required this.color,
    required this.count,
    required this.onPressed,
  });

  final Color color;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: onPressed,
            icon: Icon(
              Icons.notifications_none_rounded,
              color: color,
              size: 26,
            ),
            visualDensity: VisualDensity.compact,
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 4,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: LiaisonBrandHeader._badge,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.initials,
    required this.ink,
    required this.onTap,
  });

  final String initials;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More',
      onPressed: onTap,
      padding: EdgeInsets.zero,
      icon: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: 1.4),
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Two-letter mark from a display name, falling back to the email local part.
String liaisonInitials(String name, String email) {
  final source = name.trim().isNotEmpty ? name.trim() : email.split('@').first;
  final parts = source
      .split(RegExp(r'[\s._-]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'LO';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
