import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/theme_settings_local_data_source.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({
    ThemeSettingsLocalDataSource? localDataSource,
    ThemeMode initialMode = ThemeMode.dark,
  })  : _localDataSource = localDataSource ?? ThemeSettingsLocalDataSource(),
        super(initialMode);

  final ThemeSettingsLocalDataSource _localDataSource;

  static Future<ThemeCubit> create() async {
    final ds = ThemeSettingsLocalDataSource();
    final mode = await ds.loadThemeMode(fallback: ThemeMode.dark);
    return ThemeCubit(localDataSource: ds, initialMode: mode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (state == mode) return;
    emit(mode);
    await _localDataSource.setThemeMode(mode);
  }

  Future<void> toggle() => setTheme(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}
