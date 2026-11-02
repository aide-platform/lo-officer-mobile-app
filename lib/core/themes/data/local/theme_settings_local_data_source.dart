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

  /// Header colour (app bar, shell header).
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

  /// Primary accent: buttons, selected controls, links, focus.
  Color get accent => switch (this) {
        AppColorPalette.navyGold => const Color(0xFFD5A52A),
        AppColorPalette.oceanBreeze => const Color(0xFF18BFD0),
        AppColorPalette.emerald => const Color(0xFF159B69),
        AppColorPalette.saffron => const Color(0xFFF58A32),
        AppColorPalette.slate => const Color(0xFF718096),
        AppColorPalette.royalPurple => const Color(0xFF8045DB),
        AppColorPalette.crimson => const Color(0xFFE84355),
        AppColorPalette.midnightTeal => const Color(0xFF20BFAE),
      };

  static AppColorPalette fromId(String? id) {
    for (final p in AppColorPalette.values) {
      if (p.id == id) return p;
    }
    return AppColorPalette.midnightTeal;
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
    this.mode = ThemeMode.system,
    this.palette = AppColorPalette.midnightTeal,
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
    final paletteId = prefs.getString(_paletteKey);
    final fontId = prefs.getString(_fontKey);
    return AppThemeSettings(
      mode: mode,
      palette: paletteId == null
          ? fallback.palette
          : AppColorPaletteX.fromId(paletteId),
      font: fontId == null ? fallback.font : FontSizePresetX.fromId(fontId),
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
