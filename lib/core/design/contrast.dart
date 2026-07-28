import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'package:liaison_officer/theme/app_theme.dart';

export 'app_semantic_colors.dart';

/// Contrast helpers so labels stay readable in light and dark mode.
class Contrast {
  Contrast._();

  /// Text/icon on a solid accent fill (danger, warning, success, primary).
  static Color onSolid(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.55 ? AppTheme.lightTextPrimary : Colors.white;
  }

  static Color mutedLabel(BuildContext context) =>
      context.semantic.textSecondary;

  static Color bodyText(BuildContext context) => context.semantic.textPrimary;

  static Color cardSurface(BuildContext context) => context.semantic.surface;

  static Color cardBorder(BuildContext context) => context.semantic.border;
}
