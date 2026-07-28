import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Primary dark backgrounds
  static const Color backgroundColor = Color(0xFF070814);
  static const Color cardBgColor = Color(0xFF10122B);
  static const Color borderStrokeColor = Color(0xFF1F224D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8B92BA);
  static const Color textMuted = Color(0xFF565E87);

  // Light surfaces (neon-tinted)
  static const Color lightBackground = Color(0xFFF4F0FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF8F5FF);
  static const Color lightBorder = Color(0xFFE2E0F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightInputBg = Color(0xFFF3EEFF);

  // Neon colors & gradients
  static const Color purpleAccent = Color(0xFF7B2CBF);
  static const Color blueAccent = Color(0xFF0077B6);
  static const Color greenAccent = Color(0xFF2EC4B6);
  static const Color orangeAccent = Color(0xFFF77F00);
  static const Color pinkAccent = Color(0xFFE0115F);

  // Dynamic Theme Colors (LO accent)
  static Color activeAccent = const Color(0xFFC77DFF);
  static Color activePrimary = const Color(0xFF7B2CBF);

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF49117C), Color(0xFF8E2DE2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF084B30), Color(0xFF159957)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF093766), Color(0xFF007AD9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFF592D08), Color(0xFFD97200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFF630948), Color(0xFFD6156C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [Color(0xFF094E54), Color(0xFF00A896)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF4C3602), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightPurpleGradient = LinearGradient(
    colors: [Color(0xFF7B2CBF), Color(0xFFC77DFF)],
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
      primary: activeAccent,
      secondary: blueAccent,
      surface: cardBgColor,
      onSurfaceVariant: textSecondary,
      error: pinkAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
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
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: cardBgColor,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        selectedColor: activeAccent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBgColor,
        selectedItemColor: activeAccent,
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
          borderSide: BorderSide(color: activeAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purpleAccent,
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
      primary: purpleAccent,
      secondary: blueAccent,
      surface: lightCard,
      onSurfaceVariant: lightTextSecondary,
      error: pinkAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
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
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: lightCard,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: lightTextSecondary,
        textColor: lightTextPrimary,
        selectedColor: purpleAccent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: purpleAccent,
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
          borderSide: const BorderSide(color: purpleAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purpleAccent,
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
}
