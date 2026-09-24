// ignore_for_file: depend_on_referenced_packages
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// AERO INDIA 2026  –  BRAND PALETTE
// ═══════════════════════════════════════════════════════════════

class AeroColors {
  AeroColors._();

  // ── Core brand ────────────────────────────────────────────
  static const navy = Color(0xFF0C1A3A); // IAF deep navy
  static const navyMid = Color(0xFF16295C); // card fills
  static const navyLight = Color(0xFF1E3A7A); // hover tints
  static const royalBlue = Color(0xFF0055B8);

  static const saffron = Color(0xFFFF9933);
  static const indiaGreen = Color(0xFF128807);

  static const gold = Color(0xFFC9A84C); // medal gold
  static const goldLight = Color(0xFFE2C97A); // highlight
  static const goldDark = Color(0xFF8C6E24); // shadow

  static const sky = Color(0xFF4A9FD4); // sky blue
  static const skyLight = Color(0xFF8ECBEE); // light accent
  static const cockpit = Color(0xFF0A2540); // dark panels

  // ── Status ────────────────────────────────────────────────
  static const confirmed = Color(0xFF22C55E);
  static const pending = Color(0xFFF59E0B);
  static const critical = Color(0xFFEF4444);
  static const foreign = Color(0xFF8B5CF6);

  // ── Neutrals ──────────────────────────────────────────────
  static const offWhite = Color(0xFFF4F6FB);
  static const divider = Color(0xFFDDE3F0);
  static const textMuted = Color(0xFF6B7998);

  // ── Gradients ─────────────────────────────────────────────
  static const passGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyMid, navy, cockpit],
    stops: [0.0, 0.5, 1.0],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sky, navyMid],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyMid, Color(0xFF183070)],
  );
}

// ═══════════════════════════════════════════════════════════════
// AERO INDIA THEME DATA
// ═══════════════════════════════════════════════════════════════

class AeroTheme {
  AeroTheme._();

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AeroColors.royalBlue,
          primary: AeroColors.royalBlue,
          secondary: AeroColors.saffron,
          tertiary: AeroColors.indiaGreen,
          surface: AeroColors.offWhite,
          onPrimary: Colors.white,
          onSecondary: AeroColors.navy,
        ),
        primaryColor: AeroColors.royalBlue,
        scaffoldBackgroundColor: AeroColors.offWhite,
        cardTheme: CardThemeData(
          elevation: 3,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AeroColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AeroColors.navy,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AeroColors.offWhite,
          selectedColor: AeroColors.navy.withOpacity(0.12),
          labelStyle: const TextStyle(fontSize: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AeroColors.gold,
          foregroundColor: AeroColors.navy,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AeroColors.gold,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AeroColors.gold,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AeroColors.navyLight,
          brightness: Brightness.dark,
          primary: AeroColors.gold,
          secondary: AeroColors.sky,
          surface: AeroColors.cockpit,
          onPrimary: AeroColors.navy,
        ),
        primaryColor: AeroColors.navyMid,
        scaffoldBackgroundColor: AeroColors.cockpit,
        cardTheme: CardThemeData(
          elevation: 4,
          color: AeroColors.navyMid,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AeroColors.cockpit,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AeroColors.gold,
          foregroundColor: AeroColors.navy,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AeroColors.gold,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AeroColors.gold,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// AERO INDIA APP BAR  (drop-in AppBar replacement)
// ═══════════════════════════════════════════════════════════════

class AeroAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const AeroAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLogo = true,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(bottom != null ? kToolbarHeight + 48 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AeroColors.headerGradient,
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Row(children: [
          if (showLogo) ...[
            const _AeroLogo(size: 28),
            const SizedBox(width: 10),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3)),
              if (subtitle != null)
                Text(subtitle!,
                    style: TextStyle(
                        color: AeroColors.goldLight.withOpacity(0.85),
                        fontSize: 11)),
            ],
          ),
        ]),
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AERO INDIA LOGO WIDGET (vector-drawn, no asset needed)
// ═══════════════════════════════════════════════════════════════

class _AeroLogo extends StatelessWidget {
  final double size;
  const _AeroLogo({this.size = 32});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _AeroLogoPainter(),
      );
}

class _AeroLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // ── Outer gold ring ────────────────────────────────────
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AeroColors.goldLight, AeroColors.gold],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.42, ringPaint);

    // ── Inner navy fill ────────────────────────────────────
    final fillPaint = Paint()
      ..color = AeroColors.navyMid
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.38, fillPaint);

    // ── Aircraft silhouette (simple) ───────────────────────
    final planePaint = Paint()
      ..color = AeroColors.goldLight
      ..style = PaintingStyle.fill;

    // fuselage
    final fuselage = Path()
      ..moveTo(w * 0.22, h * 0.50)
      ..lineTo(w * 0.78, h * 0.46)
      ..lineTo(w * 0.78, h * 0.54)
      ..lineTo(w * 0.22, h * 0.54)
      ..close();
    canvas.drawPath(fuselage, planePaint);

    // left wing
    final lwing = Path()
      ..moveTo(w * 0.48, h * 0.50)
      ..lineTo(w * 0.28, h * 0.30)
      ..lineTo(w * 0.54, h * 0.50)
      ..close();
    canvas.drawPath(lwing, planePaint);

    // right wing (smaller delta)
    final rwing = Path()
      ..moveTo(w * 0.52, h * 0.50)
      ..lineTo(w * 0.42, h * 0.64)
      ..lineTo(w * 0.60, h * 0.52)
      ..close();
    canvas.drawPath(rwing, planePaint);

    // nose cone
    final nosePaint = Paint()..color = AeroColors.gold;
    canvas.drawCircle(Offset(w * 0.78, h / 2), w * 0.04, nosePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE BRANDED WIDGETS
// ═══════════════════════════════════════════════════════════════

/// Gold divider with optional label
class AeroDivider extends StatelessWidget {
  final String? label;
  const AeroDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 1, color: AeroColors.gold.withOpacity(0.3))),
          if (label != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(label!,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AeroColors.gold,
                      letterSpacing: 1.2)),
            ),
            Expanded(
                child: Container(
                    height: 1, color: AeroColors.gold.withOpacity(0.3))),
          ],
        ]),
      );
}

/// Standard branded section card
class AeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const AeroCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? (isDark ? AeroColors.navyMid : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AeroColors.gold.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: AeroColors.navy.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// Gold badge label
class AeroBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const AeroBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AeroColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon!, size: 11, color: c),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: c,
                letterSpacing: 0.5)),
      ]),
    );
  }
}

/// Full-width gradient header block (for pages)
class AeroPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget>? stats;

  const AeroPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.stats,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: const BoxDecoration(
          gradient: AeroColors.headerGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const _AeroLogo(size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: TextStyle(
                            color: AeroColors.goldLight.withOpacity(0.8),
                            fontSize: 11)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ]),
            if (stats != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats!,
              ),
            ],
          ],
        ),
      );
}

/// Stat tile for AeroPageHeader
class AeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const AeroStat({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color ?? AeroColors.goldLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 10)),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════
// SHIMMER EFFECT  (used on passes)
// ═══════════════════════════════════════════════════════════════

class AeroShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AeroShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<AeroShimmer> createState() => _AeroShimmerState();
}

class _AeroShimmerState extends State<AeroShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3.5, -0.5),
            end: Alignment(-0.5 + _ctrl.value * 3.5, 0.5),
            colors: const [
              Colors.transparent,
              Colors.white24,
              Colors.white38,
              Colors.white24,
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOLOGRAPHIC OVERLAY  (used on pass front face)
// ═══════════════════════════════════════════════════════════════

class HolographicOverlay extends StatefulWidget {
  final Widget child;
  const HolographicOverlay({super.key, required this.child});

  @override
  State<HolographicOverlay> createState() => _HolographicOverlayState();
}

class _HolographicOverlayState extends State<HolographicOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        return Stack(children: [
          if (child != null) child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HoloPainter(t),
              ),
            ),
          ),
        ]);
      },
      child: widget.child,
    );
  }
}

class _HoloPainter extends CustomPainter {
  final double t;
  _HoloPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      HSVColor.fromAHSV(0.0, (t * 360) % 360, 1, 1).toColor(),
      HSVColor.fromAHSV(0.06, (t * 360 + 60) % 360, 1, 1).toColor(),
      HSVColor.fromAHSV(0.08, (t * 360 + 120) % 360, 1, 1).toColor(),
      HSVColor.fromAHSV(0.06, (t * 360 + 180) % 360, 1, 1).toColor(),
      HSVColor.fromAHSV(0.04, (t * 360 + 240) % 360, 1, 1).toColor(),
      HSVColor.fromAHSV(0.0, (t * 360 + 300) % 360, 1, 1).toColor(),
    ];

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(math.cos(t * math.pi * 2), math.sin(t * math.pi * 2)),
        end: Alignment(-math.cos(t * math.pi * 2), -math.sin(t * math.pi * 2)),
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HoloPainter old) => old.t != t;
}
