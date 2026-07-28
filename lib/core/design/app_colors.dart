import 'package:flutter/material.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Neon-mapped color API compatible with the Aero LO module.
/// LO accent (`roleLO`) uses purple neon instead of emerald.
class AppColors {
  AppColors._();

  static const Color primary = AppTheme.purpleAccent;
  static const Color primaryDark = Color(0xFF49117C);
  static const Color primaryLight = AppTheme.blueAccent;

  static const Color teal = AppTheme.greenAccent;
  static const Color tealLight = Color(0xFF5EEAD4);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C96A);
  static const Color goldDark = Color(0xFFB8860B);

  static const Color gradientStart = AppTheme.purpleAccent;
  static const Color gradientMid = Color(0xFF8E2DE2);
  static const Color gradientEnd = Color(0xFFC77DFF);

  static const Color gradientTealStart = Color(0xFF094E54);
  static const Color gradientTealEnd = Color(0xFF00A896);
  static const Color gradientGoldStart = Color(0xFF4C3602);
  static const Color gradientGoldEnd = Color(0xFFD4AF37);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = AppTheme.backgroundColor;
  static const Color surface = AppTheme.cardBgColor;
  static const Color surfaceVar = Color(0xFF161938);
  static const Color scaffoldDark = AppTheme.backgroundColor;
  static const Color surfaceDark = AppTheme.cardBgColor;
  static const Color surfaceDark2 = Color(0xFF161938);
  static const Color drawerDark = Color(0xFF050610);

  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textMuted = AppTheme.textMuted;
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkSub = AppTheme.textSecondary;

  static const Color inputBg = Color(0xFF0C0E22);
  static const Color inputBgDark = Color(0xFF0C0E22);
  static const Color inputBorder = AppTheme.borderStrokeColor;
  static const Color inputBorderFocus = AppTheme.purpleAccent;
  static const Color inputPlaceholder = AppTheme.textMuted;

  static const Color success = AppTheme.greenAccent;
  static const Color successLight = Color(0xFF0A3D36);
  static const Color warning = AppTheme.orangeAccent;
  static const Color warningLight = Color(0xFF3D2208);
  static const Color danger = AppTheme.pinkAccent;
  static const Color dangerLight = Color(0xFF3D0A22);
  static const Color info = AppTheme.blueAccent;
  static const Color infoLight = Color(0xFF062A45);

  static const Color successAccent = success;
  static const Color dangerAccent = danger;

  static const Color navy = primary;
  static const Color navyMid = Color(0xFF2A1458);
  static const Color headerGradient = gradientStart;
  static const Color sky = teal;
  static const Color cockpit = tealLight;
  static const Color foreign = gold;
  static const Color secondary = textSecondary;
  static const Color dark = surfaceDark;
  static const Color grey = textSecondary;
  static const Color text = textPrimary;
  static const Color inputBackground = inputBg;
  static const Color divider = AppTheme.borderStrokeColor;
  static const Color dividerDark = AppTheme.borderStrokeColor;

  // Role accents — LO uses neon purple
  static const Color roleAdmin = primaryDark;
  static const Color roleVisitor = AppTheme.blueAccent;
  static const Color roleExhibitor = AppTheme.purpleAccent;
  static const Color roleDelegate = AppTheme.orangeAccent;
  static const Color roleLO = Color(0xFFC77DFF);
  static const Color roleNO = AppTheme.blueAccent;
  static const Color roleSNO = Color(0xFF2563EB);
  static const Color roleConservancy = AppTheme.greenAccent;
  static const Color roleContractor = Color(0xFF92400E);
  static const Color roleMedia = AppTheme.pinkAccent;

  static const Color themePrimary = Color(0xFFC77DFF);
  static const Color themeSecondary = AppTheme.purpleAccent;
  static const LinearGradient themeGradient = AppTheme.purpleGradient;

  static Color themePrimaryOverlay(double opacity) =>
      themePrimary.withValues(alpha: opacity);
  static Color themeSecondaryOverlay(double opacity) =>
      themeSecondary.withValues(alpha: opacity);

  static const Color shimmerBase = Color(0xFF1A1D3A);
  static const Color shimmerHighlight = Color(0xFF2A2E55);

  static Color primaryOverlay(double o) => primary.withValues(alpha: o);
  static Color goldOverlay(double o) => gold.withValues(alpha: o);
  static Color tealOverlay(double o) => teal.withValues(alpha: o);
  static Color whiteOverlay(double o) => Colors.white.withValues(alpha: o);
  static Color blackOverlay(double o) => Colors.black.withValues(alpha: o);
  static Color successOverlay(double o) => success.withValues(alpha: o);
  static Color dangerOverlay(double o) => danger.withValues(alpha: o);
  static Color warningOverlay(double o) => warning.withValues(alpha: o);

  static const LinearGradient headerGrad = AppTheme.purpleGradient;

  static const LinearGradient adminHeaderGradient = AppTheme.purpleGradient;

  static LinearGradient roleHeaderGradient(
    Color role, {
    Color? endColor,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    final endStop = endColor ?? Color.lerp(role, Colors.white, 0.28)!;
    return LinearGradient(
      colors: [role, endStop],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient roleScaffoldWash(
    Color role, {
    required bool isDark,
  }) {
    final base = isDark ? scaffoldDark : AppTheme.lightBackground;
    final tint = isDark
        ? Color.lerp(role, scaffoldDark, 0.82)!
        : Color.lerp(role, AppTheme.lightBackground, 0.88)!;
    return LinearGradient(
      colors: [tint, base],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static Color surfaceCard(bool isDark) =>
      isDark ? surfaceDark2 : AppTheme.lightCard;

  static Color inputFill(bool isDark) =>
      isDark ? inputBgDark : AppTheme.lightInputBg;

  static LinearGradient roleGradient(Color role) => LinearGradient(
        colors: [role, role.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient headerGradientFor(Color accent) {
    if (accent == roleLO) {
      return AppTheme.purpleGradient;
    }
    return roleHeaderGradient(accent);
  }
}
