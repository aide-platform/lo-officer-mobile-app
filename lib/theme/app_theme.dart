import 'package:flutter/material.dart';
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
  static const Color textMuted = Color(0xFF6B7998);

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
    double radius = 16.0,
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

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: cardBgColor,
      dividerColor: borderStrokeColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          return TextStyle(
            fontSize: 12,
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
        fillColor: cardBgColor,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderStrokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderStrokeColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: royalBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
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

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightCard,
      dividerColor: lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          return TextStyle(
            fontSize: 12,
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
        hintStyle: const TextStyle(color: lightTextMuted),
        labelStyle: const TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: royalBlue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        titleLarge:
            TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w700),
        titleMedium:
            TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Build light/dark themes tinted by the selected color palette.
  static ThemeData themeFor(AppColorPalette palette, {required bool dark}) {
    final primary = palette.swatch;
    final secondary = palette.accent;
    if (!dark) {
      final base = lightTheme;
      return base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: primary,
          secondary: secondary,
        ),
        appBarTheme: base.appBarTheme.copyWith(backgroundColor: primary),
        listTileTheme: base.listTileTheme.copyWith(selectedColor: primary),
        navigationBarTheme: base.navigationBarTheme.copyWith(
          indicatorColor: primary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((s) {
            final selected = s.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : lightTextMuted,
            );
          }),
        ),
        bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
          selectedItemColor: primary,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    final base = darkTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
      ),
      appBarTheme: base.appBarTheme.copyWith(backgroundColor: primary),
      listTileTheme: base.listTileTheme.copyWith(selectedColor: primary),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        indicatorColor: primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: primary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
