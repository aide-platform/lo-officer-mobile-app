import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Theme-aware semantic colors for LO screens.
class AppSemanticColors {
  const AppSemanticColors._(this._isDark, this._scheme);

  final bool _isDark;
  final ColorScheme _scheme;

  static AppSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    return AppSemanticColors._(
      theme.brightness == Brightness.dark,
      theme.colorScheme,
    );
  }

  Color get textPrimary =>
      _isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

  Color get textSecondary =>
      _isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  Color get textMuted =>
      _isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

  Color get surface => AppColors.surfaceCard(_isDark);

  Color get surfaceElevated =>
      _isDark ? AppColors.surfaceDark2 : AppTheme.lightCardAlt;

  Color get border => _isDark ? AppColors.divider : AppTheme.lightBorder;

  Color get inputFill => AppColors.inputFill(_isDark);

  Color get accent => _isDark ? AppTheme.activeAccent : AppTheme.purpleAccent;

  Color get onAccent => Colors.white;

  /// Text/icons on purple gradient headers.
  Color get onGradient => Colors.white;

  Color get onGradientMuted => Colors.white.withValues(alpha: 0.75);

  Color get scaffold =>
      _isDark ? AppTheme.backgroundColor : AppTheme.lightBackground;

  Color get onSurfaceVariant => _scheme.onSurfaceVariant;
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semantic => AppSemanticColors.of(this);
}
