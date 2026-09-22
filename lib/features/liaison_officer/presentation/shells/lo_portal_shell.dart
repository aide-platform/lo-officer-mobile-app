import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DelegatesTab(email: widget.email),
      const _TasksTab(),
      const _TravelTab(),
      const _AlertsTab(),
      _ProfileTab(email: widget.email),
    ];

    return AppPageScaffold(
      title: 'LO Portal',
      actions: [
        IconButton(
          tooltip: 'Theme',
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: const Icon(Icons.brightness_6_rounded, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: () => performLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
        ),
      ],
      body: BlocBuilder<LoPortalBloc, LoPortalState>(
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
          return IndexedStack(index: _index, children: pages);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Delegates',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            label: 'Travel',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            label: 'Profile',
          ),
        ],
      ),
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
              onTap: () => _showDelegateDetail(context, d),
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
                      if (d.protocolEquiv != null)
                        StatusChip(label: d.protocolEquiv!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(d.designation ?? ''),
                  Text(d.organisation ?? ''),
                  if (d.mobileNumber != null)
                    Text(d.mobileNumber!,
                        style: TextStyle(color: AppTheme.activeAccent)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDelegateDetail(BuildContext context, MyLoAssignmentDto d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.fullName ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _kv('Designation', d.designation),
              _kv('Organisation', d.organisation),
              _kv('Protocol', d.protocolEquiv),
              _kv('Email', d.email),
              _kv('Mobile', d.mobileNumber),
              _kv('Arrival',
                  '${d.arrivalFlight ?? ''} ${d.arrivalDate ?? ''} ${d.arrivalTime ?? ''}'),
              _kv('Departure',
                  '${d.departureFlight ?? ''} ${d.departureDate ?? ''} ${d.departureTime ?? ''}'),
              if (d.family.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Family',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                ...d.family.map(
                  (f) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(f.fullName ?? ''),
                    subtitle: Text('${f.relation ?? ''} · ${f.gender ?? ''}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String? v) {
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
        return StaggeredList(
          itemCount: keys.length,
          itemBuilder: (context, i) {
            final delegate = keys[i];
            final tasks = grouped[delegate]!;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(delegate,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...tasks.map((t) => _TaskTile(task: t)),
                ],
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
      trailing: PopupMenuButton<String>(
        initialValue: task.statusCode,
        onSelected: (code) {
          if (task.id == null) return;
          context.read<LoPortalBloc>().add(
                LoPortalTaskStatusUpdated(
                  taskId: task.id!,
                  statusCode: code,
                ),
              );
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'PENDING', child: Text('Pending')),
          PopupMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
          PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
        ],
        child: StatusChip(label: task.statusName ?? task.statusCode ?? '—'),
      ),
    );
  }
}

class _TravelTab extends StatelessWidget {
  const _TravelTab();

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
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.fullName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                      'Arrival: ${d.arrivalFlight ?? '—'} · ${d.arrivalDate ?? ''} ${d.arrivalTime ?? ''}'),
                  Text(
                      'Departure: ${d.departureFlight ?? '—'} · ${d.departureDate ?? ''} ${d.departureTime ?? ''}'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _editTravel(context, d),
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

  Future<void> _editTravel(BuildContext context, MyLoAssignmentDto d) async {
    final arrivalFlight = TextEditingController(text: d.arrivalFlight);
    final arrivalTerminal = TextEditingController(text: d.arrivalTerminal);
    final arrivalDate = TextEditingController(text: d.arrivalDate);
    final arrivalTime = TextEditingController(text: d.arrivalTime);
    final departureFlight = TextEditingController(text: d.departureFlight);
    final departureTerminal = TextEditingController(text: d.departureTerminal);
    final departureDate = TextEditingController(text: d.departureDate);
    final departureTime = TextEditingController(text: d.departureTime);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Travel — ${d.fullName ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: arrivalFlight,
                  decoration: const InputDecoration(labelText: 'Arrival flight')),
              TextField(
                  controller: arrivalTerminal,
                  decoration: const InputDecoration(labelText: 'Arrival terminal')),
              TextField(
                  controller: arrivalDate,
                  decoration:
                      const InputDecoration(labelText: 'Arrival date (YYYY-MM-DD)')),
              TextField(
                  controller: arrivalTime,
                  decoration: const InputDecoration(labelText: 'Arrival time')),
              TextField(
                  controller: departureFlight,
                  decoration:
                      const InputDecoration(labelText: 'Departure flight')),
              TextField(
                  controller: departureTerminal,
                  decoration:
                      const InputDecoration(labelText: 'Departure terminal')),
              TextField(
                  controller: departureDate,
                  decoration: const InputDecoration(
                      labelText: 'Departure date (YYYY-MM-DD)')),
              TextField(
                  controller: departureTime,
                  decoration: const InputDecoration(labelText: 'Departure time')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
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
              },
            ),
          );
    }
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.alerts.isEmpty) {
          return AppEmptyState(
            message: 'No notifications yet.\n'
                'Task and travel updates appear here.',
            icon: Icons.notifications_none_outlined,
            action: TextButton(
              onPressed: () => context
                  .read<LoPortalBloc>()
                  .add(LoPortalAlertsRefreshRequested()),
              child: const Text('Refresh'),
            ),
          );
        }
        return StaggeredList(
          itemCount: state.alerts.length,
          itemBuilder: (context, i) {
            final a = state.alerts[i];
            return AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.campaign_outlined,
                    color: AppTheme.activeAccent),
                title: Text(
                  a['title']?.toString() ?? 'Alert',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${a['body'] ?? ''}\n${a['at'] ?? ''}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.email});
  final String email;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _designation = TextEditingController();
  final _rank = TextEditingController();
  final _personalEmail = TextEditingController();
  final _personalContact = TextEditingController();
  final _officialContact = TextEditingController();
  final _whatsapp = TextEditingController();
  final _aadhaar = TextEditingController();
  final _orgId = TextEditingController();
  final _dob = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _designation.dispose();
    _rank.dispose();
    _personalEmail.dispose();
    _personalContact.dispose();
    _officialContact.dispose();
    _whatsapp.dispose();
    _aadhaar.dispose();
    _orgId.dispose();
    _dob.dispose();
    super.dispose();
  }

  void _seed(LiaisonOfficerDto? p) {
    if (_seeded || p == null) return;
    _first.text = p.firstName ?? '';
    _last.text = p.lastName ?? '';
    _designation.text = p.designation ?? '';
    _rank.text = p.rank ?? '';
    _personalEmail.text = p.personalEmail ?? '';
    _personalContact.text = p.personalContact ?? '';
    _officialContact.text = p.officialContact ?? '';
    _whatsapp.text = p.whatsappNumber ?? '';
    _aadhaar.text = p.aadhaarNumber ?? '';
    _orgId.text = p.orgIdNumber ?? '';
    _dob.text = p.dateOfBirth ?? '';
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoPortalBloc, LoPortalState>(
      listener: (context, state) {
        if (state.status == LoPortalStatus.ready &&
            state.profile?.profileComplete == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Profile saved'),
            ),
          );
        }
      },
      builder: (context, state) {
        _seed(state.profile);
        final p = state.profile;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.email),
                  Text('Org: ${p?.orgName ?? '—'} (${p?.orgTypeName ?? '—'})'),
                  StatusChip(
                    label: p?.profileStatus ?? 'DRAFT',
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  TextField(
                      controller: _first,
                      decoration: const InputDecoration(labelText: 'First name')),
                  TextField(
                      controller: _last,
                      decoration: const InputDecoration(labelText: 'Last name')),
                  TextField(
                      controller: _designation,
                      decoration:
                          const InputDecoration(labelText: 'Designation')),
                  TextField(
                      controller: _rank,
                      decoration: const InputDecoration(labelText: 'Rank')),
                  TextField(
                      controller: _dob,
                      decoration: const InputDecoration(
                          labelText: 'Date of birth (YYYY-MM-DD)')),
                  TextField(
                      controller: _orgId,
                      decoration: const InputDecoration(
                          labelText: 'Organisation / Service ID')),
                  TextField(
                      controller: _aadhaar,
                      decoration:
                          const InputDecoration(labelText: 'Aadhaar number')),
                  TextField(
                      controller: _personalEmail,
                      decoration:
                          const InputDecoration(labelText: 'Personal email')),
                  TextField(
                      controller: _officialContact,
                      decoration: const InputDecoration(
                          labelText: 'Official contact')),
                  TextField(
                      controller: _personalContact,
                      decoration: const InputDecoration(
                          labelText: 'Personal contact')),
                  TextField(
                      controller: _whatsapp,
                      decoration:
                          const InputDecoration(labelText: 'WhatsApp number')),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Submit profile',
                    loading: state.status == LoPortalStatus.saving,
                    onPressed: () {
                      context.read<LoPortalBloc>().add(
                            LoPortalProfileSaved({
                              'firstName': _first.text.trim(),
                              'lastName': _last.text.trim(),
                              'designation': _designation.text.trim(),
                              'rank': _rank.text.trim(),
                              'dateOfBirth': _dob.text.trim(),
                              'orgIdNumber': _orgId.text.trim(),
                              'aadhaarNumber': _aadhaar.text.trim(),
                              'personalEmail': _personalEmail.text.trim(),
                              'officialContact': _officialContact.text.trim(),
                              'personalContact': _personalContact.text.trim(),
                              'whatsappNumber': _whatsapp.text.trim(),
                            }),
                          );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
