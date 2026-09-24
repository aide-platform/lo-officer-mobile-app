import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/themes/data/local/theme_settings_local_data_source.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';

/// Web-parity Settings: color themes + font size + light/dark.
Future<void> showAppSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return BlocBuilder<ThemeCubit, AppThemeSettings>(
        builder: (context, settings) {
          final cubit = context.read<ThemeCubit>();
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    value: settings.mode == ThemeMode.dark,
                    onChanged: (v) => cubit.setTheme(
                      v ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Color Theme',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppColorPalette.values.map((p) {
                      final selected = settings.palette == p;
                      return ChoiceChip(
                        selected: selected,
                        avatar: CircleAvatar(
                          backgroundColor: p.swatch,
                          radius: 10,
                          child: CircleAvatar(
                            backgroundColor: p.accent,
                            radius: 4,
                          ),
                        ),
                        label: Text(p.label),
                        onSelected: (_) => cubit.setPalette(p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Font Size',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: FontSizePreset.values.map((f) {
                      final selected = settings.font == f;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12)
                                  : null,
                              side: BorderSide(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            onPressed: () => cubit.setFont(f),
                            child: Column(
                              children: [
                                Text(
                                  'Aa',
                                  style: TextStyle(
                                    fontSize: 18 * f.scale,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(f.label, style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
