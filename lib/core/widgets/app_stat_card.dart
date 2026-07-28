// ═══════════════════════════════════════════════════════════════
// APP STAT CARD — Animated stat tile used across all dashboards
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../design/app_colors.dart';

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool animate;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark2 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.1 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 12,
                      color: isDark ? Colors.white30 : AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            _AnimatedValue(value: value, color: color, animate: animate),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                )),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: TextStyle(fontSize: 10,
                      color: isDark ? Colors.white38 : AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedValue extends StatelessWidget {
  final String value;
  final Color color;
  final bool animate;
  const _AnimatedValue({required this.value, required this.color, required this.animate});

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (!animate || parsed == null) {
      return Text(value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color));
    }
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: parsed),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        value.contains('%') ? '$v%' : v.toString(),
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

/// Horizontal wide stat bar (for summary rows)
class AppStatRow extends StatelessWidget {
  final List<AppStatCard> cards;
  const AppStatRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cards.asMap().entries.map((e) {
        final isLast = e.key == cards.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: e.value,
          ),
        );
      }).toList(),
    );
  }
}
