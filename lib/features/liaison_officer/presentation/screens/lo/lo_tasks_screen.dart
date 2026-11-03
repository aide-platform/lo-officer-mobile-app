import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

enum _TaskFilter { all, pending, inProgress, completed }

extension on _TaskFilter {
  String get label => switch (this) {
    _TaskFilter.all => 'All tasks',
    _TaskFilter.pending => 'Pending',
    _TaskFilter.inProgress => 'In Progress',
    _TaskFilter.completed => 'Completed',
  };
}

class LoTasksScreen extends StatefulWidget {
  const LoTasksScreen({super.key});

  @override
  State<LoTasksScreen> createState() => _LoTasksScreenState();
}

class _LoTasksScreenState extends State<LoTasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static bool _isPending(LoTaskDto t) {
    final code = (t.statusCode ?? '').toUpperCase();
    final name = (t.statusName ?? '').toUpperCase();
    return code.contains('PEND') || name.contains('PEND');
  }

  static bool _isInProgress(LoTaskDto t) {
    final code = (t.statusCode ?? '').toUpperCase();
    final name = (t.statusName ?? '').toUpperCase();
    return code.contains('PROGRESS') || name.contains('PROGRESS');
  }

  static bool _isCompleted(LoTaskDto t) {
    final code = (t.statusCode ?? '').toUpperCase();
    final name = (t.statusName ?? '').toUpperCase();
    return code.contains('COMPLETE') || name.contains('COMPLETE');
  }

  List<LoTaskDto> _filtered(List<LoTaskDto> tasks) {
    final q = _searchQuery.trim().toLowerCase();
    return tasks.where((t) {
      final matchesStatus = switch (_filter) {
        _TaskFilter.all => true,
        _TaskFilter.pending => _isPending(t),
        _TaskFilter.inProgress => _isInProgress(t),
        _TaskFilter.completed => _isCompleted(t),
      };
      if (!matchesStatus) return false;
      if (q.isEmpty) return true;
      final hay = [
        t.taskTitle,
        t.taskDescription,
        t.delegateName,
        t.locationVenue,
        t.statusName,
        t.statusCode,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  void _toggleFilter(_TaskFilter f) {
    setState(() => _filter = _filter == f ? _TaskFilter.all : f);
  }

  Future<void> _openFilterSheet() async {
    final picked = await showModalBottomSheet<_TaskFilter>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        final colors = ctx.semantic;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter by status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final f in _TaskFilter.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(f.label),
                  trailing: _filter == f
                      ? Icon(Icons.check_rounded, color: colors.accent)
                      : null,
                  selected: _filter == f,
                  onTap: () => Navigator.of(ctx).pop(f),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) setState(() => _filter = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.status == LoPortalStatus.loading && state.tasks.isEmpty) {
          return const AppLoading(label: 'Loading tasks…');
        }
        if (state.status == LoPortalStatus.failure &&
            state.tasks.isEmpty &&
            state.delegates.isEmpty) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load tasks',
            onRetry: () =>
                context.read<LoPortalBloc>().add(LoPortalLoadRequested()),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<LoPortalBloc>().add(LoPortalLoadRequested());
            await context.read<LoPortalBloc>().stream.firstWhere(
              (s) =>
                  s.status == LoPortalStatus.ready ||
                  s.status == LoPortalStatus.failure,
            );
          },
          child: state.tasks.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    _TasksHero(),
                    SizedBox(height: 40),
                    AppEmptyState(
                      icon: Icons.assignment_outlined,
                      message: 'No tasks assigned.',
                    ),
                  ],
                )
              : Builder(
                  builder: (context) {
                    final filtered = _filtered(state.tasks);
                    final pendingAll = state.tasks.where(_isPending).length;
                    final inProgressAll = state.tasks
                        .where(_isInProgress)
                        .length;
                    final completedAll = state.tasks.where(_isCompleted).length;

                    // LO's own tasks (LO suit, kit, forms) first, then one
                    // group per delegate; standard tasks in client order.
                    const myTasksKey = 'My tasks';
                    final grouped = <String, List<LoTaskDto>>{};
                    for (final t in filtered) {
                      final key = t.taskScope == 'LO'
                          ? myTasksKey
                          : (t.delegateName ?? 'Unassigned');
                      grouped.putIfAbsent(key, () => []).add(t);
                    }
                    for (final list in grouped.values) {
                      list.sort(
                        (a, b) => (a.sortOrder ?? 1000).compareTo(
                          b.sortOrder ?? 1000,
                        ),
                      );
                    }
                    final keys = grouped.keys.toList()
                      ..sort((a, b) {
                        if (a == myTasksKey) return -1;
                        if (b == myTasksKey) return 1;
                        return a.compareTo(b);
                      });

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: keys.isEmpty ? 3 : keys.length + 2,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _TasksHero(),
                              _TaskStatusSummary(
                                pending: pendingAll,
                                inProgress: inProgressAll,
                                completed: completedAll,
                                filter: _filter,
                                onTap: _toggleFilter,
                              ),
                            ],
                          );
                        }
                        if (i == 1) {
                          return _SearchRow(
                            controller: _searchController,
                            query: _searchQuery,
                            filterActive: _filter != _TaskFilter.all,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            onFilter: _openFilterSheet,
                          );
                        }
                        if (keys.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: AppEmptyState(
                              icon: Icons.search_off_rounded,
                              message: 'No tasks match your search.',
                            ),
                          );
                        }
                        final delegate = keys[i - 2];
                        final tasks = grouped[delegate]!;
                        return AppStagger(
                          index: i - 2,
                          child: _DelegateGroup(
                            delegate: delegate,
                            tasks: tasks,
                            initiallyExpanded: i == 2,
                            pending: tasks.where(_isPending).length,
                            inProgress: tasks.where(_isInProgress).length,
                            completed: tasks.where(_isCompleted).length,
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TasksHero extends StatelessWidget {
  const _TasksHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.06),
            accent.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.assignment_turned_in_outlined, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your tasks and stay on track.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Icon(
                    Icons.assignment_rounded,
                    size: 56,
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surface,
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 30,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusSummary extends StatelessWidget {
  const _TaskStatusSummary({
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.filter,
    required this.onTap,
  });

  final int pending;
  final int inProgress;
  final int completed;
  final _TaskFilter filter;
  final ValueChanged<_TaskFilter> onTap;

  @override
  Widget build(BuildContext context) {
    Widget card(
      _TaskFilter f,
      String label,
      int count,
      String status,
      IconData icon,
    ) {
      return Expanded(
        child: _SummaryCard(
          label: label,
          count: count,
          color: AppStatusPalette.forLabel(status),
          icon: icon,
          selected: filter == f,
          onTap: () => onTap(f),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        spacing: 8,
        children: [
          card(
            _TaskFilter.pending,
            'Pending',
            pending,
            'PENDING',
            Icons.schedule_outlined,
          ),
          card(
            _TaskFilter.inProgress,
            'In Progress',
            inProgress,
            'IN_PROGRESS',
            Icons.play_circle_outline,
          ),
          card(
            _TaskFilter.completed,
            'Completed',
            completed,
            'COMPLETED',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: color.withValues(alpha: selected ? 0.18 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: color.withValues(alpha: selected ? 0.9 : 0.35),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
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

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.query,
    required this.filterActive,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  final TextEditingController controller;
  final String query;
  final bool filterActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final pill = BorderRadius.circular(28);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search tasks, delegate, location…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: onClear,
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: colors.surface,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: pill,
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: pill,
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: pill,
                  borderSide: BorderSide(color: colors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Badge(
            isLabelVisible: filterActive,
            smallSize: 10,
            backgroundColor: colors.accent,
            child: IconButton.outlined(
              tooltip: 'Filter by status',
              onPressed: onFilter,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegateGroup extends StatelessWidget {
  const _DelegateGroup({
    required this.delegate,
    required this.tasks,
    required this.initiallyExpanded,
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  final String delegate;
  final List<LoTaskDto> tasks;
  final bool initiallyExpanded;
  final int pending;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final total = tasks.length;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: colors.textPrimary,
          collapsedIconColor: colors.textPrimary,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.person_rounded, color: colors.accent),
          ),
          title: Text(
            '$delegate ($total)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.list_alt_rounded, size: 15, color: colors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$total tasks · $pending pending · '
                  '$inProgress in progress · $completed completed',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          children: [
            for (final t in tasks)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TaskTile(task: t),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final LoTaskDto task;

  Future<void> _updateStatus(BuildContext context) async {
    if (task.id == null) return;
    var status = task.statusCode ?? 'PENDING';
    final remarks = TextEditingController();
    final ok = await showAppFormSheet(
      context: context,
      title: 'Update status',
      builder: (ctx, setLocal) => AppFormColumn(
        children: [
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              DropdownMenuItem(
                value: 'IN_PROGRESS',
                child: Text('In Progress'),
              ),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
            ],
            onChanged: (v) {
              if (v != null) setLocal(() => status = v);
            },
          ),
          TextField(
            controller: remarks,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional, max 500)',
            ),
            maxLines: 2,
            maxLength: 500,
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      remarks.dispose();
      return;
    }
    final note = remarks.text.trim();
    context.read<LoPortalBloc>().add(
      LoPortalTaskStatusUpdated(
        taskId: task.id!,
        statusCode: status,
        remarks: note.isEmpty ? null : note,
      ),
    );
    remarks.dispose();
  }

  void _showDetails(BuildContext context, String scheduled, String location) {
    final statusLabel = task.statusName ?? task.statusCode ?? '—';
    final delegate = (task.delegateName ?? '').trim();
    final remarks = (task.remarks ?? '').trim();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final colors = ctx.semantic;
        final accent = colors.accent;
        final buttonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.assignment_outlined, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.taskTitle ?? 'Task',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusPill(label: statusLabel),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: accent.withValues(alpha: 0.1),
                      foregroundColor: colors.textPrimary,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if ((task.taskDescription ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  task.taskDescription!,
                  style: TextStyle(height: 1.45, color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              if (delegate.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          delegate
                              .split(RegExp(r'\s+'))
                              .where((s) => s.isNotEmpty)
                              .take(2)
                              .map((s) => s[0].toUpperCase())
                              .join(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delegate',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                            Text(
                              delegate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Scheduled',
                      value: scheduled.isEmpty ? '—' : scheduled,
                    ),
                  ),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.place_outlined,
                      label: 'Location',
                      value: location.isEmpty ? '—' : location,
                    ),
                  ),
                ],
              ),
              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.notes_rounded,
                  label: 'Remarks',
                  value: remarks,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (location.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => LoContactActions.openMaps(location),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: buttonShape,
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Navigate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: task.id == null
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              _updateStatus(context);
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: buttonShape,
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Update status'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final scheduled = LoDisplayFormat.dateAndTime(
      task.scheduledDate,
      task.scheduledTime,
    );
    final location = (task.locationVenue ?? '').trim();
    final statusLabel = task.statusName ?? task.statusCode ?? '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 20,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskTitle ?? '—',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if ((task.taskDescription ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.taskDescription!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                _metaRow(
                  context,
                  Icons.calendar_month_outlined,
                  'Scheduled',
                  scheduled.isEmpty ? '—' : scheduled,
                ),
                _metaRow(
                  context,
                  Icons.place_outlined,
                  'Location',
                  location.isEmpty ? '—' : location,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(child: _StatusPill(label: statusLabel)),
                    const Spacer(),
                    _CircleAction(
                      tooltip: 'Update status',
                      icon: Icons.sync_rounded,
                      onPressed: () => _updateStatus(context),
                    ),
                    const SizedBox(width: 8),
                    _CircleAction(
                      tooltip: 'Task details',
                      icon: Icons.more_horiz_rounded,
                      onPressed: () =>
                          _showDetails(context, scheduled, location),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Update status',
            onPressed: () => _updateStatus(context),
            icon: Icon(
              Icons.sync_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: colors.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppStatusPalette.forLabel(label);
    final s = label.toUpperCase();
    final icon = s.contains('COMPLETE')
        ? Icons.check_circle_outline
        : s.contains('PROGRESS')
        ? Icons.play_circle_outline
        : Icons.schedule_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.accent.withValues(alpha: 0.1),
        foregroundColor: colors.textPrimary,
        minimumSize: const Size(40, 40),
        fixedSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
