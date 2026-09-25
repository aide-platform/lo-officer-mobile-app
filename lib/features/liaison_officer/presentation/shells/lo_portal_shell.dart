import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/core/widgets/role_shell_drawer.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/notifications_inbox_screen.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LoPortalShell extends StatefulWidget {
  const LoPortalShell({
    super.key,
    required this.email,
    required this.roleLabel,
  });

  final String email;
  final String roleLabel;

  @override
  State<LoPortalShell> createState() => _LoPortalShellState();
}

class _LoPortalShellState extends State<LoPortalShell> {
  int _index = 0;
  int _unread = 0;
  bool _wizardPrompted = false;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final n =
          await AppDependencies.instance.notificationsRepository.unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  void _openProfile(BuildContext context, {required bool forceWizard}) {
    final bloc = context.read<LoPortalBloc>();
    final complete = bloc.state.profile?.profileComplete == true;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _ProfilePage(
            email: widget.email,
            readOnly: complete && !forceWizard,
          ),
        ),
      ),
    );
  }

  void _openInbox(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsInboxScreen(
          onOpenDeepLink: (link) {
            // Soft deep-link: switch to Tasks when link mentions task.
            if (link.toLowerCase().contains('task')) {
              setState(() => _index = 1);
            } else if (link.toLowerCase().contains('delegate')) {
              setState(() => _index = 0);
            }
          },
        ),
      ),
    )
        .then((_) => _refreshUnread());
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Delegates', 'Tasks', 'Alerts'];
    final pages = [
      _DelegatesTab(email: widget.email),
      const _TasksTab(),
      const _AlertsTab(),
    ];

    return AdaptiveRoleScaffold(
      title: titles[_index.clamp(0, titles.length - 1)],
      drawer: RoleShellDrawer(
        email: widget.email,
        roleLabel: widget.roleLabel,
        navItems: [
          RoleDrawerNavItem(
            icon: Icons.groups_outlined,
            label: 'Delegates',
            onTap: () => setState(() => _index = 0),
          ),
          RoleDrawerNavItem(
            icon: Icons.task_alt_outlined,
            label: 'Tasks',
            onTap: () => setState(() => _index = 1),
          ),
          RoleDrawerNavItem(
            icon: Icons.notifications_outlined,
            label: 'Alerts',
            onTap: () => setState(() => _index = 2),
          ),
          RoleDrawerNavItem(
            icon: Icons.person_outline,
            label: 'My Profile',
            onTap: () => _openProfile(context, forceWizard: false),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openInbox(context),
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Account',
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
          onSelected: (v) {
            switch (v) {
              case 'profile':
                _openProfile(context, forceWizard: false);
              case 'help':
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                );
              case 'theme':
                context.read<ThemeCubit>().toggle();
              case 'logout':
                performLogout(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text('My Profile')),
            PopupMenuItem(value: 'help', child: Text('Help & Support')),
            PopupMenuItem(value: 'theme', child: Text('Toggle theme')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
      body: BlocConsumer<LoPortalBloc, LoPortalState>(
        listener: (context, state) async {
          final bloc = context.read<LoPortalBloc>();
          if (!_wizardPrompted &&
              state.status == LoPortalStatus.ready &&
              state.profile?.profileComplete != true) {
            _wizardPrompted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openProfile(context, forceWizard: true);
            });
          }
          if (state.lastDownloadBytes != null &&
              state.lastDownloadBytes!.isNotEmpty) {
            final bytes = state.lastDownloadBytes!;
            final name = state.lastDownloadFilename ?? 'badge.pdf';
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/$name');
            await file.writeAsBytes(bytes);
            await Share.shareXFiles([XFile(file.path)], text: name);
          }
          if (!context.mounted) return;
          if (state.infoMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(state.infoMessage!),
              ),
            );
          }
          if (state.infoMessage != null ||
              state.lastDownloadBytes != null) {
            bloc.add(LoPortalClearMessages());
          }
        },
        builder: (context, state) {
          if (state.status == LoPortalStatus.loading ||
              state.status == LoPortalStatus.initial) {
            return const AppLoading(label: 'Loading portal…');
          }
          if (state.status == LoPortalStatus.failure &&
              state.delegates.isEmpty &&
              state.profile == null) {
            return AppErrorView(
              message: state.errorMessage ?? 'Failed to load',
              onRetry: () =>
                  context.read<LoPortalBloc>().add(LoPortalLoadRequested()),
            );
          }
          final showCacheBanner = state.status == LoPortalStatus.ready &&
              state.errorMessage != null &&
              state.errorMessage!.toLowerCase().contains('cached');
          return Column(
            children: [
              if (showCacheBanner)
                Material(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<LoPortalBloc>()
                              .add(LoPortalLoadRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: AppTabFade(index: _index, children: pages),
              ),
            ],
          );
        },
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Delegates',
        ),
        NavigationDestination(
          icon: Icon(Icons.task_alt_outlined),
          selectedIcon: Icon(Icons.task_alt),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
      ],
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
    );
  }
}

class _DelegatesTab extends StatelessWidget {
  const _DelegatesTab({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.delegates.isEmpty) {
          return const AppEmptyState(
            message: 'No delegates assigned yet.',
            icon: Icons.person_off_outlined,
          );
        }
        return StaggeredList(
          itemCount: state.delegates.length,
          itemBuilder: (context, i) {
            final d = state.delegates[i];
            return AppCard(
              onTap: () => _openDelegateDetail(context, d),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.fullName ?? 'Delegate',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      AppStatusChip(
                        label: _foreignDomesticLabel(d.delegateType),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(d.designation ?? ''),
                  if (d.countryName != null && d.countryName!.isNotEmpty)
                    Text(d.countryName!),
                  Text(
                    'Arr ${d.arrivalDate ?? '—'} · Dep ${d.departureDate ?? '—'}',
                    style: TextStyle(
                      color: AppTheme.activeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openDelegateDetail(BuildContext context, MyLoAssignmentDto d) {
    final bloc = context.read<LoPortalBloc>();
    final assignmentId = d.assignmentId;
    if (assignmentId != null) {
      bloc.add(LoPortalDelegateExtrasRequested(assignmentId));
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _DelegateDetailPage(delegate: d),
        ),
      ),
    );
  }

  String _foreignDomesticLabel(String? type) {
    final t = (type ?? '').toUpperCase();
    if (t.contains('FOREIGN') || t.contains('INTL') || t.contains('INTERNATIONAL')) {
      return 'Foreign';
    }
    if (t.contains('DOMESTIC') || t.contains('INDIA') || t.contains('NATIONAL')) {
      return 'Domestic';
    }
    return t.isEmpty ? 'Delegate' : type!;
  }
}

class _DelegateDetailPage extends StatelessWidget {
  const _DelegateDetailPage({required this.delegate});
  final MyLoAssignmentDto delegate;

  @override
  Widget build(BuildContext context) {
    final d = delegate;
    final assignmentId = d.assignmentId;
    return Scaffold(
      appBar: AppBar(title: Text(d.fullName ?? 'Delegate')),
      body: BlocBuilder<LoPortalBloc, LoPortalState>(
        builder: (context, state) {
          final live = () {
            if (assignmentId == null) return d;
            for (final e in state.delegates) {
              if (e.assignmentId == assignmentId) return e;
            }
            return d;
          }();
          final arrivalConnecting = assignmentId == null
              ? const <ConnectingFlightDraft>[]
              : state.arrivalConnectingByAssignment[assignmentId] ?? const [];
          final departureConnecting = assignmentId == null
              ? const <ConnectingFlightDraft>[]
              : state.departureConnectingByAssignment[assignmentId] ?? const [];
          final vehicles = assignmentId == null
              ? const <Map<String, dynamic>>[]
              : state.vehiclesByAssignment[assignmentId] ?? const [];
          final nominations = assignmentId == null
              ? const <Map<String, dynamic>>[]
              : state.nominationsByAssignment[assignmentId] ?? const [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                live.fullName ?? '',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              _detailKv('Designation', live.designation),
              _detailKv('Organisation', live.organisation),
              _detailKv('Ministry', live.ministry),
              _detailKv('Gender', live.gender),
              _detailKv('Protocol', live.protocolEquiv),
              _detailKv('VIP category', live.vipCategory),
              _detailKv('Country', live.countryName),
              _detailLinkKv(
                context,
                'Email',
                live.email,
                () => _launchUri(Uri(
                  scheme: 'mailto',
                  path: live.email,
                )),
              ),
              _detailLinkKv(
                context,
                'Mobile',
                live.mobileNumber,
                () => _launchUri(Uri(
                  scheme: 'tel',
                  path: live.mobileNumber,
                )),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Accommodation & day schedules appear here when CAP returns those fields on the assignment payload.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              if (live.family.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Family',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                ...live.family.map(
                  (f) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(f.fullName ?? ''),
                    subtitle: Text(
                      [f.relation, f.gender]
                          .whereType<String>()
                          .where((e) => e.isNotEmpty)
                          .join(' · '),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Transport',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              if (vehicles.isEmpty)
                const Text('No vehicles assigned.')
              else
                ...vehicles.map(
                  (v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.directions_car_outlined),
                    title: Text(
                      '${v['vehicleType'] ?? 'Vehicle'} · ${v['vehicleNumber'] ?? ''}',
                    ),
                    subtitle: Text(
                      [
                        if (v['driverName'] != null)
                          'Driver: ${v['driverName']}',
                        if (v['driverContact'] != null)
                          v['driverContact'].toString(),
                      ].join(' · '),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text('Event nominations',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              if (nominations.isEmpty)
                const Text('No event nominations.')
              else
                ...nominations.map(
                  (n) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(n['eventName']?.toString() ?? 'Event'),
                    subtitle: Text(
                      [n['eventDate'], n['eventTime'], n['venue']]
                          .where((e) =>
                              e != null && e.toString().trim().isNotEmpty)
                          .join(' · '),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Travel',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Arrival: ${live.arrivalFlight ?? '—'} · ${live.arrivalDate ?? ''} ${live.arrivalTime ?? ''}',
              ),
              Text(
                'Departure: ${live.departureFlight ?? '—'} · ${live.departureDate ?? ''} ${live.departureTime ?? ''}',
              ),
              if (arrivalConnecting.isNotEmpty)
                Text(
                  'Arrival connecting: ${arrivalConnecting.map((c) => c.flightNumber).where((e) => e.isNotEmpty).join(', ')}',
                ),
              if (departureConnecting.isNotEmpty)
                Text(
                  'Departure connecting: ${departureConnecting.map((c) => c.flightNumber).where((e) => e.isNotEmpty).join(', ')}',
                ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  _TravelTab().openEditor(
                    context,
                    live,
                    arrivalConnecting,
                    departureConnecting,
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Update travel details'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _detailKv(String k, String? v) {
  if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

Widget _detailLinkKv(
  BuildContext context,
  String k,
  String? v,
  VoidCallback onTap,
) {
  if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Text(
              v,
              style: TextStyle(
                color: AppTheme.activeAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _launchUri(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.tasks.isEmpty) {
          return const AppEmptyState(message: 'No tasks assigned.');
        }
        final grouped = <String, List<LoTaskDto>>{};
        for (final t in state.tasks) {
          final key = t.delegateName ?? 'Unassigned';
          grouped.putIfAbsent(key, () => []).add(t);
        }
        final keys = grouped.keys.toList();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: keys.length,
          itemBuilder: (context, i) {
            final delegate = keys[i];
            final tasks = grouped[delegate]!;
            final total = tasks.length;
            final pending = tasks
                .where((t) =>
                    (t.statusCode ?? '').toUpperCase().contains('PEND') ||
                    (t.statusName ?? '').toUpperCase().contains('PEND'))
                .length;
            final inProgress = tasks
                .where((t) =>
                    (t.statusCode ?? '').toUpperCase().contains('PROGRESS') ||
                    (t.statusName ?? '').toUpperCase().contains('PROGRESS'))
                .length;
            final completed = tasks
                .where((t) =>
                    (t.statusCode ?? '').toUpperCase().contains('COMPLETE') ||
                    (t.statusName ?? '').toUpperCase().contains('COMPLETE'))
                .length;
            return AppCard(
              child: ExpansionTile(
                initiallyExpanded: i == 0,
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  delegate,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Total $total · Pending $pending · In progress $inProgress · Done $completed',
                ),
                children: tasks.map((t) => _TaskTile(task: t)).toList(),
              ),
            );
          },
        );
      },
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
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
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
              labelText: 'Remarks (optional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      remarks.dispose();
      return;
    }
    context.read<LoPortalBloc>().add(
          LoPortalTaskStatusUpdated(
            taskId: task.id!,
            statusCode: status,
            remarks: remarks.text.trim().isEmpty ? null : remarks.text.trim(),
          ),
        );
    remarks.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(task.taskTitle ?? ''),
      subtitle: Text(
        [
          task.taskDescription,
          if (task.scheduledDate != null)
            '${task.scheduledDate} ${task.scheduledTime ?? ''}',
          task.locationVenue,
        ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
      ),
      trailing: IconButton(
        tooltip: 'Update status',
        onPressed: () => _updateStatus(context),
        icon: AppStatusChip(label: task.statusName ?? task.statusCode ?? '—'),
      ),
    );
  }
}

class _TravelTab extends StatelessWidget {
  const _TravelTab();

  Future<void> openEditor(
    BuildContext context,
    MyLoAssignmentDto d,
    List<ConnectingFlightDraft> seededArrival,
    List<ConnectingFlightDraft> seededDeparture,
  ) =>
      _editTravel(context, d, seededArrival, seededDeparture);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.delegates.isEmpty) {
          return const AppEmptyState(message: 'No travel records.');
        }
        return StaggeredList(
          itemCount: state.delegates.length,
          itemBuilder: (context, i) {
            final d = state.delegates[i];
            final arrivalConnecting = d.assignmentId == null
                ? const <ConnectingFlightDraft>[]
                : state.arrivalConnectingByAssignment[d.assignmentId!] ??
                    const [];
            final departureConnecting = d.assignmentId == null
                ? const <ConnectingFlightDraft>[]
                : state.departureConnectingByAssignment[d.assignmentId!] ??
                    const [];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.fullName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arrival: ${d.arrivalFlight ?? '—'} · ${d.arrivalDate ?? ''} ${d.arrivalTime ?? ''}',
                  ),
                  Text(
                    'Departure: ${d.departureFlight ?? '—'} · ${d.departureDate ?? ''} ${d.departureTime ?? ''}',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => openEditor(
                        context,
                        d,
                        arrivalConnecting,
                        departureConnecting,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Update'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final existing = DateTime.tryParse(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    controller.text = '$y-$m-$d';
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay initial = TimeOfDay.now();
    final parts = controller.text.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h, minute: m);
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    controller.text = '$h:$m';
  }

  Widget _dateTimeField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool isDate,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(
          isDate ? Icons.calendar_today_outlined : Icons.access_time,
        ),
      ),
      onTap: () => isDate
          ? _pickDate(context, controller)
          : _pickTime(context, controller),
    );
  }

  Widget _connectingSection({
    required String title,
    required List<ConnectingFlightDraft> flights,
    required void Function(List<ConnectingFlightDraft>) onChanged,
    required void Function(void Function()) setLocal,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setLocal(() {
                  onChanged([...flights, const ConnectingFlightDraft()]);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        ...List.generate(flights.length, (i) {
          final f = flights[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Leg ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          setLocal(() {
                            onChanged([...flights]..removeAt(i));
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: f.flightNumber,
                    decoration:
                        const InputDecoration(labelText: 'Flight number'),
                    onChanged: (v) {
                      final next = [...flights];
                      next[i] = ConnectingFlightDraft(
                        flightNumber: v,
                        terminal: flights[i].terminal,
                        date: flights[i].date,
                        time: flights[i].time,
                      );
                      onChanged(next);
                    },
                  ),
                  TextFormField(
                    initialValue: f.terminal,
                    decoration: const InputDecoration(labelText: 'Terminal'),
                    onChanged: (v) {
                      final next = [...flights];
                      next[i] = ConnectingFlightDraft(
                        flightNumber: flights[i].flightNumber,
                        terminal: v,
                        date: flights[i].date,
                        time: flights[i].time,
                      );
                      onChanged(next);
                    },
                  ),
                  TextFormField(
                    initialValue: f.date,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final existing = DateTime.tryParse(flights[i].date);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: existing ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked == null) return;
                      final y = picked.year.toString().padLeft(4, '0');
                      final m = picked.month.toString().padLeft(2, '0');
                      final d = picked.day.toString().padLeft(2, '0');
                      setLocal(() {
                        final next = [...flights];
                        next[i] = ConnectingFlightDraft(
                          flightNumber: flights[i].flightNumber,
                          terminal: flights[i].terminal,
                          date: '$y-$m-$d',
                          time: flights[i].time,
                        );
                        onChanged(next);
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: f.time,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () async {
                      TimeOfDay initial = TimeOfDay.now();
                      final parts = flights[i].time.split(':');
                      if (parts.length >= 2) {
                        final h = int.tryParse(parts[0]);
                        final m = int.tryParse(parts[1]);
                        if (h != null && m != null) {
                          initial = TimeOfDay(hour: h, minute: m);
                        }
                      }
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initial,
                      );
                      if (picked == null) return;
                      final h = picked.hour.toString().padLeft(2, '0');
                      final m = picked.minute.toString().padLeft(2, '0');
                      setLocal(() {
                        final next = [...flights];
                        next[i] = ConnectingFlightDraft(
                          flightNumber: flights[i].flightNumber,
                          terminal: flights[i].terminal,
                          date: flights[i].date,
                          time: '$h:$m',
                        );
                        onChanged(next);
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editTravel(
    BuildContext context,
    MyLoAssignmentDto d,
    List<ConnectingFlightDraft> seededArrival,
    List<ConnectingFlightDraft> seededDeparture,
  ) async {
    final arrivalFlight = TextEditingController(text: d.arrivalFlight);
    final arrivalTerminal = TextEditingController(text: d.arrivalTerminal);
    final arrivalDate = TextEditingController(text: d.arrivalDate);
    final arrivalTime = TextEditingController(text: d.arrivalTime);
    final departureFlight = TextEditingController(text: d.departureFlight);
    final departureTerminal = TextEditingController(text: d.departureTerminal);
    final departureDate = TextEditingController(text: d.departureDate);
    final departureTime = TextEditingController(text: d.departureTime);

    var arrivalFlights = seededArrival
        .map(
          (e) => ConnectingFlightDraft(
            flightNumber: e.flightNumber,
            terminal: e.terminal,
            date: e.date,
            time: e.time,
          ),
        )
        .toList();
    var departureFlights = seededDeparture
        .map(
          (e) => ConnectingFlightDraft(
            flightNumber: e.flightNumber,
            terminal: e.terminal,
            date: e.date,
            time: e.time,
          ),
        )
        .toList();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Travel — ${d.fullName ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: arrivalFlight,
                    decoration:
                        const InputDecoration(labelText: 'Arrival flight'),
                  ),
                  TextField(
                    controller: arrivalTerminal,
                    decoration:
                        const InputDecoration(labelText: 'Arrival terminal'),
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: arrivalDate,
                    label: 'Arrival date',
                    isDate: true,
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: arrivalTime,
                    label: 'Arrival time',
                    isDate: false,
                  ),
                  TextField(
                    controller: departureFlight,
                    decoration:
                        const InputDecoration(labelText: 'Departure flight'),
                  ),
                  TextField(
                    controller: departureTerminal,
                    decoration: const InputDecoration(
                      labelText: 'Departure terminal',
                    ),
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: departureDate,
                    label: 'Departure date',
                    isDate: true,
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: departureTime,
                    label: 'Departure time',
                    isDate: false,
                  ),
                  const SizedBox(height: 16),
                  _connectingSection(
                    title: 'Arrival connecting flights',
                    flights: arrivalFlights,
                    onChanged: (v) => arrivalFlights = v,
                    setLocal: setLocal,
                    context: ctx,
                  ),
                  const SizedBox(height: 12),
                  _connectingSection(
                    title: 'Departure connecting flights',
                    flights: departureFlights,
                    onChanged: (v) => departureFlights = v,
                    setLocal: setLocal,
                    context: ctx,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved == true && context.mounted && d.assignmentId != null) {
      context.read<LoPortalBloc>().add(
            LoPortalTravelUpdated(
              assignmentId: d.assignmentId!,
              body: {
                'arrivalFlight': arrivalFlight.text.trim(),
                'arrivalTerminal': arrivalTerminal.text.trim(),
                'arrivalDate': arrivalDate.text.trim(),
                'arrivalTime': arrivalTime.text.trim(),
                'departureFlight': departureFlight.text.trim(),
                'departureTerminal': departureTerminal.text.trim(),
                'departureDate': departureDate.text.trim(),
                'departureTime': departureTime.text.trim(),
                'arrivalConnectingFlights':
                    arrivalFlights.map((e) => e.toJson()).toList(),
                'departureConnectingFlights':
                    departureFlights.map((e) => e.toJson()).toList(),
              },
            ),
          );
    }

    arrivalFlight.dispose();
    arrivalTerminal.dispose();
    arrivalDate.dispose();
    arrivalTime.dispose();
    departureFlight.dispose();
    departureTerminal.dispose();
    departureDate.dispose();
    departureTime.dispose();
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  static const _leadOptions = [15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final lead = _leadOptions.contains(state.alertLeadMinutes)
            ? state.alertLeadMinutes
            : 60;

        return Column(
          children: [
            AppCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Alert lead time',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DropdownButton<int>(
                    value: lead,
                    items: _leadOptions
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m min'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      context
                          .read<LoPortalBloc>()
                          .add(LoPortalAlertLeadMinutesChanged(v));
                    },
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => context
                        .read<LoPortalBloc>()
                        .add(LoPortalAlertsRefreshRequested()),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsInboxScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Open CAP notification inbox'),
                ),
              ),
            ),
            Expanded(
              child: state.alerts.isEmpty
                  ? AppEmptyState(
                      message:
                          'No notifications yet.\nAssignment, travel, and task alerts appear here.',
                      icon: Icons.notifications_none_outlined,
                      action: TextButton(
                        onPressed: () => context
                            .read<LoPortalBloc>()
                            .add(LoPortalAlertsRefreshRequested()),
                        child: const Text('Refresh'),
                      ),
                    )
                  : StaggeredList(
                      itemCount: state.alerts.length,
                      itemBuilder: (context, i) {
                        final a = state.alerts[i];
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.campaign_outlined,
                              color: AppTheme.activeAccent,
                            ),
                            title: Text(
                              a['title']?.toString() ?? 'Alert',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${a['body'] ?? ''}\n${a['at'] ?? ''}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.email, this.readOnly = false});
  final String email;
  final bool readOnly;

  static int calcAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  static const _salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _languageOptions = [
    'English',
    'Hindi',
    'Kannada',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
    'Gujarati',
  ];

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _designation = TextEditingController();
  final _rank = TextEditingController();
  final _officialEmail = TextEditingController();
  final _personalEmail = TextEditingController();
  final _personalContact = TextEditingController();
  final _officialContact = TextEditingController();
  final _whatsapp = TextEditingController();
  final _aadhaar = TextEditingController();
  final _orgId = TextEditingController();

  String _salutation = 'Mr';
  String _gender = 'Male';
  DateTime? _dob;
  /// null = custom WhatsApp; 'official' or 'personal' = mirror that contact.
  String? _whatsappSameAs;
  bool _hasPrevLoExp = false;
  bool _seeded = false;
  int _step = 0; // 0 Personal, 1 Documents, 2 Prior Experience

  final Map<LoUploadKind, String> _uploadNames = {};
  Uint8List? _pendingPhotoBytes;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _designation.dispose();
    _rank.dispose();
    _officialEmail.dispose();
    _personalEmail.dispose();
    _personalContact.dispose();
    _officialContact.dispose();
    _whatsapp.dispose();
    _aadhaar.dispose();
    _orgId.dispose();
    super.dispose();
  }

  void _seed(LiaisonOfficerDto? p) {
    if (_seeded || p == null) return;
    _first.text = p.firstName ?? '';
    _last.text = p.lastName ?? '';
    _designation.text = p.designation ?? '';
    _rank.text = p.rank ?? '';
    _officialEmail.text = p.officialEmail ?? widget.email;
    _personalEmail.text = p.personalEmail ?? '';
    _personalContact.text = p.personalContact ?? '';
    _officialContact.text = p.officialContact ?? '';
    _whatsapp.text = p.whatsappNumber ?? '';
    _aadhaar.text = p.aadhaarNumber ?? '';
    _orgId.text = p.orgIdNumber ?? '';
    if (p.salutationName != null &&
        _salutations.contains(p.salutationName)) {
      _salutation = p.salutationName!;
    }
    if (p.genderName != null && _genders.contains(p.genderName)) {
      _gender = p.genderName!;
    }
    if (p.dateOfBirth != null && p.dateOfBirth!.isNotEmpty) {
      _dob = DateTime.tryParse(p.dateOfBirth!);
    }
    _hasPrevLoExp = p.hasPrevLoExp ?? false;
    if (_whatsapp.text.isNotEmpty) {
      if (_whatsapp.text == _officialContact.text) {
        _whatsappSameAs = 'official';
      } else if (_whatsapp.text == _personalContact.text) {
        _whatsappSameAs = 'personal';
      }
    }
    _seeded = true;
  }

  void _syncWhatsappFromSource() {
    // Kept for future WhatsApp mirror UI.
    if (_whatsappSameAs == 'official') {
      _whatsapp.text = _officialContact.text;
    } else if (_whatsappSameAs == 'personal') {
      _whatsapp.text = _personalContact.text;
    }
  }

  // ignore: unused_element
  void _applyWhatsappMirror() => _syncWhatsappFromSource();

  String _dobLabel() {
    if (_dob == null) return 'Select date of birth';
    final d = _dob!;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _dob = picked);
  }

  Future<void> _pickUpload(LoUploadKind kind, String label) async {
    final file = await ImagePickService.pickImageWithChooser(context);
    if (file == null || !mounted) return;
    // Defer API upload until final Submit (wizard / edit).
    setState(() {
      _uploadNames[kind] = file.filename;
      if (kind == LoUploadKind.photo) {
        _pendingPhotoBytes = file.bytes;
      }
    });
    context.read<LoPortalBloc>().add(
          LoPortalUploadRequested(
            kind: kind,
            bytes: file.bytes,
            filename: file.filename,
          ),
        );
  }

  Widget _uploadRow(LoUploadKind kind, String label) {
    return AppImageThumbRow(
      label: label,
      bytes: kind == LoUploadKind.photo ? _pendingPhotoBytes : null,
      onPick: () => _pickUpload(kind, label),
      onClear: () => setState(() {
        _uploadNames.remove(kind);
        if (kind == LoUploadKind.photo) {
          _pendingPhotoBytes = null;
        }
      }),
    );
  }

  Future<void> _addExperience() async {
    final eventName = TextEditingController();
    final year = TextEditingController();
    final role = TextEditingController();
    final delegateDetails = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventName,
                decoration: const InputDecoration(labelText: 'Event name'),
              ),
              TextField(
                controller: year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              TextField(
                controller: role,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              TextField(
                controller: delegateDetails,
                decoration:
                    const InputDecoration(labelText: 'Delegate details'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<LoPortalBloc>().add(
            LoPortalExperienceAdded({
              'eventName': eventName.text.trim(),
              'year': int.tryParse(year.text.trim()),
              'roleResponsibilities': role.text.trim(),
              'delegateDetails': delegateDetails.text.trim(),
            }),
          );
    }

    eventName.dispose();
    year.dispose();
    role.dispose();
    delegateDetails.dispose();
  }

  void _saveLanguages(List<String> selected) {
    context.read<LoPortalBloc>().add(LoPortalLanguagesSaved(selected));
  }

  void _submit(LoPortalState state) {
    final selected = List<String>.from(state.languages);
    _saveLanguages(selected);
    context.read<LoPortalBloc>().add(
          LoPortalProfileSaved({
            'salutation': _salutation,
            'firstName': _first.text.trim(),
            'lastName': _last.text.trim(),
            'genderName': _gender,
            'dateOfBirth': _dob == null ? null : _dobLabel(),
            'rank': _rank.text.trim(),
            'designation': _designation.text.trim(),
            'orgIdNumber': _orgId.text.trim(),
            'aadhaarNumber': _aadhaar.text.trim(),
            'officialEmail': _officialEmail.text.trim(),
            'personalEmail': _personalEmail.text.trim(),
            'officialContact': _officialContact.text.trim(),
            'personalContact': _personalContact.text.trim(),
            'whatsappNumber': _whatsapp.text.trim(),
            'hasPrevLoExp': _hasPrevLoExp,
            'profileStatus': 'SUBMITTED',
            'profileComplete': true,
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoPortalBloc, LoPortalState>(
      listener: (context, state) {
        if (state.status == LoPortalStatus.ready &&
            state.profile?.profileComplete == true &&
            !widget.readOnly) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Profile saved'),
            ),
          );
          Navigator.of(context).maybePop();
        }
        if (state.status == LoPortalStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.errorMessage!),
            ),
          );
        }
      },
      builder: (context, state) {
        _seed(state.profile);
        final p = state.profile;
        final age = _dob == null ? null : _ProfilePage.calcAge(_dob!);

        if (widget.readOnly) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              actions: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => BlocProvider.value(
                          value: context.read<LoPortalBloc>(),
                          child: _ProfilePage(
                            email: widget.email,
                            readOnly: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?.fullName ?? '${_first.text} ${_last.text}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(widget.email),
                      Text('Org: ${p?.orgName ?? '—'}'),
                      const SizedBox(height: 8),
                      AppStatusChip(label: p?.profileStatus ?? 'SUBMITTED'),
                      if (p?.currentPassId != null &&
                          p!.currentPassId!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        if (p.currentPassNumber != null)
                          Text('Badge: ${p.currentPassNumber}'),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => context.read<LoPortalBloc>().add(
                                LoPortalBadgeDownloadRequested(
                                  passId: p.currentPassId!,
                                  filename:
                                      'badge-${p.currentPassNumber ?? p.currentPassId}.pdf',
                                ),
                              ),
                          icon: const Icon(Icons.badge_outlined),
                          label: const Text('Download badge'),
                        ),
                      ],
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      _detailKv('Designation', p?.designation ?? _designation.text),
                      _detailKv('Rank', p?.rank ?? _rank.text),
                      _detailKv('Gender', p?.genderName ?? _gender),
                      _detailKv('DOB', p?.dateOfBirth ?? _dobLabel()),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      _detailKv('Official email', p?.officialEmail),
                      _detailKv('Personal email', p?.personalEmail),
                      _detailKv('Official contact', p?.officialContact),
                      _detailKv('Personal contact', p?.personalContact),
                      _detailKv('WhatsApp', p?.whatsappNumber),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Languages',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Wrap(
                        spacing: 8,
                        children: state.languages
                            .map((l) => AppStatusChip(label: l))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Documents',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _uploadNames.entries
                            .map((e) => Chip(label: Text(e.value)))
                            .toList(),
                      ),
                      if (_uploadNames.isEmpty)
                        const Text('No documents uploaded yet.'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget stepBody;
        if (_step == 0) {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('salutation-$_salutation'),
                  initialValue: _salutation,
                  decoration: const InputDecoration(labelText: 'Salutation'),
                  items: _salutations
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _salutation = v);
                  },
                ),
                TextField(
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('gender-$_gender'),
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _gender = v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of birth'),
                  subtitle: Text(
                    age == null ? _dobLabel() : '${_dobLabel()} · Age $age',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDob,
                ),
                TextField(
                  controller: _rank,
                  decoration: const InputDecoration(labelText: 'Rank'),
                ),
                TextField(
                  controller: _designation,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                TextField(
                  controller: _orgId,
                  decoration: const InputDecoration(
                    labelText: 'Organisation / Service ID',
                  ),
                ),
                TextField(
                  controller: _aadhaar,
                  decoration: const InputDecoration(labelText: 'Aadhaar number'),
                ),
                TextField(
                  controller: _officialEmail,
                  decoration:
                      const InputDecoration(labelText: 'Official email'),
                ),
                TextField(
                  controller: _personalEmail,
                  decoration:
                      const InputDecoration(labelText: 'Personal email'),
                ),
                TextField(
                  controller: _officialContact,
                  decoration:
                      const InputDecoration(labelText: 'Official contact'),
                ),
                TextField(
                  controller: _personalContact,
                  decoration:
                      const InputDecoration(labelText: 'Personal contact'),
                ),
                TextField(
                  controller: _whatsapp,
                  decoration:
                      const InputDecoration(labelText: 'WhatsApp number'),
                ),
                const SizedBox(height: 8),
                const Text('Languages',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Wrap(
                  spacing: 8,
                  children: _languageOptions.map((lang) {
                    final selected = state.languages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: selected,
                      onSelected: (on) {
                        final next = List<String>.from(state.languages);
                        if (on) {
                          if (!next.contains(lang)) next.add(lang);
                        } else {
                          next.remove(lang);
                        }
                        _saveLanguages(next);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        } else if (_step == 1) {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documents',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.photo, 'Photo'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.signature, 'Signature'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.orgBadgeFront, 'Org badge (front)'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.orgBadgeBack, 'Org badge (back)'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.aadhaarFront, 'Aadhaar (front)'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.aadhaarBack, 'Aadhaar (back)'),
              ],
            ),
          );
        } else {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prior LO experience',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I have previous LO experience'),
                  value: _hasPrevLoExp,
                  onChanged: (v) => setState(() => _hasPrevLoExp = v),
                ),
                if (_hasPrevLoExp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addExperience,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                  ...state.experiences.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.eventName ?? 'Event'),
                      subtitle: Text(
                        [
                          if (e.year != null) '${e.year}',
                          e.roleResponsibilities,
                        ]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == _step;
                    return Container(
                      width: active ? 12 : 8,
                      height: active ? 12 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppTheme.activeAccent
                            : Colors.grey.shade400,
                      ),
                    );
                  }),
                ),
              ),
              Text(
                ['Personal', 'Documents', 'Prior Experience'][_step],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Expanded(child: ListView(children: [stepBody])),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (_step > 0)
                        TextButton(
                          onPressed: () => setState(() => _step--),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      if (_step < 2)
                        FilledButton(
                          onPressed: () => setState(() => _step++),
                          child: const Text('Next'),
                        )
                      else
                        FilledButton(
                          onPressed: state.status == LoPortalStatus.saving
                              ? null
                              : () => _submit(state),
                          child: const Text('Submit'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
