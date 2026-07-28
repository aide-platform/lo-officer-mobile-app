// =============================================================
// Liaison Officer Screen with Bottom Nav
// =============================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/contrast.dart';
import '../../data/enum/taskStatus.dart';
import '../../data/enum/taskType.dart';
import '../../data/models/LoTask.dart';
import '../widgets/statusSlider.dart';
import '../../bloc/lo_bloc.dart';

// ═══════════════════════════════════════════════════════════════
// ASSIGNED TASKS PAGE
// ═══════════════════════════════════════════════════════════════

class AssignedTasksPage extends StatefulWidget {
  final List<LOTask> tasks;
  final VoidCallback onUpdate;

  const AssignedTasksPage({
    super.key,
    required this.tasks,
    required this.onUpdate,
  });

  @override
  State<AssignedTasksPage> createState() => _AssignedTasksPageState();
}

class _AssignedTasksPageState extends State<AssignedTasksPage> {
  // ── Filter ────────────────────────────────────────────────
  TaskStatus? _filterStatus; // null = All
  String? _filterVip; // null = All VIPs

  // ── Derived lists ─────────────────────────────────────────
  List<LOTask> get _filtered => widget.tasks.where((t) {
        if (_filterStatus != null && t.status != _filterStatus) return false;
        if (_filterVip != null && t.vipName != _filterVip) return false;
        return true;
      }).toList();

  List<String> get _vipNames {
    final names = widget.tasks.map((t) => t.vipName).toSet().toList()..sort();
    return names;
  }

  Map<String, List<LOTask>> get _groupedByVip {
    final grouped = <String, List<LOTask>>{};
    for (final t in _filtered) {
      grouped.putIfAbsent(t.vipName, () => []).add(t);
    }
    return grouped;
  }

  // ── Stats ─────────────────────────────────────────────────
  int get _total => widget.tasks.length;
  int get _pending =>
      widget.tasks.where((t) => t.status == TaskStatus.pending).length;
  int get _inProgress =>
      widget.tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get _done =>
      widget.tasks.where((t) => t.status == TaskStatus.completed).length;

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupedByVip;

    return Column(
      children: [
        // ── Progress header ──────────────────────────
        _buildHeader(cs),

        // ── Status filter chips ──────────────────────
        _buildStatusFilter(cs),

        // ── VIP filter ────────────────────────────────
        if (_vipNames.length > 1) _buildVipFilter(cs),

        // ── Task list ─────────────────────────────────
        Expanded(
          child: grouped.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: grouped.length,
                  itemBuilder: (_, i) {
                    final vipName = grouped.keys.toList()[i];
                    final tasks = grouped[vipName]!;
                    return _VipTaskGroup(
                      vipName: vipName,
                      tasks: tasks,
                      onStatusChanged: (task, status) {
                        context.read<LoBloc>().add(LoTaskStatusChanged(
                              task.vipName,
                              task.taskIndex,
                              status,
                            ));
                      },
                      onSwipeComplete: (task) {
                        context.read<LoBloc>().add(LoTaskStatusChanged(
                              task.vipName,
                              task.taskIndex,
                              TaskStatus.completed,
                            ));
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Header strip ──────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Contrast.cardSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Contrast.cardBorder(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatBubble(
                  label: 'Total', value: _total, color: cs.primary),
            ),
            Expanded(
              child: _StatBubble(
                  label: 'Pending',
                  value: _pending,
                  color: AppColors.warning),
            ),
            Expanded(
              child: _StatBubble(
                  label: 'In Progress',
                  value: _inProgress,
                  color: AppColors.primary),
            ),
            Expanded(
              child: _StatBubble(
                  label: 'Done', value: _done, color: AppColors.success),
            ),
          ],
        ),
      );
  }

  // ── Status filter chips ───────────────────────────────────

  Widget _buildStatusFilter(ColorScheme cs) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          _FilterChip(
            label: 'All',
            selected: _filterStatus == null,
            color: cs.primary,
            onTap: () => setState(() => _filterStatus = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pending',
            selected: _filterStatus == TaskStatus.pending,
            color: AppColors.warning,
            onTap: () => setState(() => _filterStatus =
                _filterStatus == TaskStatus.pending
                    ? null
                    : TaskStatus.pending),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'In Progress',
            selected: _filterStatus == TaskStatus.inProgress,
            color: AppColors.primary,
            onTap: () => setState(() => _filterStatus =
                _filterStatus == TaskStatus.inProgress
                    ? null
                    : TaskStatus.inProgress),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Completed',
            selected: _filterStatus == TaskStatus.completed,
            color: AppColors.success,
            onTap: () => setState(() => _filterStatus =
                _filterStatus == TaskStatus.completed
                    ? null
                    : TaskStatus.completed),
          ),
        ]),
      );

  // ── VIP filter ────────────────────────────────────────────

  Widget _buildVipFilter(ColorScheme cs) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Row(children: [
          _FilterChip(
            label: 'All VIPs',
            selected: _filterVip == null,
            color: cs.secondary,
            icon: Icons.people,
            onTap: () => setState(() => _filterVip = null),
          ),
          ..._vipNames.map((name) {
            final short = name.split(' ').first;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: short,
                selected: _filterVip == name,
                color: cs.secondary,
                icon: Icons.person,
                onTap: () => setState(
                    () => _filterVip = _filterVip == name ? null : name),
              ),
            );
          }),
        ]),
      );

  // ── Empty state ───────────────────────────────────────────

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 56, color: context.semantic.border),
            const SizedBox(height: 12),
            Text(
              _filterStatus != null || _filterVip != null
                  ? 'No tasks match this filter'
                  : 'No tasks assigned yet',
              style: TextStyle(color: context.semantic.textMuted, fontSize: 14),
            ),
            if (_filterStatus != null || _filterVip != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() {
                  _filterStatus = null;
                  _filterVip = null;
                }),
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// VIP TASK GROUP
// ═══════════════════════════════════════════════════════════════

class _VipTaskGroup extends StatelessWidget {
  final String vipName;
  final List<LOTask> tasks;
  final void Function(LOTask, TaskStatus) onStatusChanged;
  final void Function(LOTask) onSwipeComplete;

  const _VipTaskGroup({
    required this.vipName,
    required this.tasks,
    required this.onStatusChanged,
    required this.onSwipeComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── VIP group header ───────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Text(
                vipName[0].toUpperCase(),
                style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vipName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: context.semantic.border,
                      color: progress == 1 ? AppColors.success : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$done/${tasks.length}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: progress == 1 ? AppColors.success : cs.primary),
            ),
          ]),
        ),

        // ── Tasks ──────────────────────────────────
        ...tasks.map((task) => _TaskCard(
              task: task,
              onStatusChanged: (s) => onStatusChanged(task, s),
              onSwipeComplete: () => onSwipeComplete(task),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TASK CARD
// ═══════════════════════════════════════════════════════════════

class _TaskCard extends StatelessWidget {
  final LOTask task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onSwipeComplete;

  const _TaskCard({
    required this.task,
    required this.onStatusChanged,
    required this.onSwipeComplete,
  });

  // ── Task type metadata ────────────────────────────────────

  IconData get _typeIcon => switch (task.type) {
        TaskType.pickup => Icons.flight_land,
        TaskType.drop => Icons.flight_takeoff,
        TaskType.hotelCheckin => Icons.hotel,
        TaskType.venueTransfer => Icons.directions_bus,
        TaskType.protocol => Icons.military_tech,
      };

  String get _typeLabel => switch (task.type) {
        TaskType.pickup => 'Pickup',
        TaskType.drop => 'Drop',
        TaskType.hotelCheckin => 'Hotel',
        TaskType.venueTransfer => 'Transfer',
        TaskType.protocol => 'Protocol',
      };

  Color get _typeColor => switch (task.type) {
        TaskType.pickup => AppColors.primary,
        TaskType.drop => AppColors.roleNO,
        TaskType.hotelCheckin => AppColors.roleDelegate,
        TaskType.venueTransfer => AppColors.roleLO,
        TaskType.protocol => AppColors.roleContractor,
      };


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.status == TaskStatus.completed;

    return Dismissible(
      key: Key('task_${task.vipName}_${task.description}'),
      direction: done ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(height: 4),
            Text('Complete',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onDismissed: (_) => onSwipeComplete(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ───────────────────────
              Row(children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcon, size: 12, color: _typeColor),
                    const SizedBox(width: 4),
                    Text(_typeLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: _typeColor,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                // Quick-complete tick
                if (!done)
                  InkWell(
                    onTap: onSwipeComplete,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    ),
                  )
                else
                  Icon(Icons.check_circle,
                      size: 20, color: AppColors.success),
              ]),

              const SizedBox(height: 4),

              // Created at
              Text(
                _fmtDate(task.createdAt),
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),

              // ── Status slider ─────────────────────
              StatusSlider(
                status: task.status,
                onChanged: onStatusChanged,
              ),

              if (!done)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(Icons.swipe_left, size: 12, color: context.semantic.border),
                    const SizedBox(width: 4),
                    Text('Swipe to complete',
                        style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ),
            ],
          ),
        ),
    );
  }

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year} · $h:$mi';
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _StatBubble extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBubble({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Contrast.mutedLabel(context),
            ),
          ),
        ],
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : Contrast.cardSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.55)
                    : Contrast.cardBorder(context),
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon!,
                  size: 12,
                  color: selected
                      ? color
                      : Contrast.mutedLabel(context),
                ),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? color
                          : Contrast.mutedLabel(context),)),
            ],
          ),
        ),
      );
  }
}
