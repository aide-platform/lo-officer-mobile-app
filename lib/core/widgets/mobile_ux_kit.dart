import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Canonical status colors for Pending / In Progress / Completed / Rejected
/// plus common profile statuses.
class AppStatusPalette {
  AppStatusPalette._();

  static Color forLabel(String? raw) {
    final s = (raw ?? '').trim().toUpperCase().replaceAll(' ', '_');
    if (s.contains('REJECT') ||
        s.contains('INACTIVE') ||
        s.contains('FAIL') ||
        s.contains('CRITICAL') ||
        s.contains('HIGH')) {
      return AppTheme.pinkAccent;
    }
    if (s.contains('COMPLETE') ||
        s.contains('APPROV') ||
        s.contains('SUBMIT') ||
        s.contains('ACTIVE') ||
        s.contains('ARRIVAL') ||
        s == 'DONE' ||
        s.contains('SYNCED')) {
      return AppTheme.indiaGreen;
    }
    if (s.contains('PROGRESS') ||
        s.contains('ASSIGN') ||
        s.contains('DISTRIBUT') ||
        s.contains('IN_REVIEW') ||
        s.contains('TRANSFER') ||
        s.contains('VENUE') ||
        s.contains('EVENT') ||
        s.contains('TRANSPORT')) {
      return AppTheme.royalBlue;
    }
    if (s.contains('PENDING') ||
        s.contains('DRAFT') ||
        s.contains('INCOMPLETE') ||
        s.contains('DEPARTURE') ||
        s.contains('MEDIUM') ||
        s.isEmpty) {
      return AppTheme.saffron;
    }
    return AppTheme.activeAccent;
  }
}

/// Status chip with consistent color coding across the app.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: label,
      color: color ?? AppStatusPalette.forLabel(label),
    );
  }
}

/// Bottom sheet for short forms (≤5 fields / one logical group).
Future<bool?> showAppFormSheet({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext ctx, void Function(void Function()) setLocal)
      builder,
  String confirmLabel = 'Save',
  String Function()? confirmLabelBuilder,
  String cancelLabel = 'Cancel',
  bool Function()? onConfirmValidate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final label = confirmLabelBuilder?.call() ?? confirmLabel;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  builder(ctx, setLocal),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(cancelLabel),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          if (onConfirmValidate != null &&
                              !onConfirmValidate()) {
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                        child: Text(label),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

/// Full-screen modal route for longer / multi-section forms.
Future<T?> pushAppFormPage<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  List<Widget>? actions,
  Widget? floatingActionButton,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
        ),
        floatingActionButton: floatingActionButton,
        body: body,
      ),
    ),
  );
}

class AppFilterOption {
  const AppFilterOption({
    required this.key,
    required this.label,
    required this.allLabel,
    required this.options,
    this.value,
  });

  final String key;
  final String label;
  final String allLabel;
  final List<String> options;
  final String? value;
}

/// Filters bottom sheet — returns map of key → selected value (null = all).
Future<Map<String, String?>?> showAppFiltersSheet({
  required BuildContext context,
  required List<AppFilterOption> filters,
}) {
  final values = <String, String?>{
    for (final f in filters) f.key: f.value,
  };
  return showModalBottomSheet<Map<String, String?>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                ...filters.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: values[f.key],
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: f.label,
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(f.allLabel),
                        ),
                        ...f.options.map(
                          (o) => DropdownMenuItem(
                            value: o,
                            child: Text(o, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => values[f.key] = v),
                    ),
                  );
                }),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        for (final f in filters) {
                          values[f.key] = null;
                        }
                        Navigator.pop(ctx, Map<String, String?>.from(values));
                      },
                      child: const Text('Clear all'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        Map<String, String?>.from(values),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Removable filter chips shown under the app bar / list header.
class AppFilterChipsBar extends StatelessWidget {
  const AppFilterChipsBar({
    super.key,
    required this.chips,
    required this.onClearKey,
    this.onOpenFilters,
  });

  final Map<String, String> chips; // key → display label
  final ValueChanged<String> onClearKey;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          if (onOpenFilters != null)
            TextButton.icon(
              onPressed: onOpenFilters,
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filters'),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          label: Text(e.value),
                          onDeleted: () => onClearKey(e.key),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Long-press selection mode with a bottom bulk-action bar.
class AppSelectionScope<T> extends StatefulWidget {
  const AppSelectionScope({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.actions,
    this.idOf,
  });

  final List<T> items;
  final Widget Function(
    BuildContext context,
    T item,
    bool selected,
    VoidCallback onToggle,
    VoidCallback onLongPress,
  ) itemBuilder;
  final List<AppBulkAction<T>> actions;
  final Object Function(T item)? idOf;

  @override
  State<AppSelectionScope<T>> createState() => _AppSelectionScopeState<T>();
}

class AppBulkAction<T> {
  const AppBulkAction({
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final void Function(List<T> selected) onSelected;
}

class _AppSelectionScopeState<T> extends State<AppSelectionScope<T>> {
  final Set<Object> _selected = {};
  bool _selecting = false;

  Object _id(T item) => widget.idOf?.call(item) ?? item as Object;

  void _toggle(T item) {
    final id = _id(item);
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selecting = false;
      } else {
        _selected.add(id);
        _selecting = true;
      }
    });
  }

  void _longPress(T item) {
    setState(() {
      _selecting = true;
      _selected.add(_id(item));
    });
  }

  List<T> get _selectedItems =>
      widget.items.where((e) => _selected.contains(_id(e))).toList();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.only(bottom: _selecting ? 88 : 16),
          itemCount: widget.items.length,
          itemBuilder: (context, i) {
            final item = widget.items[i];
            final selected = _selected.contains(_id(item));
            return widget.itemBuilder(
              context,
              item,
              selected,
              () {
                if (_selecting) {
                  _toggle(item);
                }
              },
              () => _longPress(item),
            );
          },
        ),
        if (_selecting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_selected.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () => setState(() {
                          _selected.clear();
                          _selecting = false;
                        }),
                        icon: const Icon(Icons.close),
                      ),
                      ...widget.actions.map(
                        (a) => IconButton(
                          tooltip: a.label,
                          onPressed: _selected.isEmpty
                              ? null
                              : () {
                                  a.onSelected(_selectedItems);
                                  setState(() {
                                    _selected.clear();
                                    _selecting = false;
                                  });
                                },
                          icon: Icon(a.icon),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Thumbnail + re-upload row for camera/gallery picks.
class AppImageThumbRow extends StatelessWidget {
  const AppImageThumbRow({
    super.key,
    required this.bytes,
    required this.onPick,
    required this.onClear,
    this.label = 'Photo',
  });

  final Uint8List? bytes;
  final Future<void> Function() onPick;
  final VoidCallback onClear;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (bytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26),
            ),
            child: const Icon(Icons.image_outlined),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: onPick,
                    child: Text(bytes == null ? 'Add photo' : 'Re-upload'),
                  ),
                  if (bytes != null)
                    TextButton(onPressed: onClear, child: const Text('Remove')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Adaptive shell: bottom nav on phone, NavigationRail on ≥600dp.
class AdaptiveRoleScaffold extends StatelessWidget {
  const AdaptiveRoleScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.secondaryBody,
    this.drawer,
  });

  final String title;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? secondaryBody;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.phone;
    if (!wide) {
      return AppPageScaffold(
        title: title,
        actions: actions,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF070B18), Color(0xFF12182E)]
                : const [Color(0xFFF4F7FC), Color(0xFFE8F1FF)],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                destinations: destinations
                    .map(
                      (d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon ?? d.icon,
                        label: Text(d.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        0,
                      ),
                      child: GradientHeader(
                        title: title,
                        actions: actions,
                        showMenu: drawer != null,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: secondaryBody == null
                            ? body
                            : Row(
                                children: [
                                  Expanded(flex: 2, child: body),
                                  const VerticalDivider(width: 1),
                                  Expanded(flex: 3, child: secondaryBody!),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
