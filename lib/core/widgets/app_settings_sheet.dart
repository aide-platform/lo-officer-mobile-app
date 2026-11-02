import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/contrast.dart';
import 'package:liaison_officer/core/themes/data/local/theme_settings_local_data_source.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Web-parity Settings: appearance mode + color theme + font size.
Future<void> showAppSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return BlocBuilder<ThemeCubit, AppThemeSettings>(
        builder: (context, settings) {
          final cubit = context.read<ThemeCubit>();
          final colors = context.semantic;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Close',
                        style: IconButton.styleFrom(
                          backgroundColor: colors.accent.withValues(alpha: 0.1),
                          foregroundColor: colors.textPrimary,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: colors.border),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    icon: Icon(Icons.contrast_rounded, size: 22),
                    title: 'Appearance',
                  ),
                  const SizedBox(height: 12),
                  _SegmentedSelector<ThemeMode>(
                    selected: settings.mode,
                    onSelected: cubit.setTheme,
                    options: const [
                      _SegmentOption(
                        value: ThemeMode.light,
                        label: 'Light',
                        icon: Icon(Icons.light_mode_outlined, size: 20),
                      ),
                      _SegmentOption(
                        value: ThemeMode.dark,
                        label: 'Dark',
                        icon: Icon(Icons.dark_mode_outlined, size: 20),
                      ),
                      _SegmentOption(
                        value: ThemeMode.system,
                        label: 'System',
                        icon: Icon(Icons.settings_suggest_outlined, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    icon: Icon(Icons.palette_outlined, size: 22),
                    title: 'Color Theme',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in AppColorPalette.values)
                        _PaletteChip(
                          palette: p,
                          selected: settings.palette == p,
                          onTap: () => cubit.setPalette(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    icon: Text(
                      'Aa',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    title: 'Font Size',
                  ),
                  const SizedBox(height: 12),
                  _SegmentedSelector<FontSizePreset>(
                    selected: settings.font,
                    onSelected: cubit.setFont,
                    options: [
                      for (final f in FontSizePreset.values)
                        _SegmentOption(
                          value: f,
                          label: f.label,
                          icon: Text(
                            'Aa',
                            style: TextStyle(
                              fontSize: 18 * f.scale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = context.semantic.accent;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: accent),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: accent),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final Widget icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingsIcon(child: icon),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: context.semantic.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppColorPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final swatch = palette.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.label} theme',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? swatch.withValues(alpha: 0.14)
            : colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? swatch : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: swatch.withValues(alpha: 0.08),
          focusColor: swatch.withValues(alpha: 0.18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: swatch,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppTheme.readableOn(swatch),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  palette.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentOption<T> {
  const _SegmentOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final Widget icon;
}

class _SegmentedSelector<T> extends StatelessWidget {
  const _SegmentedSelector({
    required this.selected,
    required this.onSelected,
    required this.options,
  });

  final T selected;
  final ValueChanged<T> onSelected;
  final List<_SegmentOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == o.value,
                label: o.label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  hoverColor: accent.withValues(alpha: 0.06),
                  focusColor: accent.withValues(alpha: 0.16),
                  onTap: () => onSelected(o.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == o.value
                          ? accent.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected == o.value
                            ? accent
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        IconTheme.merge(
                          data: IconThemeData(
                            color: selected == o.value
                                ? accent
                                : colors.textSecondary,
                          ),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: colors.textPrimary),
                            child: o.icon,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          o.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected == o.value
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected == o.value
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
