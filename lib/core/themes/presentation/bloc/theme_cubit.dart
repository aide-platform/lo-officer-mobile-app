import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/themes/data/local/theme_settings_local_data_source.dart';

class ThemeCubit extends Cubit<AppThemeSettings> {
  ThemeCubit({
    ThemeSettingsLocalDataSource? localDataSource,
    AppThemeSettings initial = const AppThemeSettings(),
  })  : _localDataSource = localDataSource ?? ThemeSettingsLocalDataSource(),
        super(initial);

  final ThemeSettingsLocalDataSource _localDataSource;

  static Future<ThemeCubit> create() async {
    final ds = ThemeSettingsLocalDataSource();
    final settings = await ds.loadSettings();
    return ThemeCubit(localDataSource: ds, initial: settings);
  }

  Future<void> _persist(AppThemeSettings next) async {
    emit(next);
    await _localDataSource.saveSettings(next);
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (state.mode == mode) return;
    await _persist(state.copyWith(mode: mode));
  }

  Future<void> setPalette(AppColorPalette palette) async {
    if (state.palette == palette) return;
    await _persist(state.copyWith(palette: palette));
  }

  Future<void> setFont(FontSizePreset font) async {
    if (state.font == font) return;
    await _persist(state.copyWith(font: font));
  }

  /// [current] is the brightness on screen; needed when mode is system.
  Future<void> toggle([Brightness? current]) {
    final isDark = state.mode == ThemeMode.system
        ? current == Brightness.dark
        : state.mode == ThemeMode.dark;
    return setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
