import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const GlassCard({
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: AppTheme.glassCardDecoration(
        radius: borderRadius,
        isDark: isDark,
      ).copyWith(
        boxShadow: AppTheme.glowShadow(
          AppTheme.activeAccent,
          opacity: isDark ? 0.12 : 0.08,
        ),
      ),
      child: child,
    );
  }
}
