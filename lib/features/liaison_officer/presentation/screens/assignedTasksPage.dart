import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/contrast.dart';
import '../../../../core/notifications/mock_email_notifier.dart';
import '../../data/enum/taskStatus.dart';
import '../../data/models/LoTask.dart';
import '../../data/models/lo_assignment.dart';
import '../widgets/statusSlider.dart';
import 'lo_notifications_screen.dart';

/// LO.9.3 Tasks tab — prefers [LoTaskAssignment], falls back to derived [LOTask]s.
class AssignedTasksPage extends StatefulWidget {
  final String loEmail;
  final List<LOTask> fallbackTasks;
  final VoidCallback? onUpdate;

  const AssignedTasksPage({
    super.key,
    required this.loEmail,
    this.fallbackTasks = const [],
    this.onUpdate,
  });

  @override
  State<AssignedTasksPage> createState() => _AssignedTasksPageState();
}

class _AssignedTasksPageState extends State<AssignedTasksPage> {
  List<LoTaskAssignment> _assignments = [];
  bool _loading = true;
  String? _filterStatus;
  String? _filterDelegate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AssignedTasksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loEmail != widget.loEmail) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await LoTaskAssignment.ensureDemoSeed(widget.loEmail);
      final tasks = await LoTaskAssignment.forLo(widget.loEmail);
      if (!mounted) return;
      setState(() {
        _assignments = tasks;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('AssignedTasksPage._load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _assignments = _memoryDemoTasks(widget.loEmail);
        _loading = false;
      });
    }
  }

  static List<LoTaskAssignment> _memoryDemoTasks(String loEmail) {
    final now = DateTime.now();
    return [
      LoTaskAssignment(
        taskTitle: 'Airport Pickup',
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        taskSource: 'Protocol',
        description: 'Receive delegate at T2 arrivals and escort to hotel.',
        scheduledDate: now.add(const Duration(hours: 2)),
        location: 'Kempegowda International Airport — T2',
        status: 'Pending',
      ),
      LoTaskAssignment(
        taskTitle: 'Hotel Check-in Assist',
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        taskSource: 'Accommodation',
        description: 'Coordinate presidential suite check-in and room briefing.',
        scheduledDate: now.add(const Duration(hours: 4)),
        location: 'The Leela Palace',
        status: 'Pending',
      ),
      LoTaskAssignment(
        taskTitle: 'Welcome Dinner Escort',
        delegateName: 'Sharan',
        assignedLoEmail: loEmail,
        taskSource: 'Protocol',
        description: 'Escort delegate to Welcome Dinner and confirm seating.',
        scheduledDate: now.add(const Duration(hours: 6)),
        location: 'Taj West End — Banquet Hall',
        status: 'In Progress',
      ),
      LoTaskAssignment(
        taskTitle: 'Inaugural Function Support',
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        taskSource: 'Events',
        description: 'Protocol support during Inaugural Function.',
        scheduledDate: now.add(const Duration(days: 1, hours: 2)),
        location: 'Main Convention Centre',
        status: 'Pending',
      ),
    ];
  }

  bool get _useAssignments => _assignments.isNotEmpty;

  List<LoTaskAssignment> get _filteredAssignments {
    return _assignments.where((t) {
      if (_filterStatus != null && t.status != _filterStatus) return false;
      if (_filterDelegate != null && t.delegateName != _filterDelegate) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<LoTaskAssignment>> get _grouped {
    final map = <String, List<LoTaskAssignment>>{};
    for (final t in _filteredAssignments) {
      map.putIfAbsent(t.delegateName, () => []).add(t);
    }
    return map;
  }

  List<String> get _delegateNames =>
      _assignments.map((t) => t.delegateName).toSet().toList()..sort();

  int get _total => _assignments.length;
  int get _pending =>
      _assignments.where((t) => t.status == 'Pending').length;
  int get _inProgress =>
      _assignments.where((t) => t.status == 'In Progress').length;
  int get _done =>
      _assignments.where((t) => t.status == 'Completed').length;

  TaskStatus _toEnum(String status) {
    switch (status) {
      case 'In Progress':
        return TaskStatus.inProgress;
      case 'Completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  String _fromEnum(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.pending:
        return 'Pending';
    }
  }

  Future<void> _updateStatus(LoTaskAssignment task, TaskStatus status) async {
    final label = _fromEnum(status);
    try {
      await LoTaskAssignment.updateStatus(
        delegateName: task.delegateName,
        assignedLoEmail: task.assignedLoEmail,
        taskTitle: task.taskTitle,
        status: label,
      );
    } catch (e) {
      debugPrint('Task status persist failed: $e');
      if (!mounted) return;
      setState(() {
        _assignments = _assignments
            .map((t) => t.taskTitle == task.taskTitle &&
                    t.delegateName == task.delegateName
                ? t.copyWith(status: label)
                : t)
            .toList();
      });
    }

    LoNotificationStore.instance.add(
      LoNotification(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Task status updated',
        body:
            '${task.taskTitle} for ${task.delegateName} is now $label. Visible to LO Committee Nodal Officer.',
        type: LoNotifType.task,
        timestamp: DateTime.now(),
      ),
    );

    try {
      await MockEmailNotifier.send(
        to: 'nodal.officer@lo-committee.example',
        subject: 'Task status — ${task.taskTitle}',
        body:
            'LO updated task "${task.taskTitle}" for ${task.delegateName} to $label.',
      );
    } catch (_) {}

    widget.onUpdate?.call();
    try {
      await _load();
    } catch (_) {}
  }

  String _fmtSchedule(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_useAssignments) {
      return _FallbackDerivedTasks(tasks: widget.fallbackTasks);
    }

    final grouped = _grouped;

    return Column(
      children: [
        _buildHeader(cs),
        _buildStatusFilter(cs),
        if (_delegateNames.length > 1) _buildDelegateFilter(cs),
        Expanded(
          child: grouped.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: grouped.length,
                  itemBuilder: (_, i) {
                    final name = grouped.keys.toList()[i];
                    final tasks = grouped[name]!;
                    return _DelegateTaskGroup(
                      delegateName: name,
                      tasks: tasks,
                      formatSchedule: _fmtSchedule,
                      toEnum: _toEnum,
                      onStatusChanged: _updateStatus,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final s = context.semantic;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.border),
      ),
      child: Row(
        children: [
          _Stat(label: 'Total', value: '$_total', color: cs.primary),
          _Stat(label: 'Pending', value: '$_pending', color: AppColors.warning),
          _Stat(
              label: 'Active', value: '$_inProgress', color: AppColors.primary),
          _Stat(label: 'Done', value: '$_done', color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(ColorScheme cs) {
    final options = <String?>[null, 'Pending', 'In Progress', 'Completed'];
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: options.map((o) {
          final selected = _filterStatus == o;
          final label = o ?? 'All';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: selected,
              label: Text(label),
              onSelected: (_) => setState(() => _filterStatus = o),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDelegateFilter(ColorScheme cs) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: _filterDelegate == null,
              label: const Text('All delegates'),
              onSelected: (_) => setState(() => _filterDelegate = null),
            ),
          ),
          ..._delegateNames.map(
            (n) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                selected: _filterDelegate == n,
                label: Text(n),
                onSelected: (_) => setState(() => _filterDelegate = n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    final s = context.semantic;
    return Center(
      child: Text(
        'No tasks match this filter.',
        style: TextStyle(color: s.textMuted),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Contrast.mutedLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegateTaskGroup extends StatelessWidget {
  const _DelegateTaskGroup({
    required this.delegateName,
    required this.tasks,
    required this.formatSchedule,
    required this.toEnum,
    required this.onStatusChanged,
  });

  final String delegateName;
  final List<LoTaskAssignment> tasks;
  final String Function(DateTime) formatSchedule;
  final TaskStatus Function(String) toEnum;
  final Future<void> Function(LoTaskAssignment, TaskStatus) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            delegateName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: s.textPrimary,
            ),
          ),
        ),
        ...tasks.map((task) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: s.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 13, color: s.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.person_outline,
                      label: task.delegateName,
                    ),
                    _MetaChip(
                      icon: Icons.schedule,
                      label: formatSchedule(task.scheduledDate),
                    ),
                    if (task.location.isNotEmpty)
                      _MetaChip(
                        icon: Icons.place_outlined,
                        label: task.location,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                StatusSlider(
                  status: toEnum(task.status),
                  onChanged: (status) => onStatusChanged(task, status),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: s.accent),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: s.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal fallback when no persisted assignments exist.
class _FallbackDerivedTasks extends StatelessWidget {
  const _FallbackDerivedTasks({required this.tasks});

  final List<LOTask> tasks;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks assigned yet.',
          style: TextStyle(color: s.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final t = tasks[i];
        return ListTile(
          title: Text(t.description),
          subtitle: Text('${t.vipName} · ${t.status.name}'),
        );
      },
    );
  }
}
