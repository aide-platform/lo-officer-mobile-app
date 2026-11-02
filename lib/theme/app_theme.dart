import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/themes/data/local/theme_settings_local_data_source.dart';

/// Aero India 2027 brand theme — navy / saffron / India green (no purple neon).
class AppTheme {
  AppTheme._();

  // Brand (logo + MoD portal)
  static const Color saffron = Color(0xFFFF9933);
  static const Color indiaGreen = Color(0xFF128807);
  static const Color chakraBlue = Color(0xFF000080);
  static const Color royalBlue = Color(0xFF0055B8);
  static const Color navy = Color(0xFF0C1A3A);
  static const Color navyMid = Color(0xFF16295C);

  // Surfaces
  static const Color backgroundColor = Color(0xFF070B18);
  static const Color cardBgColor = Color(0xFF10182E);
  static const Color borderStrokeColor = Color(0xFF243056);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA8B4D0);
  static const Color textMuted = Color(0xFFC5D0E6);
  static const Color darkInputFill = Color(0xFF1A2544);

  /// Accent when the swatch is too close to the dark bar to read.
  static Color emphasisOnDark(Color swatch, Color accent) {
    return swatch.computeLuminance() < 0.18 ? accent : swatch;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// White or dark text, whichever reads better on [background].
  static Color readableOn(Color background) {
    return _contrast(Colors.white, background) >=
            _contrast(lightTextPrimary, background)
        ? Colors.white
        : lightTextPrimary;
  }

  /// Palette accent nudged until it reaches 4.5:1 on [surface] (WCAG AA),
  /// so accent text, icons and focus rings stay readable in both modes.
  static Color _accentFor(Color accent, Color surface, {required bool dark}) {
    var c = accent;
    for (var i = 0; i < 10 && _contrast(c, surface) < 4.5; i++) {
      c = Color.lerp(c, dark ? Colors.white : Colors.black, 0.1)!;
    }
    return c;
  }

  /// Shell header gradient from the palette header colour
  /// (`AppBarTheme.backgroundColor`). Navy keeps the brand gradients.
  static LinearGradient headerGradient(Color header, {required bool dark}) {
    if (header == navy) return dark ? brandHeaderGradient : lightPurpleGradient;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [Color.lerp(header, Colors.black, 0.35)!, header]
          : [header, Color.lerp(header, Colors.white, 0.28)!],
    );
  }

  /// Primary-button gradient from the theme accent (`colorScheme.primary`).
  static LinearGradient accentGradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary,
        Color.lerp(scheme.primary, Colors.black, 0.15)!,
      ],
    );
  }

  static const Color lightBackground = Color(0xFFF4F7FC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF0F5FB);
  static const Color lightBorder = Color(0xFFD5DEEC);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightInputBg = Color(0xFFF5F8FC);

  // Accents (mapped for legacy neon API names)
  static const Color purpleAccent = royalBlue;
  static const Color blueAccent = Color(0xFF4A9FD4);
  static const Color greenAccent = indiaGreen;
  static const Color orangeAccent = saffron;
  static const Color pinkAccent = Color(0xFFEF4444);

  static Color activeAccent = royalBlue;
  static Color activePrimary = navy;

  static const LinearGradient brandHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyMid, Color(0xFF183070)],
  );

  static const LinearGradient saffronGreenGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [saffron, Color(0xFFFFCC66), indiaGreen],
  );

  static const LinearGradient purpleGradient = brandHeaderGradient;
  static const LinearGradient lightPurpleGradient = LinearGradient(
    colors: [royalBlue, Color(0xFF3D8AD9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF0A4D08), indiaGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [navy, royalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFB35F00), saffron],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFF8B1538), Color(0xFFE0115F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [navyMid, blueAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF8C6E24), Color(0xFFC9A84C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.2}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
    ];
  }

  static BoxDecoration glassCardDecoration({
    Color? borderColor,
    Color? bgColor,
    double radius = AppRadii.lg,
    bool isDark = true,
  }) {
    return BoxDecoration(
      color: bgColor ?? (isDark ? cardBgColor : lightCard),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? (isDark ? borderStrokeColor : lightBorder),
        width: 1.2,
      ),
    );
  }

  static TextTheme _textTheme({required bool dark}) {
    final onSurface = dark ? textPrimary : lightTextPrimary;
    final muted = dark ? textSecondary : lightTextSecondary;
    final ui = GoogleFonts.outfitTextTheme();
    final display = GoogleFonts.sourceSerif4TextTheme();

    TextStyle outfit(
      TextStyle? base, {
      double? size,
      FontWeight? weight,
      Color? color,
      double? height,
      double? letterSpacing,
    }) {
      return GoogleFonts.outfit(
        textStyle: base,
        fontSize: size,
        fontWeight: weight,
        color: color ?? onSurface,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    TextStyle serif(
      TextStyle? base, {
      double? size,
      FontWeight? weight,
      Color? color,
      double? height,
    }) {
      return GoogleFonts.sourceSerif4(
        textStyle: base,
        fontSize: size,
        fontWeight: weight,
        color: color ?? onSurface,
        height: height,
      );
    }

    return TextTheme(
      displayLarge: serif(display.displayLarge, size: 40, weight: FontWeight.w700),
      displayMedium: serif(display.displayMedium, size: 32, weight: FontWeight.w700),
      displaySmall: serif(display.displaySmall, size: 28, weight: FontWeight.w600),
      headlineLarge: serif(display.headlineLarge, size: 26, weight: FontWeight.w700),
      headlineMedium: outfit(ui.headlineMedium, size: 22, weight: FontWeight.w700),
      headlineSmall: outfit(ui.headlineSmall, size: 20, weight: FontWeight.w700),
      titleLarge: outfit(ui.titleLarge, size: 18, weight: FontWeight.w700),
      titleMedium: outfit(ui.titleMedium, size: 16, weight: FontWeight.w600),
      titleSmall: outfit(ui.titleSmall, size: 14, weight: FontWeight.w600),
      bodyLarge: outfit(ui.bodyLarge, size: 16, weight: FontWeight.w400),
      bodyMedium: outfit(ui.bodyMedium, size: 14, weight: FontWeight.w400),
      bodySmall: outfit(ui.bodySmall, size: 12, weight: FontWeight.w400, color: muted),
      labelLarge: outfit(ui.labelLarge, size: 14, weight: FontWeight.w600),
      labelMedium: outfit(ui.labelMedium, size: 12, weight: FontWeight.w600),
      labelSmall: outfit(
        ui.labelSmall,
        size: 11,
        weight: FontWeight.w600,
        color: muted,
        letterSpacing: 0.4,
      ),
    );
  }

  static PageTransitionsTheme get _pageTransitions => PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        },
      );

  static ThemeData get darkTheme {
    final scheme = ColorScheme.dark(
      primary: royalBlue,
      secondary: saffron,
      tertiary: indiaGreen,
      surface: cardBgColor,
      onSurfaceVariant: textSecondary,
      error: pinkAccent,
      onPrimary: Colors.white,
      onSecondary: navy,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    final text = _textTheme(dark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: cardBgColor,
      dividerColor: borderStrokeColor,
      pageTransitionsTheme: _pageTransitions,
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardBgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: cardBgColor),
      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        selectedColor: royalBlue,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBgColor,
        indicatorColor: royalBlue.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return text.labelMedium!.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? royalBlue : textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBgColor,
        selectedItemColor: royalBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: borderStrokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: borderStrokeColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: royalBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.light(
      primary: royalBlue,
      secondary: saffron,
      tertiary: indiaGreen,
      surface: lightCard,
      onSurfaceVariant: lightTextSecondary,
      error: pinkAccent,
      onPrimary: Colors.white,
      onSecondary: navy,
      onSurface: lightTextPrimary,
      onError: Colors.white,
    );

    final text = _textTheme(dark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightCard,
      dividerColor: lightBorder,
      pageTransitionsTheme: _pageTransitions,
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: lightCard),
      listTileTheme: const ListTileThemeData(
        iconColor: lightTextSecondary,
        textColor: lightTextPrimary,
        selectedColor: royalBlue,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightCard,
        indicatorColor: royalBlue.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return text.labelMedium!.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? royalBlue : lightTextMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: royalBlue,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: lightTextMuted),
        labelStyle: text.bodyMedium?.copyWith(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: royalBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build light/dark themes for the selected palette.
  ///
  /// Only accent-dependent tokens change per palette: `colorScheme.primary`
  /// (buttons, switches, checkboxes, tabs, links, progress, focus) and the
  /// header colour. Backgrounds, text, borders and status colours stay put.
  static ThemeData themeFor(AppColorPalette palette, {required bool dark}) {
    final base = dark ? darkTheme : lightTheme;
    final header = palette.swatch;
    final accent = _accentFor(
      palette.accent,
      dark ? cardBgColor : lightBackground,
      dark: dark,
    );
    final onAccent = readableOn(accent);
    final muted = dark ? textMuted : lightTextMuted;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        onPrimary: onAccent,
        secondary: palette.accent,
        onSecondary: readableOn(palette.accent),
      ),
      appBarTheme: base.appBarTheme.copyWith(backgroundColor: header),
      listTileTheme: base.listTileTheme.copyWith(
        selectedColor: accent,
        selectedTileColor: accent.withValues(alpha: dark ? 0.16 : 0.10),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        indicatorColor: accent.withValues(alpha: dark ? 0.28 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return base.textTheme.labelMedium!.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : muted,
          );
        }),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: accent,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
        ),
      ),
    );
  }
}
