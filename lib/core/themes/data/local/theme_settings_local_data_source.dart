import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorPalette {
  navyGold,
  oceanBreeze,
  emerald,
  saffron,
  slate,
  royalPurple,
  crimson,
  midnightTeal,
}

enum FontSizePreset { small, medium, large }

extension AppColorPaletteX on AppColorPalette {
  String get id => name;

  String get label => switch (this) {
        AppColorPalette.navyGold => 'Navy Gold',
        AppColorPalette.oceanBreeze => 'Ocean Breeze',
        AppColorPalette.emerald => 'Emerald',
        AppColorPalette.saffron => 'Saffron',
        AppColorPalette.slate => 'Slate',
        AppColorPalette.royalPurple => 'Royal Purple',
        AppColorPalette.crimson => 'Crimson',
        AppColorPalette.midnightTeal => 'Midnight Teal',
      };

  /// Preview swatch (primary).
  Color get swatch => switch (this) {
        AppColorPalette.navyGold => const Color(0xFF0C1A3A),
        AppColorPalette.oceanBreeze => const Color(0xFF0E7490),
        AppColorPalette.emerald => const Color(0xFF047857),
        AppColorPalette.saffron => const Color(0xFFE87820),
        AppColorPalette.slate => const Color(0xFF475569),
        AppColorPalette.royalPurple => const Color(0xFF6D28D9),
        AppColorPalette.crimson => const Color(0xFFB91C1C),
        AppColorPalette.midnightTeal => const Color(0xFF134E4A),
      };

  Color get accent => switch (this) {
        AppColorPalette.navyGold => const Color(0xFFC9A84C),
        AppColorPalette.oceanBreeze => const Color(0xFF22D3EE),
        AppColorPalette.emerald => const Color(0xFF34D399),
        AppColorPalette.saffron => const Color(0xFFFF9933),
        AppColorPalette.slate => const Color(0xFF94A3B8),
        AppColorPalette.royalPurple => const Color(0xFFA78BFA),
        AppColorPalette.crimson => const Color(0xFFF87171),
        AppColorPalette.midnightTeal => const Color(0xFF2DD4BF),
      };

  static AppColorPalette fromId(String? id) {
    for (final p in AppColorPalette.values) {
      if (p.id == id) return p;
    }
    return AppColorPalette.navyGold;
  }
}

extension FontSizePresetX on FontSizePreset {
  String get id => name;

  String get label => switch (this) {
        FontSizePreset.small => 'Small',
        FontSizePreset.medium => 'Medium',
        FontSizePreset.large => 'Large',
      };

  double get scale => switch (this) {
        FontSizePreset.small => 0.9,
        FontSizePreset.medium => 1.0,
        FontSizePreset.large => 1.15,
      };

  static FontSizePreset fromId(String? id) {
    for (final f in FontSizePreset.values) {
      if (f.id == id) return f;
    }
    return FontSizePreset.medium;
  }
}

class AppThemeSettings {
  const AppThemeSettings({
    this.mode = ThemeMode.light,
    this.palette = AppColorPalette.navyGold,
    this.font = FontSizePreset.medium,
  });

  final ThemeMode mode;
  final AppColorPalette palette;
  final FontSizePreset font;

  AppThemeSettings copyWith({
    ThemeMode? mode,
    AppColorPalette? palette,
    FontSizePreset? font,
  }) {
    return AppThemeSettings(
      mode: mode ?? this.mode,
      palette: palette ?? this.palette,
      font: font ?? this.font,
    );
  }
}

class ThemeSettingsLocalDataSource {
  static const _modeKey = 'theme_mode';
  static const _paletteKey = 'theme_palette';
  static const _fontKey = 'theme_font';

  Future<AppThemeSettings> loadSettings({
    AppThemeSettings fallback = const AppThemeSettings(),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = switch (prefs.getString(_modeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => fallback.mode,
    };
    return AppThemeSettings(
      mode: mode,
      palette: AppColorPaletteX.fromId(prefs.getString(_paletteKey)),
      font: FontSizePresetX.fromId(prefs.getString(_fontKey)),
    );
  }

  Future<void> saveSettings(AppThemeSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final modeValue = switch (settings.mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_modeKey, modeValue);
    await prefs.setString(_paletteKey, settings.palette.id);
    await prefs.setString(_fontKey, settings.font.id);
  }

  /// Legacy API kept for callers that only touch mode.
  Future<ThemeMode> loadThemeMode({
    ThemeMode fallback = ThemeMode.dark,
  }) async {
    final s = await loadSettings(
      fallback: AppThemeSettings(mode: fallback),
    );
    return s.mode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(mode: mode));
  }
}
