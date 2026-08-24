import 'package:liaison_officer/features/liaison_officer/presentation/screens/assignedTasksPage.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo_daily_summary_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo_notifications_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo_venue_nav_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/widgets/VIPCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/contrast.dart';
import '../../core/notifications/mock_email_notifier.dart';
import '../../core/session/auth_logout.dart';
import '../../core/themes/presentation/bloc/theme_cubit.dart';
import '../../core/widgets/gradient_app_bar.dart';
import '../../core/widgets/role_profile_drawer_header.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'bloc/lo_bloc.dart';
import 'data/enum/taskStatus.dart';
import 'data/enum/taskType.dart';
import 'data/models/LoTask.dart';
import 'data/models/guestActivity.dart';
import 'data/models/lo_assignment.dart';
import 'data/models/vip.dart';
import 'data/services/upcoming_task_reminder_service.dart';
import 'presentation/screens/profile_view.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo_delegate_updates_screen.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// URL HELPERS
// ═══════════════════════════════════════════════════════════════

Future<void> _launchCall(String phone, [BuildContext? context]) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return;
  }
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Unable to start phone call'),
      ),
    );
  }
}

Future<void> _launchWhatsApp(String phone, [BuildContext? context]) async {
  final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri.parse('https://wa.me/$clean');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Unable to open WhatsApp'),
      ),
    );
  }
}

Future<void> _launchMaps(String query, [BuildContext? context]) async {
  if (query.isEmpty) return;
  final encoded = Uri.encodeComponent(query);
  final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Unable to open maps'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY LOG BUILDER  (shared with VIPCard)
// ═══════════════════════════════════════════════════════════════

List<GuestActivity> buildActivityLog(VIP vip) {
  final log = <GuestActivity>[];
  log.add(GuestActivity('Guest Created', DateTime.now()));
  if (vip.hotel.name.isNotEmpty) {
    log.add(GuestActivity(
        'Hotel Assigned: ${vip.hotel.name} (${vip.hotel.roomNumber})',
        DateTime.now()));
  }
  if (vip.transport.status.toLowerCase() == 'completed') {
    log.add(GuestActivity(
        'Transport Completed (${vip.transport.carType})',
        DateTime.now()));
  }
  if (vip.transport.arrivalTime != null) {
    log.add(GuestActivity(
        'Expected Arrival: ${vip.transport.arrivalLocation}',
        vip.transport.arrivalTime!));
  }
  if (vip.foodPreferences != null) {
    log.add(GuestActivity(
        'Catering Notified: ${vip.foodPreferences}',
        DateTime.now()));
  }
  for (final e in vip.engagements) {
    log.add(GuestActivity(
        'Engagement: ${e.eventName} (${e.rsvpStatus})',
        e.dateTime));
  }
  return log;
}

// ═══════════════════════════════════════════════════════════════
// LIAISON OFFICER SCREEN
// ═══════════════════════════════════════════════════════════════

class LiaisonOfficerScreen extends StatefulWidget {
  final String email;
  const LiaisonOfficerScreen({super.key, required this.email});

  @override
  State<LiaisonOfficerScreen> createState() => _LiaisonOfficerScreenState();
}

class _LiaisonOfficerScreenState extends State<LiaisonOfficerScreen> {
  // ── Navigation ────────────────────────────────────────────
  // Tabs: 0=VIPs  1=Tasks  2=Summary  3=Profile
  int _selectedIndex = 0;

  // ── VIP action bar ────────────────────────────────────────
  VIP? _activeVip;
  bool _showActionBar = false;
  int  _actionIndex   = 0;
  final double _barHeight = 80.0;
  final ScrollController _scrollController = ScrollController();

  /// Assigned delegate names for this LO (null = not loaded yet).
  Set<String>? _assignedNames;

  // ── Filtered VIP list ─────────────────────────────────────
  List<VIP> getFilteredVIPs(List<VIP> vips, String query, String filter) {
    final q = query.toLowerCase();
    return vips.where((v) {
      final matchSearch = q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.designation.toLowerCase().contains(q) ||
          v.organisation.toLowerCase().contains(q) ||
          v.contact.contains(q);
      final matchFilter = filter == 'All' ||
          (filter == 'Foreign') == v.isForeign;
      return matchSearch && matchFilter;
    }).toList();
  }

  // ── Task list (derived) ───────────────────────────────────
  TaskStatus _mapTransportStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return TaskStatus.completed;
      case 'in progress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }

  TaskStatus _mapRsvpStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return TaskStatus.completed;
      case 'in progress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }

  List<LOTask> _buildTasksFromVIPs(List<VIP> vips) {
    final tasks = <LOTask>[];
    for (final vip in vips) {
      tasks.add(LOTask(
        vipName: vip.name,
        type: TaskType.pickup,
        status: _mapTransportStatus(vip.transport.status),
        description:
            'Pickup via ${vip.transport.carType} (${vip.transport.driverName})',
        createdAt: DateTime.now(),
        taskIndex: 0,
      ));
      tasks.add(LOTask(
        vipName: vip.name,
        type: TaskType.hotelCheckin,
        status: vip.hotel.roomNumber.trim().isNotEmpty
            ? TaskStatus.completed
            : TaskStatus.pending,
        description: 'Hotel check-in at ${vip.hotel.name}, '
            'Room ${vip.hotel.roomNumber}',
        createdAt: DateTime.now(),
        taskIndex: 1,
      ));
      for (var i = 0; i < vip.engagements.length; i++) {
        final e = vip.engagements[i];
        tasks.add(LOTask(
          vipName: vip.name,
          type: TaskType.protocol,
          status: _mapRsvpStatus(e.rsvpStatus),
          description: 'Engagement: ${e.eventName}',
          createdAt: e.dateTime,
          taskIndex: 2 + i,
        ));
      }
    }
    return tasks;
  }

  // ── VIP card toggle callback ──────────────────────────────
  void _onVIPToggle(VIP vip, bool isOpen) {
    setState(() {
      if (isOpen) {
        _activeVip     = vip;
        _showActionBar = true;
      } else if (_activeVip == vip) {
        _activeVip     = null;
        _showActionBar = false;
      }
    });
  }

  // ── Tab navigation ────────────────────────────────────────
  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _showActionBar = false;
      _activeVip     = null;
    });
    Navigator.pop(context); // close drawer
  }

  // ── Open notifications screen ─────────────────────────────
  void _openNotifications() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const LoNotificationsScreen()));
  }

  // ── Open issue reports ────────────────────────────────────
  void _openIssueReports(List<VIP> vipList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoIssueReportPage(
          vips: vipList,
        ),
      ),
    );
  }

  // ── Open venue navigation ─────────────────────────────────
  void _openVenueNav() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const LoVenueNavScreen()));
  }

  // ── Init ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _bootstrapAssignments();
    UpcomingTaskReminderService.start(widget.email);
  }

  Future<void> _bootstrapAssignments() async {
    try {
      await LoDelegateAssignment.ensureDemoSeed(widget.email);
      await LoTaskAssignment.ensureDemoSeed(widget.email);
      final assignments = await LoDelegateAssignment.getAll();
      final mine = assignments
          .where((a) =>
              a.assignedLoEmail.trim().toLowerCase() ==
              widget.email.trim().toLowerCase())
          .map((a) => a.delegateName)
          .toSet();

      if (mine.isNotEmpty) {
        final already = LoNotificationStore.instance.all.any(
          (n) => n.id == 'assignment_seed_${widget.email}',
        );
        if (!already) {
          LoNotificationStore.instance.add(
            LoNotification(
              id: 'assignment_seed_${widget.email}',
              title: 'New delegate assignments',
              body:
                  'You have been assigned ${mine.length} delegate(s). Review profiles and travel details.',
              type: LoNotifType.task,
              timestamp: DateTime.now(),
            ),
          );
          await MockEmailNotifier.send(
            to: widget.email,
            subject: 'New LO delegate assignments',
            body:
                'You have been assigned: ${mine.join(', ')}. Open the LO portal to view details.',
          );
        }
      }

      if (!mounted) return;
      setState(() => _assignedNames = mine);
    } catch (e) {
      debugPrint('LO bootstrap assignments failed: $e');
      if (!mounted) return;
      setState(() => _assignedNames = {
            'Sharan',
            'Dr. Michael Thompson',
          });
    }
  }

  List<VIP> _assignedVips(List<VIP> all) {
    final names = _assignedNames;
    if (names == null || names.isEmpty) return all;
    final filtered = all.where((v) => names.contains(v.name)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  @override
  void dispose() {
    UpcomingTaskReminderService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoBloc, LoBlocState>(
      builder: (context, state) {
        final vipList = _assignedVips(state.vipList);
        final onDuty = state.onDuty;
        final searchQuery = state.searchQuery;
        final filterCategory = state.filterCategory;

        final tasks = _buildTasksFromVIPs(vipList);
        final pendingTaskCount = tasks.where((t) => t.status == TaskStatus.pending).length;
        final filtered = getFilteredVIPs(vipList, searchQuery, filterCategory);

        final pages = [
          // ── 0: VIPs ──────────────────────────────────────────
          _buildVipsTab(vipList, filtered, searchQuery, filterCategory),

          // ── 1: Tasks ─────────────────────────────────────────
          AssignedTasksPage(
            loEmail: widget.email,
            fallbackTasks: tasks,
            onUpdate: () => setState(() {}),
          ),

          // ── 2: Daily Summary (replaces MIS Stats) ────────────
          LoDailySummaryScreen(
            vips:     vipList,
            tasks:    tasks,
            onUpdate: () {},
            onTaskStatusChanged: (task, status) {
              context.read<LoBloc>().add(
                    LoTaskStatusChanged(
                      task.vipName,
                      task.taskIndex,
                      status,
                    ),
                  );
            },
            onVipChanged: _onVipChanged,
          ),

          // ── 3: Profile ───────────────────────────────────────
          ProfilePage(email: widget.email, assignedVIPs: vipList),
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,

          // ── AppBar ─────────────────────────────────────────────
          appBar: _buildAppBar(onDuty),

          // ── Drawer ─────────────────────────────────────────────
          drawer: _buildDrawer(context, state, pendingTaskCount, vipList, onDuty),

          body: RoleScaffoldBackground(
            accent: AppColors.roleLO,
            child: SafeArea(
              child: state.status == LoStatus.loading && vipList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.status == LoStatus.error && vipList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.errorMessage ?? 'Failed to load data',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => context
                                      .read<LoBloc>()
                                      .add(LoLoadRequested(widget.email)),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : IndexedStack(
                          index: _selectedIndex, children: pages),
            ),
          ),

          bottomNavigationBar: _buildBottomBar(pendingTaskCount),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════
  // APP BAR
  // ═════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(bool onDuty) {
    return GradientAppBar(
      accent: AppColors.roleLO,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liaison Officer',
            style: TextStyle(
                color:      Colors.white,
                fontSize:   16,
                fontWeight: FontWeight.bold),
          ),
          Text(
            widget.email,
            style: const TextStyle(
                color:   AppColors.goldLight,
                fontSize: 10),
          ),
        ],
      ),
      actions: [
        // ── Duty toggle pill ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 14),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<LoBloc>().add(LoDutyStatusToggled());
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(
                content: Text(!onDuty
                    ? 'You are now ON duty'
                    : 'You are now OFF duty'),
                backgroundColor: !onDuty
                    ? AppColors.success
                    : AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: onDuty
                    ? AppColors.success.withValues(alpha: 0.85)
                    : AppColors.warning.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    onDuty
                        ? Icons.play_circle_fill
                        : Icons.pause_circle_filled,
                    key:   ValueKey(onDuty),
                    size:  14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  onDuty ? 'On Duty' : 'Off Duty',
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   11,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ),
        ),

        // ── Notification bell (#12) ───────────────────────
        LoNotificationBell(onTap: _openNotifications),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════
  // DRAWER
  // ═════════════════════════════════════════════════════════

  Widget _buildDrawer(BuildContext context, LoBlocState state, int pendingTaskCount, List<VIP> vipList, bool onDuty) {
    return Drawer(
      child: Column(children: [
        RoleProfileDrawerHeader(
          name: 'Liaison Officer',
          role: 'Liaison Officer',
          subtitle: widget.email,
          accentColor: AppColors.roleLO,
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: onDuty ? AppColors.success.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              onDuty ? 'On Duty' : 'Off Duty',
              style: TextStyle(
                color: onDuty ? AppColors.success : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          pills: [
            DrawerStatPill(
              label: 'VIPs',
              value: '${vipList.length}',
              color: AppColors.themeSecondary,
            ),
            DrawerStatPill(
              label: 'Tasks',
              value: '$pendingTaskCount',
              color: pendingTaskCount > 0 ? AppColors.danger : AppColors.success,
            ),
          ],
          profileRows: [
            ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: widget.email,
            ),
            ProfileInfoRow(
              icon: Icons.people,
              label: 'VIPs Assigned',
              value: '${vipList.length}',
            ),
            const ProfileInfoRow(
              icon: Icons.event,
              label: 'Event',
              value: 'Liaison Officer',
            ),
            ProfileInfoRow(
              icon: Icons.task,
              label: 'Duty',
              value: onDuty ? 'On Duty' : 'Off Duty',
            ),
          ],
          onAvatarTap: () {
            Navigator.pop(context);
            setState(() {
              _selectedIndex = 3;
              _showActionBar = false;
              _activeVip     = null;
            });
          },
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            children: [

              // ── Core navigation ─────────────────────────
              _DrawerNavItem(
                icon:     Icons.people,
                label:    'Delegates',
                selected: _selectedIndex == 0,
                onTap:    () => _selectTab(0),
              ),
              _DrawerNavItem(
                icon:     Icons.task_alt,
                label:    'Tasks',
                badge:    pendingTaskCount,
                selected: _selectedIndex == 1,
                onTap:    () => _selectTab(1),
              ),
              _DrawerNavItem(
                icon:     Icons.bar_chart,
                label:    'Daily Summary',
                selected: _selectedIndex == 2,
                onTap:    () => _selectTab(2),
              ),
              _DrawerNavItem(
                icon:     Icons.person,
                label:    'Profile',
                selected: _selectedIndex == 3,
                onTap:    () => _selectTab(3),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Divider(height: 1),
              ),

              // ── Quick access tools ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    12, 6, 12, 4),
                child: Text(
                  'TOOLS',
                  style: TextStyle(
                      fontSize:     10,
                      fontWeight:   FontWeight.bold,
                      color:        context.semantic.textSecondary,
                      letterSpacing: 1.2),
                ),
              ),

              // Notifications (#12)
              _DrawerNavItem(
                icon:     Icons.notifications_outlined,
                label:    'Notifications',
                badge:    LoNotificationStore.instance.unreadCount,
                selected: false,
                onTap:    () {
                  Navigator.pop(context);
                  _openNotifications();
                },
                trailing: LoNotificationStore.instance.unreadCount > 0
                    ? LoNotificationBadge()
                    : null,
              ),

              // Issue Reports (#11)
              _DrawerNavItem(
                icon:     Icons.report_problem_outlined,
                label:    'Issue Reports',
                selected: false,
                onTap:    () {
                  Navigator.pop(context);
                  _openIssueReports(vipList);
                },
              ),

              // Venue Navigation (#13)
              _DrawerNavItem(
                icon:     Icons.map_outlined,
                label:    'Venue Navigation',
                selected: false,
                onTap:    () {
                  Navigator.pop(context);
                  _openVenueNav();
                },
              ),

              _DrawerNavItem(
                icon:     Icons.flight_takeoff_outlined,
                label:    'Travel Updates',
                selected: false,
                onTap:    () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoDelegateUpdatesScreen(vips: vipList),
                    ),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Divider(height: 1),
              ),

              // ── Settings ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    12, 6, 12, 4),
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                      fontSize:     10,
                      fontWeight:   FontWeight.bold,
                      color:        context.semantic.textSecondary,
                      letterSpacing: 1.2),
                ),
              ),

              // Duty toggle
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4),
                child: SwitchListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                  secondary: Icon(
                    onDuty
                        ? Icons.play_circle_fill
                        : Icons.pause_circle_filled,
                    color: onDuty
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  title: const Text('On Duty'),
                  subtitle: Text(
                      onDuty
                          ? 'Checked In'
                          : 'Checked Out',
                      style: const TextStyle(
                          fontSize: 11)),
                  value: onDuty,
                  onChanged: (v) {
                    context.read<LoBloc>().add(LoDutyStatusToggled());
                    Navigator.pop(context);
                  },
                ),
              ),

              // Dark mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return SwitchListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (v) {
                        context.read<ThemeCubit>().setTheme(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Divider(height: 1),
              ),

              // Logout
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12)),
                leading: const Icon(Icons.logout,
                    color: AppColors.danger),
                title: const Text('Logout',
                    style: TextStyle(
                        color:      AppColors.danger,
                        fontWeight: FontWeight.bold)),
                onTap: () => performLogout(context),
              ),
            ],
          ),
        ),

        // ── Footer ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text('Liaison Officer',
              style: TextStyle(
                  fontSize: 11,
                  color:    context.semantic.textMuted)),
        ),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════
  // VIPs TAB  (#1 — assigned delegate list)
  // ═════════════════════════════════════════════════════════

  Widget _buildVipsTab(List<VIP> vipList, List<VIP> filtered, String searchQuery, String filterCategory) {
    final cs       = Theme.of(context).colorScheme;

    return Column(children: [
      // ── Summary strip ─────────────────────────────────────
      _VipSummaryStrip(vipList: vipList),

      // ── Search bar ────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          onChanged: (v) => context.read<LoBloc>().add(LoSearchQueryChanged(v)),
          decoration: InputDecoration(
            hintText:   'Search delegates…',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () =>
                  context.read<LoBloc>().add(LoSearchQueryChanged('')),
            )
                : null,
            isDense:      true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none),
            filled:    true,
            fillColor: AppColors.inputFill(
                Theme.of(context).brightness == Brightness.dark),
          ),
        ),
      ),

      // ── Filter chips ──────────────────────────────────────
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 4),
        child: Row(
          children:
          ['All', 'Foreign', 'Domestic'].map((cat) {
            final sel = filterCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    color: sel
                        ? cs.primary
                        : Contrast.mutedLabel(context),
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected:      sel,
                onSelected:    (_) => context.read<LoBloc>().add(LoFilterChanged(cat)),
                avatar: Icon(
                  cat == 'All'
                      ? Icons.people
                      : cat == 'Foreign'
                      ? Icons.public
                      : Icons.flag,
                  size: 14,
                  color: sel
                      ? cs.primary
                      : Contrast.mutedLabel(context),
                ),
                selectedColor: cs.primary.withValues(alpha: 0.18),
                backgroundColor: Contrast.cardSurface(context),
                side: BorderSide(
                  color: sel
                      ? cs.primary.withValues(alpha: 0.5)
                      : Contrast.cardBorder(context),
                ),
                checkmarkColor: cs.primary,
              ),
            );
          }).toList(),
        ),
      ),

      // ── Count strip ───────────────────────────────────────
      if (searchQuery.isNotEmpty ||
          filterCategory != 'All')
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} of ${vipList.length} VIPs',
              style: TextStyle(
                  fontSize: 11,
                  color:    context.semantic.textSecondary),
            ),
          ),
        ),

      // ── List + sticky action bar ──────────────────────────
      Expanded(
        child: Stack(children: [
          filtered.isEmpty
              ? _emptyState(searchQuery)
              : ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                kBottomNavigationBarHeight +
                    _barHeight +
                    80),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final vip = filtered[i];
              return TweenAnimationBuilder<double>(
                tween:    Tween(begin: 0, end: 1),
                duration: Duration(
                    milliseconds: 250 + i * 60),
                curve:    Curves.easeOut,
                builder: (_, val, child) => Opacity(
                  opacity: val,
                  child:   Transform.translate(
                      offset: Offset(0, 18 * (1 - val)),
                      child:  child),
                ),
                child: Column(children: [
                  VIPCard(
                    vip:      vip,
                    allVips:  vipList,
                    onUpdate: _onVipChanged,
                    onToggle: (isOpen) =>
                        _onVIPToggle(vip, isOpen),
                  ),
                  AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 400),
                    curve:    Curves.easeOutBack,
                    height:   _activeVip == vip
                        ? 24
                        : 10,
                  ),
                ]),
              );
            },
          ),

          // ── Sticky action bar ───────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve:    Curves.easeInOut,
            left:  0,
            right: 0,
            bottom: _showActionBar ? 0 : -_barHeight,
            child: _activeVip != null
                ? _buildActionBar(context, _activeVip!, vipList)
                : const SizedBox.shrink(),
          ),
        ]),
      ),
    ]);
  }

  Widget _emptyState(String searchQuery) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off,
            size:  60,
            color: context.semantic.border),
        const SizedBox(height: 12),
        Text(
          searchQuery.isNotEmpty
              ? 'No VIPs match "$searchQuery"'
              : 'No VIPs in this category',
          style: TextStyle(
              color:    context.semantic.textSecondary,
              fontSize: 14),
        ),
      ],
    ),
  );

  // ═════════════════════════════════════════════════════════
  // VIP QUICK-ACTION BAR
  // ═════════════════════════════════════════════════════════

  Widget _buildActionBar(BuildContext context, VIP vip, List<VIP> vipList) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation:    12,
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20)),
      color: Theme.of(context).canvasColor,
      child: Container(
        height:  _barHeight,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionIcon(
              icon:     Icons.call,
              label:    'Call',
              isActive: _actionIndex == 0,
              cs:       cs,
              onTap:    () {
                setState(() => _actionIndex = 0);
                _launchCall(vip.contact, context);
              },
            ),
            _actionIcon(
              icon:     Icons.message,
              label:    'WhatsApp',
              isActive: _actionIndex == 1,
              cs:       cs,
              onTap:    () {
                setState(() => _actionIndex = 1);
                _launchWhatsApp(vip.contact, context);
              },
            ),
            _actionIcon(
              icon:     Icons.map,
              label:    'Navigate',
              isActive: _actionIndex == 2,
              cs:       cs,
              onTap:    () {
                setState(() => _actionIndex = 2);
                final dest = vip.hotel.name.isNotEmpty
                    ? '${vip.hotel.name} Bangalore'
                    : (vip.transport.arrivalLocation ?? '');
                _launchMaps(dest, context);
              },
            ),
            _actionIcon(
              icon:     Icons.report_problem_outlined,
              label:    'Issue',
              isActive: _actionIndex == 3,
              cs:       cs,
              onTap:    () {
                setState(() => _actionIndex = 3);
                // Open issue sheet pre-filled for this VIP
                LoIssueReportSheet.show(
                  context,
                  vips:           vipList,
                  preselectedVip: vip,
                );
              },
            ),
            _actionIcon(
              icon:     Icons.close,
              label:    'Dismiss',
              isActive: false,
              cs:       cs,
              onTap:    () => setState(() {
                _showActionBar = false;
                _activeVip     = null;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData     icon,
    required String       label,
    required bool         isActive,
    required ColorScheme  cs,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: isActive ? 1.15 : 1.0,
              child: Icon(icon,
                  size:  20,
                  color: isActive
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.6))),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve:    Curves.easeInOut,
              height:   3,
              width:    isActive ? 20 : 5,
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═════════════════════════════════════════════════════════

  Widget _buildBottomBar(int pendingTaskCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppColors.roleLO;
    final items = [
      (Icons.people,         Icons.people_outline,     'Delegates'),
      (Icons.task_alt,       Icons.task,               'Tasks'),
      (Icons.bar_chart,      Icons.bar_chart_outlined,  'Summary'),
      (Icons.person,         Icons.person_outline,      'Profile'),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppTheme.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? context.semantic.border : AppTheme.lightBorder,
            width: 1.2,
          ),
        ),
        boxShadow: AppTheme.glowShadow(accent, opacity: isDark ? 0.12 : 0.06),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item  = items[index];
          final isAct = _selectedIndex == index;

          // Tasks tab gets a pending-count badge
          final hasBadge =
              index == 1 && pendingTaskCount > 0;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedIndex = index;
              _showActionBar = false;
              _activeVip     = null;
            }),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize:     MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(clipBehavior: Clip.none, children: [
                    AnimatedScale(
                      scale:    isAct ? 1.2 : 1.0,
                      duration: const Duration(
                          milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AnimatedSwitcher(
                        duration: const Duration(
                            milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(
                                scale: anim, child: child),
                        child: Icon(
                          isAct
                              ? item.$1
                              : item.$2,
                          key:   ValueKey(isAct),
                          color: isAct
                              ? accent
                              : context.semantic.textMuted,
                        ),
                      ),
                    ),
                    if (hasBadge)
                      Positioned(
                        top:  -4,
                        right: -8,
                        child: Container(
                          width:  15, height: 15,
                          decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '$pendingTaskCount',
                              style: const TextStyle(
                                  color:      Colors.white,
                                  fontSize:   8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(
                        milliseconds: 300),
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.bold,
                      color: isAct
                          ? accent
                          : context.semantic.textMuted,
                    ),
                    child: Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 300),
                    curve:  Curves.easeInOut,
                    height: 3,
                    width:  isAct ? 28 : 0,
                    decoration: BoxDecoration(
                      color: isAct
                          ? accent
                          : Colors.transparent,
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onVipChanged(VIP vip) {
    context.read<LoBloc>().add(LoVipUpdated(vip));
  }
}

// ═══════════════════════════════════════════════════════════════
// VIP SUMMARY STRIP  (top of VIPs tab)
// ═══════════════════════════════════════════════════════════════

class _VipSummaryStrip extends StatelessWidget {
  final List<VIP> vipList;
  const _VipSummaryStrip({required this.vipList});

  @override
  Widget build(BuildContext context) {
    if (vipList.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = vipList.length;
    final foreign = vipList.where((v) => v.isForeign).length;
    final pending =
        vipList.where((v) => v.transport.status != 'Completed').length;
    final done = vipList.fold<int>(0, (s, v) => s + v.completedTasks);
    final allTasks = vipList.fold<int>(0, (s, v) => s + v.totalTasks);
    final pct = allTasks > 0 ? done / allTasks : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Contrast.cardSurface(context),
        border: Border(
          bottom: BorderSide(color: Contrast.cardBorder(context)),
        ),
      ),
      child: Column(children: [
        Row(
          children: [
            Expanded(
              child: _Strip(
                  'Delegates', '$total', AppColors.roleLO, Icons.people),
            ),
            Expanded(
              child: _Strip(
                  'Foreign', '$foreign', AppColors.gold, Icons.public),
            ),
            Expanded(
              child: _Strip(
                'Pending',
                '$pending',
                pending > 0 ? AppColors.warning : AppColors.success,
                Icons.pending_actions,
              ),
            ),
            Expanded(
              child: _Strip(
                'Tasks',
                '${(pct * 100).round()}%',
                AppColors.sky,
                Icons.task_alt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct == 1 ? AppColors.success : AppColors.roleLO,
            ),
          ),
        ),
      ]),
    );
  }
}

class _Strip extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Strip(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final muted = Contrast.mutedLabel(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DRAWER NAV ITEM
// ═══════════════════════════════════════════════════════════════

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final Widget? trailing;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Stack(clipBehavior: Clip.none, children: [
        Icon(icon,
            color: selected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.6)),
        if (badge > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ]),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? cs.primary : cs.onSurface,
        ),
      ),
      trailing: trailing,
      selected: selected,
      selectedTileColor: cs.primary.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}
