// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/contrast.dart';
import '../../../../core/widgets/gradient_app_bar.dart';

// ═══════════════════════════════════════════════════════════════
// LO NOTIFICATIONS  (#12)
//
// Integration A — NotificationBell in AppBar actions:
//   LoNotificationBell(onTap: () => Navigator.push(
//     context, MaterialPageRoute(builder: (_) =>
//       LoNotificationsScreen())))
//
// Integration B — Add to drawer:
//   ListTile(
//     leading: const Icon(Icons.notifications),
//     title: const Text('Notifications'),
//     trailing: LoNotificationBadge(),
//     onTap: () => Navigator.push(…))
// ═══════════════════════════════════════════════════════════════

// ── Singleton notification store ──────────────────────────────
// In production swap for Riverpod/Hive/FCM provider.
class LoNotificationStore {
  LoNotificationStore._();
  static final instance = LoNotificationStore._();

  final List<LoNotification> _items = _seedNotifications();
  List<LoNotification> get all => _items;

  int get unreadCount =>
      _items.where((n) => !n.isRead).length;

  void markRead(String id) {
    final idx =
    _items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: true);
    }
  }

  void markAllRead() {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }

  void add(LoNotification n) => _items.insert(0, n);

  void remove(String id) =>
      _items.removeWhere((n) => n.id == id);
}

// ── Seed data for demo ────────────────────────────────────────
List<LoNotification> _seedNotifications() => [
  LoNotification(
    id:        '1',
    title:     'VIP Arrival in 30 mins',
    body:      'Air Marshal Kapoor lands at T2 at 14:30. Vehicle on standby.',
    type:      LoNotifType.urgent,
    timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  LoNotification(
    id:        '2',
    title:     'Task Overdue',
    body:      'Hotel check-in for Amb. Rodriguez has not been updated.',
    type:      LoNotifType.task,
    timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
  ),
  LoNotification(
    id:        '3',
    title:     'Schedule Change',
    body:      'Static display visit moved to 16:00. Inform your delegates.',
    type:      LoNotifType.schedule,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  LoNotification(
    id:        '4',
    title:     'New Task Assigned',
    body:      'Protocol escort for Defence Secretary at Pavilion 4 at 11:00.',
    type:      LoNotifType.task,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead:    true,
  ),
  LoNotification(
    id:        '5',
    title:     'Operational Instruction',
    body:      'All LOs report to the main gate by 08:30 for morning briefing.',
    type:      LoNotifType.instruction,
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    isRead:    true,
  ),
  LoNotification(
    id:        '6',
    title:     'Issue Escalated',
    body:      'Catering delay for VIP lounge has been escalated to Event Ops.',
    type:      LoNotifType.issue,
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    isRead:    true,
  ),
];

// ═══════════════════════════════════════════════════════════════
// FULL SCREEN
// ═══════════════════════════════════════════════════════════════

class LoNotificationsScreen extends StatefulWidget {
  const LoNotificationsScreen({super.key});

  @override
  State<LoNotificationsScreen> createState() =>
      _LoNotificationsScreenState();
}

class _LoNotificationsScreenState
    extends State<LoNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _store = LoNotificationStore.instance;
  LoNotifType? _filter;

  List<LoNotification> get _filtered => _filter == null
      ? _store.all
      : _store.all.where((n) => n.type == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final unreadH = _store.unreadCount > 0 ? 44.0 : 0.0;
    final bottomH = unreadH + 54.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GradientAppBar(
        accent: AppColors.roleLO,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Aero India 2026 · LO Portal',
                style: TextStyle(color: AppColors.goldLight, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _store.markAllRead()),
            child: const Text('Mark all read',
                style: TextStyle(color: AppColors.goldLight, fontSize: 11)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_store.unreadCount > 0)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                  ),
                  child: Row(children: [
                    Icon(Icons.circle, size: 8, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text(
                        '${_store.unreadCount} unread '
                        'notification${_store.unreadCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      color: context.semantic.accent,
                      onTap: () => setState(() => _filter = null),
                    ),
                    ...LoNotifType.values.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: _typeLabel(t),
                            selected: _filter == t,
                            color: _typeColor(t),
                            onTap: () => setState(
                                () => _filter = _filter == t ? null : t),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RoleScaffoldBackground(
        accent: AppColors.roleLO,
        child: Column(children: [
        // ── List ─────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size:  52,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Text('No notifications',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                16, 8, 16, 80),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final n = _filtered[i];
              return _NotificationTile(
                notification: n,
                index:        i,
                onTap: () => setState(
                        () => _store.markRead(n.id)),
                onDismiss: () => setState(
                        () => _store.remove(n.id)),
              );
            },
          ),
        ),
      ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION TILE
// ═══════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  final LoNotification notification;
  final int            index;
  final VoidCallback   onTap;
  final VoidCallback   onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.index,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final n    = notification;
    final read = n.isRead;

    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0, end: 1),
      duration: Duration(
          milliseconds: 250 + (index * 50)),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child:   Transform.translate(
            offset: Offset(0, 16 * (1 - val)),
            child:  child),
      ),
      child: Dismissible(
        key:             Key(n.id),
        direction:       DismissDirection.endToStart,
        onDismissed:     (_) => onDismiss(),
        background: Container(
          alignment:    Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color:        AppColors.danger,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline,
              color: Colors.white),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: read
                  ? AppColors.surfaceCard(
                      Theme.of(context).brightness == Brightness.dark)
                  : _typeColor(n.type).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: read
                    ? context.semantic.border
                    : _typeColor(n.type)
                    .withValues(alpha: 0.3),
                width: read ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 
                      read ? 0.03 : 0.06),
                  blurRadius: read ? 4 : 8,
                  offset:     const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        _typeColor(n.type)
                        .withValues(alpha: 0.1),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(n.type),
                      size:  18,
                      color: _typeColor(n.type)),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        // Unread dot
                        if (!read) ...[
                          Container(
                            width:  7,
                            height: 7,
                            margin: const EdgeInsets
                                .only(right: 6, top: 1),
                            decoration: BoxDecoration(
                              color:  _typeColor(n.type),
                              shape:  BoxShape.circle,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(n.title,
                              style: TextStyle(
                                  fontWeight: read
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 13)),
                        ),
                        _TypeBadge(type: n.type),
                      ]),
                      const SizedBox(height: 4),
                      Text(n.body,
                          style: TextStyle(
                              fontSize: 12,
                              color:    context.semantic.textSecondary,
                              height:   1.4)),
                      const SizedBox(height: 6),
                      Text(_relativeTime(n.timestamp),
                          style: TextStyle(
                              fontSize: 10,
                              color:    context.semantic.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION BELL  (use in AppBar actions)
// ═══════════════════════════════════════════════════════════════

class LoNotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  const LoNotificationBell({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = LoNotificationStore.instance.unreadCount;
    return Stack(children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined,
            color: Colors.white),
        onPressed: onTap,
      ),
      if (count > 0)
        Positioned(
          right: 8,
          top:   8,
          child: Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(
                minWidth: 16, minHeight: 16),
            decoration: const BoxDecoration(
              color:  AppColors.danger,
              shape:  BoxShape.circle,
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   8,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ]);
  }
}

// ── Inline badge (for drawer) ─────────────────────────────────
class LoNotificationBadge extends StatelessWidget {
  const LoNotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final count = LoNotificationStore.instance.unreadCount;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              color:      Colors.white,
              fontSize:   11,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.7)
                  : Colors.white24,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? (color == context.semantic.accent
                      ? Colors.white
                      : color)
                      : Colors.white54)),
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  final LoNotifType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color:        _typeColor(type).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(_typeLabel(type),
        style: TextStyle(
            fontSize:   8,
            fontWeight: FontWeight.bold,
            color:      _typeColor(type))),
  );
}

// ═══════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════

enum LoNotifType { urgent, task, schedule, instruction, issue }

class LoNotification {
  final String      id;
  final String      title;
  final String      body;
  final LoNotifType type;
  final DateTime    timestamp;
  final bool        isRead;

  const LoNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  LoNotification copyWith({bool? isRead}) => LoNotification(
    id:        id,
    title:     title,
    body:      body,
    type:      type,
    timestamp: timestamp,
    isRead:    isRead ?? this.isRead,
  );
}

// ═══════════════════════════════════════════════════════════════
// UTILITY
// ═══════════════════════════════════════════════════════════════

Color _typeColor(LoNotifType t) => switch (t) {
  LoNotifType.urgent      => AppColors.danger,
  LoNotifType.task        => AppColors.roleLO,
  LoNotifType.schedule    => AppColors.gold,
  LoNotifType.instruction => AppColors.sky,
  LoNotifType.issue       => AppColors.warning,
};

IconData _typeIcon(LoNotifType t) => switch (t) {
  LoNotifType.urgent      => Icons.priority_high,
  LoNotifType.task        => Icons.assignment,
  LoNotifType.schedule    => Icons.event,
  LoNotifType.instruction => Icons.campaign,
  LoNotifType.issue       => Icons.report_problem,
};

String _typeLabel(LoNotifType t) => switch (t) {
  LoNotifType.urgent      => 'Urgent',
  LoNotifType.task        => 'Task',
  LoNotifType.schedule    => 'Schedule',
  LoNotifType.instruction => 'Instruction',
  LoNotifType.issue       => 'Issue',
};