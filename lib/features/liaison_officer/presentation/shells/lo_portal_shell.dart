import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
      body: BlocConsumer<LoPortalBloc, LoPortalState>(
        listener: (context, state) async {
          final bloc = context.read<LoPortalBloc>();
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
                    Text(
                      d.mobileNumber!,
                      style: TextStyle(color: AppTheme.activeAccent),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDelegateDetail(BuildContext context, MyLoAssignmentDto d) {
    final bloc = context.read<LoPortalBloc>();
    final assignmentId = d.assignmentId;
    if (assignmentId != null) {
      bloc.add(LoPortalDelegateExtrasRequested(assignmentId));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.fullName ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _kv('Designation', d.designation),
                _kv('Organisation', d.organisation),
                _kv('Ministry', d.ministry),
                _kv('Gender', d.gender),
                _kv('Protocol', d.protocolEquiv),
                _kv('VIP category', d.vipCategory),
                _kv('Country', d.countryName),
                _kv('Email', d.email),
                _kv('Mobile', d.mobileNumber),
                _kv(
                  'Arrival',
                  '${d.arrivalFlight ?? ''} ${d.arrivalDate ?? ''} ${d.arrivalTime ?? ''}',
                ),
                _kv(
                  'Departure',
                  '${d.departureFlight ?? ''} ${d.departureDate ?? ''} ${d.departureTime ?? ''}',
                ),
                if (d.family.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Family',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  ...d.family.map(
                    (f) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.fullName ?? ''),
                      subtitle: Text(
                        [
                          f.relation,
                          f.gender,
                          if (f.passportNumber != null &&
                              f.passportNumber!.trim().isNotEmpty)
                            'Passport: ${f.passportNumber}'
                                '${f.passportValidity != null ? ' · Valid till ${f.passportValidity}' : ''}',
                        ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
                      ),
                    ),
                  ),
                ],
                if (d.passportNumber != null &&
                    d.passportNumber!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Passport',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  _kv('Number', d.passportNumber),
                  _kv('Expiry', d.passportExpiry),
                  _kv('Nationality', d.passportNationality),
                ],
                if (d.decorations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Decorations',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  ...d.decorations.map((e) => Text('• $e')),
                ],
                if (assignmentId != null)
                  BlocBuilder<LoPortalBloc, LoPortalState>(
                    builder: (context, state) {
                      final vehicles =
                          state.vehiclesByAssignment[assignmentId] ?? const [];
                      final nominations =
                          state.nominationsByAssignment[assignmentId] ??
                              const [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Vehicles',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (vehicles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('No vehicles assigned.'),
                            )
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
                          const Text(
                            'Nominations',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (nominations.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('No event nominations.'),
                            )
                          else
                            ...nominations.map(
                              (n) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading:
                                    const Icon(Icons.event_available_outlined),
                                title: Text(n['eventName']?.toString() ?? 'Event'),
                                subtitle: Text(
                                  [
                                    n['eventDate'],
                                    n['eventTime'],
                                    n['venue'],
                                  ]
                                      .where(
                                        (e) =>
                                            e != null &&
                                            e.toString().trim().isNotEmpty,
                                      )
                                      .join(' · '),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
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
                  Text(
                    delegate,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
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
                  if (arrivalConnecting.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Arrival connecting: ${arrivalConnecting.map((c) => c.flightNumber).where((e) => e.isNotEmpty).join(', ')}',
                      style: TextStyle(color: AppTheme.activeAccent),
                    ),
                  ],
                  if (departureConnecting.isNotEmpty) ...[
                    Text(
                      'Departure connecting: ${departureConnecting.map((c) => c.flightNumber).where((e) => e.isNotEmpty).join(', ')}',
                      style: TextStyle(color: AppTheme.activeAccent),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _editTravel(
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

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text('Travel — ${d.fullName ?? ''}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                child: const Text('Save'),
              ),
            ],
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

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.email});
  final String email;

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
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
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

  final Map<LoUploadKind, String> _uploadNames = {};

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
    if (_whatsappSameAs == 'official') {
      _whatsapp.text = _officialContact.text;
    } else if (_whatsappSameAs == 'personal') {
      _whatsapp.text = _personalContact.text;
    }
  }

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
    final file = await ImagePickService.pickImage();
    if (file == null || !mounted) return;
    context.read<LoPortalBloc>().add(
          LoPortalUploadRequested(
            kind: kind,
            bytes: file.bytes,
            filename: file.filename,
          ),
        );
    setState(() => _uploadNames[kind] = file.filename);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$label: ${file.filename}'),
      ),
    );
  }

  Widget _uploadRow(LoUploadKind kind, String label) {
    final name = _uploadNames[kind];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: name == null ? null : Text(name),
      trailing: name != null
          ? StatusChip(label: name)
          : TextButton.icon(
              onPressed: () => _pickUpload(kind, label),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload'),
            ),
      onTap: name == null ? null : () => _pickUpload(kind, label),
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
            state.profile?.profileComplete == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Profile saved'),
            ),
          );
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
        final age = _dob == null ? null : _ProfileTab.calcAge(_dob!);

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.email),
                  Text('Org: ${p?.orgName ?? '—'} (${p?.orgTypeName ?? '—'})'),
                  const SizedBox(height: 8),
                  StatusChip(label: p?.profileStatus ?? 'DRAFT'),
                  if (p?.currentPassId != null) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => context.read<LoPortalBloc>().add(
                            LoPortalBadgeDownloadRequested(
                              passId: p!.currentPassId!,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('salutation-$_salutation'),
                    initialValue: _salutation,
                    decoration: const InputDecoration(labelText: 'Salutation'),
                    items: _salutations
                        .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        )
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
                        .map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        )
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
                    decoration:
                        const InputDecoration(labelText: 'Designation'),
                  ),
                  TextField(
                    controller: _orgId,
                    decoration: const InputDecoration(
                      labelText: 'Organisation / Service ID',
                    ),
                  ),
                  TextField(
                    controller: _aadhaar,
                    decoration:
                        const InputDecoration(labelText: 'Aadhaar number'),
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
                    onChanged: (_) {
                      if (_whatsappSameAs == 'official') {
                        _whatsapp.text = _officialContact.text;
                      }
                    },
                  ),
                  TextField(
                    controller: _personalContact,
                    decoration:
                        const InputDecoration(labelText: 'Personal contact'),
                    onChanged: (_) {
                      if (_whatsappSameAs == 'personal') {
                        _whatsapp.text = _personalContact.text;
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      'WhatsApp same as',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Official contact'),
                    value: 'official',
                    groupValue: _whatsappSameAs,
                    onChanged: (v) {
                      setState(() {
                        _whatsappSameAs = v;
                        _syncWhatsappFromSource();
                      });
                    },
                  ),
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Personal contact'),
                    value: 'personal',
                    groupValue: _whatsappSameAs,
                    onChanged: (v) {
                      setState(() {
                        _whatsappSameAs = v;
                        _syncWhatsappFromSource();
                      });
                    },
                  ),
                  if (_whatsappSameAs != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _whatsappSameAs = null);
                      },
                      child: const Text('Enter WhatsApp manually'),
                    ),
                  TextField(
                    controller: _whatsapp,
                    enabled: _whatsappSameAs == null,
                    decoration:
                        const InputDecoration(labelText: 'WhatsApp number'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      'Previous LO experience?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Yes'),
                    value: true,
                    groupValue: _hasPrevLoExp,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _hasPrevLoExp = v);
                    },
                  ),
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('No'),
                    value: false,
                    groupValue: _hasPrevLoExp,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _hasPrevLoExp = v);
                    },
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documents',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  _uploadRow(LoUploadKind.photo, 'Photo'),
                  _uploadRow(LoUploadKind.signature, 'Signature'),
                  _uploadRow(LoUploadKind.orgBadgeFront, 'Org badge (front)'),
                  _uploadRow(LoUploadKind.orgBadgeBack, 'Org badge (back)'),
                  _uploadRow(LoUploadKind.aadhaarFront, 'Aadhaar (front)'),
                  _uploadRow(LoUploadKind.aadhaarBack, 'Aadhaar (back)'),
                ],
              ),
            ),
            if (_hasPrevLoExp)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Experience',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addExperience,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (state.experiences.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No previous LO experience added.'),
                      )
                    else
                      ...state.experiences.map(
                        (e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.eventName ?? 'Event'),
                          subtitle: Text(
                            [
                              if (e.year != null) '${e.year}',
                              e.roleResponsibilities,
                              e.delegateDetails,
                            ]
                                .whereType<String>()
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete',
                            onPressed: e.id == null
                                ? null
                                : () => context.read<LoPortalBloc>().add(
                                      LoPortalExperienceDeleted(e.id!),
                                    ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Languages',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GradientButton(
                label: 'Submit profile',
                loading: state.status == LoPortalStatus.saving,
                onPressed: () => _submit(state),
              ),
            ),
          ],
        );
      },
    );
  }
}
