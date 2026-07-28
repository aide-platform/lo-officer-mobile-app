// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/contrast.dart';
import '../../data/enum/taskStatus.dart';
import '../../data/enum/taskType.dart';
import '../../data/models/LoTask.dart';
import '../../data/models/vip.dart';

// ═══════════════════════════════════════════════════════════════
// DAILY ACTIVITY SUMMARY  (#14)  +  DELEGATE MOVEMENT UPDATE (#10)
//
// Integration in liaison_officer_screen.dart (Stats tab, index 2):
//   Replace the existing stats page body with:
//     LoDailySummaryScreen(vips: vipList, tasks: tasks, onUpdate: () {})
// ═══════════════════════════════════════════════════════════════

class LoDailySummaryScreen extends StatefulWidget {
  final List<VIP>   vips;
  final List<LOTask> tasks;
  final VoidCallback onUpdate;
  final void Function(LOTask task, TaskStatus status)? onTaskStatusChanged;
  final ValueChanged<VIP>? onVipChanged;

  const LoDailySummaryScreen({
    super.key,
    required this.vips,
    required this.tasks,
    required this.onUpdate,
    this.onTaskStatusChanged,
    this.onVipChanged,
  });

  @override
  State<LoDailySummaryScreen> createState() =>
      _LoDailySummaryScreenState();
}

class _LoDailySummaryScreenState
    extends State<LoDailySummaryScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _staggerCtrl =
  AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // ── Derived ───────────────────────────────────────────────
  int get _totalVips => widget.vips.length;
  int get _totalTasks => widget.tasks.length;
  int get _doneTasks  =>
      widget.tasks.where((t) => t.status == TaskStatus.completed).length;
  int get _pendingTasks =>
      widget.tasks.where((t) => t.status == TaskStatus.pending).length;
  int get _activeTasks  =>
      widget.tasks.where((t) => t.status == TaskStatus.inProgress).length;

  List<_MovementEntry> get _movements {
    final list = <_MovementEntry>[];
    for (final v in widget.vips) {
      if (v.transport.arrivalTime != null) {
        list.add(_MovementEntry(
          vipName: v.name,
          type:    MovementType.arrival,
          detail:  '${v.transport.flightNumber ?? 'Flight'} · '
              '${v.transport.arrivalTerminal ?? 'Terminal TBD'}',
          time:    v.transport.arrivalTime!,
          status:  v.transport.status,
        ));
      }
      for (final e in v.engagements) {
        list.add(_MovementEntry(
          vipName: v.name,
          type:    MovementType.event,
          detail:  e.eventName,
          time:    e.dateTime,
          status:  e.rsvpStatus,
        ));
      }
    }
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  // ── Upcoming tasks (next 3 pending/active) ────────────────
  List<LOTask> get _upcomingTasks => widget.tasks
      .where((t) => t.status != TaskStatus.completed)
      .take(3)
      .toList();

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now  = DateTime.now();
    final date = '${_weekday(now.weekday)}, '
        '${now.day} ${_month(now.month)} ${now.year}';
    final s = context.semantic;

    return CustomScrollView(
      slivers: [
        // ── Gradient header ──────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradientFor(AppColors.roleLO),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.today,
                        color: AppColors.goldLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Summary',
                          style: TextStyle(
                              color: s.onGradient,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(date,
                          style: TextStyle(
                              color: s.onGradientMuted,
                              fontSize: 11)),
                    ],
                  ),
                ]),

                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 360;
                    final stats = [
                      _SummaryStatCard(
                        label: 'Delegates',
                        value: _totalVips.toString(),
                        icon: Icons.people,
                        color: AppColors.sky,
                        delay: 0.0,
                        ctrl: _staggerCtrl,
                      ),
                      _SummaryStatCard(
                        label: 'Tasks Done',
                        value: '$_doneTasks/$_totalTasks',
                        icon: Icons.task_alt,
                        color: AppColors.success,
                        delay: 0.15,
                        ctrl: _staggerCtrl,
                      ),
                      _SummaryStatCard(
                        label: 'Pending',
                        value: _pendingTasks.toString(),
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                        delay: 0.30,
                        ctrl: _staggerCtrl,
                      ),
                      _SummaryStatCard(
                        label: 'Active',
                        value: _activeTasks.toString(),
                        icon: Icons.timelapse,
                        color: AppColors.sky,
                        delay: 0.45,
                        ctrl: _staggerCtrl,
                      ),
                    ];
                    if (narrow) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stats
                            .map((c) => SizedBox(
                                  width: (constraints.maxWidth - 8) / 2,
                                  child: c,
                                ))
                            .toList(),
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: stats,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Progress bar ────────────────────────────────
              _AnimatedProgressSection(
                done:  _doneTasks,
                total: _totalTasks,
                ctrl:  _staggerCtrl,
              ),

              const SizedBox(height: 20),

              // ── Upcoming tasks ──────────────────────────────
              if (_upcomingTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: 'UPCOMING TASKS',
                  icon:  Icons.assignment_outlined,
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Open the Tasks tab to manage all tasks'),
                        ),
                      );
                    },
                    child: const Text('View all',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 8),
                ..._upcomingTasks.asMap().entries.map(
                      (entry) => _UpcomingTaskTile(
                    task:  entry.value,
                    index: entry.key,
                    ctrl:  _staggerCtrl,
                    onMarkDone: () {
                      widget.onTaskStatusChanged?.call(
                        entry.value,
                        TaskStatus.completed,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Movement timeline ───────────────────────────
              _SectionHeader(
                title:   'MOVEMENT SCHEDULE',
                icon:    Icons.route,
                action:  () => _showAddMovementSheet(),
                actionLabel: 'Log Movement',
              ),
              const SizedBox(height: 8),

              _movements.isEmpty
                  ? _EmptyState(
                icon:    Icons.directions_bus_outlined,
                message: 'No movements scheduled today',
                sub:     'Tap "Log Movement" to add one',
              )
                  : _MovementTimeline(
                entries: _movements,
                ctrl:    _staggerCtrl,
              ),

              const SizedBox(height: 20),

              // ── Delegate quick list ─────────────────────────
              _SectionHeader(
                title: 'DELEGATES TODAY',
                icon:  Icons.person_pin,
              ),
              const SizedBox(height: 8),
              ...widget.vips.asMap().entries.map(
                    (entry) => _DelegateQuickTile(
                  vip:   entry.value,
                  index: entry.key,
                  ctrl:  _staggerCtrl,
                  onMovement: () =>
                      _showMovementSheet(entry.value),
                ),
              ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Add movement sheet (generic) ──────────────────────────
  void _showAddMovementSheet() {
    if (widget.vips.isEmpty) return;
    _showMovementSheet(widget.vips.first);
  }

  void _showMovementSheet(VIP vip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MovementUpdateSheet(
        vip: vip,
        onSave: (entry) {
          _applyMovement(vip, entry);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Movement logged for ${vip.name}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  void _applyMovement(VIP vip, _MovementEntry entry) {
    switch (entry.type) {
      case MovementType.arrival:
      case MovementType.departure:
      case MovementType.venueTransfer:
        vip.transport.status = entry.status;
        vip.transport.arrivalTime = entry.time;
        if (entry.detail.isNotEmpty) {
          vip.transport.arrivalLocation = entry.detail;
        }
        break;
      case MovementType.hotel:
        if (entry.status.toLowerCase() == 'completed' &&
            vip.hotel.roomNumber.trim().isEmpty) {
          vip.hotel.roomNumber = '101';
        }
        break;
      case MovementType.event:
        vip.remarks.add(
          '${entry.type.name}: ${entry.detail} (${entry.status}) @ '
          '${entry.time.hour.toString().padLeft(2, '0')}:'
          '${entry.time.minute.toString().padLeft(2, '0')}',
        );
        break;
    }
    widget.onVipChanged?.call(vip);
    widget.onUpdate();
  }

  String _weekday(int d) => const [
    '', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday'
  ][d];

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}

// ═══════════════════════════════════════════════════════════════
// MOVEMENT UPDATE SHEET  (#10)
// ═══════════════════════════════════════════════════════════════

class _MovementUpdateSheet extends StatefulWidget {
  final VIP vip;
  final ValueChanged<_MovementEntry> onSave;

  const _MovementUpdateSheet(
      {required this.vip, required this.onSave});

  @override
  State<_MovementUpdateSheet> createState() =>
      _MovementUpdateSheetState();
}

class _MovementUpdateSheetState
    extends State<_MovementUpdateSheet> {
  MovementType _type     = MovementType.arrival;
  String       _status   = 'Pending';
  TimeOfDay    _time      = TimeOfDay.now();
  final _detailCtrl      = TextEditingController();
  final _remarksCtrl     = TextEditingController();

  @override
  void dispose() {
    _detailCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color:        context.semantic.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            CircleAvatar(
              radius:          20,
              backgroundColor: context.semantic.accent.withValues(alpha: 0.1),
              child: Text(widget.vip.name[0].toUpperCase(),
                  style: TextStyle(
                      color:      context.semantic.accent,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log Movement',
                    style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.bold)),
                Text(widget.vip.name,
                    style: TextStyle(
                        color:   context.semantic.textSecondary,
                        fontSize: 12)),
              ],
            ),
          ]),

          const SizedBox(height: 20),

          // Movement type chips
          Text('Movement Type',
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MovementType.values.map((t) {
              final active = _type == t;
              final isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:  active
                        ? _typeColor(t).withValues(alpha: 0.12)
                        : AppColors.inputFill(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? _typeColor(t)
                          : context.semantic.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(t),
                          size:  14,
                          color: active
                              ? _typeColor(t)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(_typeLabel(t),
                          style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? _typeColor(t)
                                  : context.semantic.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Time picker
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Time',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context,
                          initialTime: _time);
                      if (t != null) {
                        setState(() => _time = t);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color:        context.semantic.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.inputBorder),
                      ),
                      child: Row(children: [
                        Icon(Icons.access_time,
                            size:  16,
                            color: context.semantic.accent),
                        const SizedBox(width: 8),
                        Text(_time.format(context),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:   14)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.inputBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.inputBorder)),
                      filled:    true,
                      fillColor: context.semantic.inputFill,
                    ),
                    items: const [
                      'Pending',
                      'Departed',
                      'En Route',
                      'Arrived',
                      'Completed',
                    ].map((s) => DropdownMenuItem(
                        value: s, child: Text(s))).toList(),
                    onChanged: (v) =>
                        setState(() => _status = v!),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // Detail field
          TextField(
            controller: _detailCtrl,
            decoration: InputDecoration(
              labelText:   'Details (flight, venue, etc.)',
              prefixIcon:  const Icon(Icons.info_outline, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: AppColors.inputBorder)),
              filled:    true,
              fillColor: context.semantic.inputFill,
            ),
          ),

          const SizedBox(height: 10),

          // Remarks field
          TextField(
            controller:    _remarksCtrl,
            maxLines:      2,
            decoration: InputDecoration(
              labelText:   'Remarks',
              prefixIcon:  const Icon(Icons.edit_note, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: AppColors.inputBorder)),
              filled:    true,
              fillColor: context.semantic.inputFill,
            ),
          ),

          const SizedBox(height: 16),

          // Save
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon:  const Icon(Icons.check_circle_outline,
                  size: 18),
              label: const Text('Log Movement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.semantic.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                final now = DateTime.now();
                final entry = _MovementEntry(
                  vipName: widget.vip.name,
                  type:    _type,
                  detail:  _detailCtrl.text.isEmpty
                      ? _typeLabel(_type)
                      : _detailCtrl.text,
                  time: DateTime(now.year, now.month,
                      now.day, _time.hour, _time.minute),
                  status: _status,
                );
                Navigator.pop(context);
                widget.onSave(entry);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOVEMENT TIMELINE WIDGET
// ═══════════════════════════════════════════════════════════════

class _MovementTimeline extends StatelessWidget {
  final List<_MovementEntry> entries;
  final AnimationController ctrl;

  const _MovementTimeline(
      {required this.entries, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.asMap().entries.map((e) {
        final idx   = e.key;
        final entry = e.value;
        final isLast = idx == entries.length - 1;

        return TweenAnimationBuilder<double>(
          tween:    Tween(begin: 0, end: 1),
          duration: Duration(
              milliseconds: 400 + (idx * 60)),
          curve: Curves.easeOut,
          builder: (_, val, child) => Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(20 * (1 - val), 0),
              child: child,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Text(
                        _fmt(entry.time),
                        style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.bold,
                            color:      context.semantic.accent),
                      ),
                    ],
                  ),
                ),

                // Node + line
                Column(children: [
                  Container(
                    width:  12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _typeColor(entry.type),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _typeColor(entry.type)
                              .withValues(alpha: 0.4),
                          blurRadius:   6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets
                            .symmetric(vertical: 3),
                        color: context.semantic.border,
                      ),
                    ),
                ]),

                const SizedBox(width: 12),

                // Content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                        bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard(
                          Theme.of(context).brightness ==
                              Brightness.dark),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: _typeColor(entry.type)
                              .withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.04),
                          blurRadius:  6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(_typeIcon(entry.type),
                              size:  13,
                              color: _typeColor(entry.type)),
                          const SizedBox(width: 5),
                          Text(_typeLabel(entry.type),
                              style: TextStyle(
                                  fontSize:   9,
                                  fontWeight: FontWeight.bold,
                                  color:
                                  _typeColor(entry.type),
                                  letterSpacing: 0.8)),
                          const Spacer(),
                          _StatusPill(
                              status: entry.status),
                        ]),
                        const SizedBox(height: 4),
                        Text(entry.vipName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:   12)),
                        if (entry.detail.isNotEmpty)
                          Text(entry.detail,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:    context.semantic.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmt(DateTime dt) {
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$h:$mi';
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double delay;
  final AnimationController ctrl;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.7 + 0.3 * t,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: color.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color:      color,
                        fontSize:   15,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(
                        color: context.semantic.onGradientMuted,
                        fontSize: 9),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedProgressSection extends StatefulWidget {
  final int done;
  final int total;
  final AnimationController ctrl;

  const _AnimatedProgressSection(
      {required this.done,
        required this.total,
        required this.ctrl});

  @override
  State<_AnimatedProgressSection> createState() =>
      _AnimatedProgressSectionState();
}

class _AnimatedProgressSectionState
    extends State<_AnimatedProgressSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progCtrl =
  AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 1200),
  );
  late Animation<double> _prog;

  @override
  void initState() {
    super.initState();
    final pct = widget.total > 0
        ? widget.done / widget.total
        : 0.0;
    _prog = Tween<double>(begin: 0, end: pct)
        .animate(CurvedAnimation(
        parent: _progCtrl, curve: Curves.easeOut));
    Future.delayed(
        const Duration(milliseconds: 400),
            () => _progCtrl.forward());
  }

  @override
  void dispose() {
    _progCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surfaceCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color:      context.semantic.accent.withValues(alpha: 0.06),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.bar_chart,
              color: context.semantic.accent, size: 16),
          const SizedBox(width: 8),
          Text('Task Completion',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   13)),
          const Spacer(),
          AnimatedBuilder(
            animation: _prog,
            builder: (_, __) => Text(
              '${(_prog.value * 100).round()}%',
              style: TextStyle(
                  color:      context.semantic.accent,
                  fontWeight: FontWeight.bold,
                  fontSize:   13),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _prog,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:          _prog.value,
              minHeight:      10,
              backgroundColor: AppColors.inputFill(isDark),
              valueColor: AlwaysStoppedAnimation<Color>(
                _prog.value == 1
                    ? AppColors.success
                    : context.semantic.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.done} done',
                style: const TextStyle(
                    fontSize: 11,
                    color:    AppColors.success,
                    fontWeight: FontWeight.w600)),
            Text('${widget.total - widget.done} remaining',
                style: TextStyle(
                    fontSize: 11,
                    color:    context.semantic.textMuted)),
          ],
        ),
      ]),
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  final LOTask task;
  final int    index;
  final AnimationController ctrl;
  final VoidCallback onMarkDone;

  const _UpcomingTaskTile({
    required this.task,
    required this.index,
    required this.ctrl,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _taskTypeColor(task.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.surfaceCard(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding:      const EdgeInsets.all(8),
          decoration:   BoxDecoration(
            color:        typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_taskTypeIcon(task.type),
              size: 16, color: typeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   12)),
              Text(task.vipName,
                  style: TextStyle(
                      fontSize: 10,
                      color:    context.semantic.textMuted)),
            ],
          ),
        ),
        // Quick done button
        GestureDetector(
          onTap: onMarkDone,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check,
                size: 14, color: AppColors.success),
          ),
        ),
      ]),
    );
  }
}

class _DelegateQuickTile extends StatelessWidget {
  final VIP  vip;
  final int  index;
  final AnimationController ctrl;
  final VoidCallback onMovement;

  const _DelegateQuickTile({
    required this.vip,
    required this.index,
    required this.ctrl,
    required this.onMovement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.surfaceCard(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color:      context.semantic.accent.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius:          20,
          backgroundColor: context.semantic.accent.withValues(alpha: 0.1),
          child: Text(
            vip.name.isNotEmpty ? vip.name[0].toUpperCase() : '?',
            style: TextStyle(
                color:      context.semantic.accent,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(vip.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:   13)),
                if (vip.isForeign) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color:        AppColors.foreign
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('FOREIGN',
                        style: TextStyle(
                            fontSize:   8,
                            color:      AppColors.foreign,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              Text(vip.designation,
                  style: TextStyle(
                      fontSize: 11,
                      color:    context.semantic.textMuted)),
              if (vip.hotel.name.isNotEmpty)
                Text('🏨 ${vip.hotel.name}',
                    style: TextStyle(
                        fontSize: 10,
                        color:    context.semantic.textMuted)),
            ],
          ),
        ),

        // Transport status pill
        Column(children: [
          _StatusPill(status: vip.transport.status),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onMovement,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        context.semantic.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Update',
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.bold,
                      color:      context.semantic.accent)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String     title;
  final IconData   icon;
  final Widget?    trailing;
  final VoidCallback? action;
  final String?    actionLabel;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: context.semantic.accent),
    const SizedBox(width: 6),
    Text(title,
        style: TextStyle(
            fontSize:     11,
            fontWeight:   FontWeight.bold,
            color:        context.semantic.accent,
            letterSpacing: 1.1)),
    const Spacer(),
    if (trailing != null) trailing!,
    if (action != null)
      GestureDetector(
        onTap: action,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:        context.semantic.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.add,
                size: 12, color: context.semantic.accent),
            const SizedBox(width: 4),
            Text(actionLabel ?? 'Add',
                style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.bold,
                    color:      context.semantic.accent)),
          ]),
        ),
      ),
  ]);
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color get _c {
    final s = status.toLowerCase();
    if (s.contains('complet') || s.contains('arrived') ||
        s.contains('confirmed')) return AppColors.success;
    if (s.contains('route') || s.contains('progress') ||
        s.contains('depart')) return AppColors.sky;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        _c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _c.withValues(alpha: 0.4)),
    ),
    child: Text(status,
        style: TextStyle(
            fontSize:   8,
            fontWeight: FontWeight.bold,
            color:      _c)),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final String?  sub;

  const _EmptyState(
      {required this.icon,
        required this.message,
        this.sub});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.semantic.border),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color:   context.semantic.textMuted,
                  fontSize: 13)),
          if (sub != null)
            Text(sub!,
                style: TextStyle(
                    color:   context.semantic.border,
                    fontSize: 11)),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

enum MovementType { arrival, departure, venueTransfer, event, hotel }

class _MovementEntry {
  final String       vipName;
  final MovementType type;
  final String       detail;
  final DateTime     time;
  final String       status;

  const _MovementEntry({
    required this.vipName,
    required this.type,
    required this.detail,
    required this.time,
    required this.status,
  });
}

// ═══════════════════════════════════════════════════════════════
// UTILITY
// ═══════════════════════════════════════════════════════════════

Color _typeColor(MovementType t) => switch (t) {
  MovementType.arrival       => AppColors.success,
  MovementType.departure     => AppColors.danger,
  MovementType.venueTransfer => AppColors.sky,
  MovementType.event         => AppColors.gold,
  MovementType.hotel         => AppColors.roleDelegate,
};

IconData _typeIcon(MovementType t) => switch (t) {
  MovementType.arrival       => Icons.flight_land,
  MovementType.departure     => Icons.flight_takeoff,
  MovementType.venueTransfer => Icons.directions_bus,
  MovementType.event         => Icons.event,
  MovementType.hotel         => Icons.hotel,
};

String _typeLabel(MovementType t) => switch (t) {
  MovementType.arrival       => 'Arrival',
  MovementType.departure     => 'Departure',
  MovementType.venueTransfer => 'Transfer',
  MovementType.event         => 'Event',
  MovementType.hotel         => 'Hotel',
};

Color _taskTypeColor(TaskType t) => switch (t) {
  TaskType.pickup        => AppColors.sky,
  TaskType.drop          => AppColors.roleNO,
  TaskType.hotelCheckin  => AppColors.roleDelegate,
  TaskType.venueTransfer => AppColors.roleLO,
  TaskType.protocol      => AppColors.roleContractor,
};

IconData _taskTypeIcon(TaskType t) => switch (t) {
  TaskType.pickup        => Icons.flight_land,
  TaskType.drop          => Icons.flight_takeoff,
  TaskType.hotelCheckin  => Icons.hotel,
  TaskType.venueTransfer => Icons.directions_bus,
  TaskType.protocol      => Icons.military_tech,
};