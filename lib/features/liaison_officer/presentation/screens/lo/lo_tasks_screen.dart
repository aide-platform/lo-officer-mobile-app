import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

class LoTasksScreen extends StatefulWidget {
  const LoTasksScreen({super.key});

  @override
  State<LoTasksScreen> createState() => _LoTasksScreenState();
}

class _LoTasksScreenState extends State<LoTasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    if (q.isEmpty) return tasks;
    return tasks.where((t) {
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
                    SizedBox(height: 120),
                    AppEmptyState(
                      message: 'No tasks assigned.',
                      icon: Icons.task_alt_outlined,
                    ),
                  ],
                )
              : Builder(
                  builder: (context) {
                    final filtered = _filtered(state.tasks);
                    final pendingAll =
                        state.tasks.where(_isPending).length;
                    final inProgressAll =
                        state.tasks.where(_isInProgress).length;
                    final completedAll =
                        state.tasks.where(_isCompleted).length;

                    final grouped = <String, List<LoTaskDto>>{};
                    for (final t in filtered) {
                      final key = t.delegateName ?? 'Unassigned';
                      grouped.putIfAbsent(key, () => []).add(t);
                    }
                    final keys = grouped.keys.toList();

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: keys.isEmpty ? 3 : keys.length + 2,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return _TaskStatusSummary(
                            pending: pendingAll,
                            inProgress: inProgressAll,
                            completed: completedAll,
                          );
                        }
                        if (i == 1) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search tasks, delegate, location…',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear',
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: const Icon(Icons.clear),
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                          );
                        }
                        if (keys.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: AppEmptyState(
                              message: 'No tasks match your search.',
                              icon: Icons.search_off_outlined,
                            ),
                          );
                        }
                        final delegate = keys[i - 2];
                        final tasks = grouped[delegate]!;
                        final total = tasks.length;
                        final pending = tasks.where(_isPending).length;
                        final inProgress = tasks.where(_isInProgress).length;
                        final completed = tasks.where(_isCompleted).length;
                        return AppCard(
                          child: ExpansionTile(
                            initiallyExpanded: i == 2,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.person_outline,
                              color: AppTheme.activeAccent,
                            ),
                            title: Text(
                              '$delegate ($total)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '$total tasks · $pending pending · '
                              '$inProgress in progress · $completed completed',
                            ),
                            children: [
                              for (final t in tasks) ...[
                                const Divider(height: 1),
                                _TaskTile(task: t),
                              ],
                            ],
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

class _TaskStatusSummary extends StatelessWidget {
  const _TaskStatusSummary({
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  final int pending;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Pending',
              count: pending,
              color: AppStatusPalette.forLabel('PENDING'),
              icon: Icons.schedule_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'In Progress',
              count: inProgress,
              color: AppStatusPalette.forLabel('IN_PROGRESS'),
              icon: Icons.play_circle_outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'Completed',
              count: completed,
              color: AppStatusPalette.forLabel('COMPLETED'),
              icon: Icons.check_circle_outline,
            ),
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
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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
              DropdownMenuItem(
                value: 'COMPLETED',
                child: Text('Completed'),
              ),
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

  @override
  Widget build(BuildContext context) {
    final scheduled = [
      task.scheduledDate,
      task.scheduledTime,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' - ');
    final location = (task.locationVenue ?? '').trim();
    final statusLabel = task.statusName ?? task.statusCode ?? '—';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskTitle ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((task.taskDescription ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.taskDescription!,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                _metaRow(
                  context,
                  'Scheduled',
                  scheduled.isEmpty ? '—' : scheduled,
                ),
                _metaRow(
                  context,
                  'Location',
                  location.isEmpty ? '—' : location,
                ),
                const SizedBox(height: 6),
                AppStatusChip(label: statusLabel),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Update status',
            onPressed: () => _updateStatus(context),
            icon: Icon(
              Icons.sync_outlined,
              color: AppTheme.activeAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
